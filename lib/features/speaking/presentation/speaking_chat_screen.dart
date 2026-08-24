import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme.dart';
import '../../../core/ui/glass.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/error_handling.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../data/audio_recorder.dart';
import '../data/device_tts.dart';
import '../data/frame_watch.dart';
import '../data/speculative_stt.dart';
import '../data/turn_timing.dart';
import '../data/voice_activity.dart';
import '../data/tts_service.dart';
import '../domain/models.dart';
import 'avatar/avatar_stage.dart';
import 'avatar/avatar_state.dart';
import 'feedback_view.dart';
import 'scenario_theme.dart';
import 'voice_picker_sheet.dart';
import 'widgets/ai_chat_bubble.dart';
import 'widgets/glass_action.dart';

/// The flagship Speaking experience: a face-to-face conversation with a
/// scenario-matched AI character. The avatar is the stage centrepiece; its
/// glass speech bubble streams the reply, a stateful mic drives the turn, and
/// the whole scene (avatar, background, accent) is chosen by the scenario.
class SpeakingChatScreen extends ConsumerStatefulWidget {
  const SpeakingChatScreen({required this.launch, super.key});

  final SpeakingLaunch launch;

  @override
  ConsumerState<SpeakingChatScreen> createState() => _SpeakingChatScreenState();
}

class _SpeakingChatScreenState extends ConsumerState<SpeakingChatScreen>
    with WidgetsBindingObserver {
  // Resolved eagerly in initState, NOT lazily: `dispose` touches both, and a
  // learner who opens Speaking and leaves without ever tapping the mic would
  // otherwise make `dispose` the first access — reading a provider through a
  // ref that is already dead ("Cannot use ref after the widget was disposed").
  late final TtsService _tts;
  late final SpeechRecorder _recorder;

  // A track lesson carries its theme key directly; a free topic is matched
  // from its text.
  late final ScenarioBackdrop _backdrop = widget.launch.backdropKey != null
      ? backdropForKey(widget.launch.backdropKey!)
      : backdropFor(freeTopic: widget.launch.freeTopic);
  bool _hasBg = false;
  /// The composed backdrop, cached by identity — see the build site.
  Widget? _bg;

  late SpeakingSession _session = widget.launch.started.session;
  // The reply arrives token by token. Held in a notifier rather than in
  // setState so a streaming turn repaints ONLY the speech bubble: the
  // full-screen backdrop (a gaussian-blurred photo) and the 60 fps avatar are
  // never rebuilt mid-sentence, which is where the stutter while talking came
  // from on modest phones and inside the Telegram WebView.
  late final ValueNotifier<String> _line =
      ValueNotifier<String>(widget.launch.started.firstMessage.content);
  String get _aiLine => _line.value;
  // Only whether a line EXISTS drives the surrounding controls, and that flips
  // at most twice a turn — cheap enough for setState.
  bool _hasLine = true;
  Coaching? _coaching;
  bool _busy = false;
  bool _recording = false;
  bool _voiceWarned = false;
  bool _deafWarned = false;
  bool _greeted = false;
  Timer? _greetSafety;

  // ── hands-free ──────────────────────────────────────────────────────────
  /// On by default. The button was the thing nobody understood, so the default
  /// has to be the path that needs no button; a learner who wants to type turns
  /// it off and it stays off for the session.
  /// False while the app is not in the foreground.
  ///
  /// The lifecycle handler already stops the recorder; without this the
  /// watchdog simply started it again, leaving a live microphone in an app the
  /// learner had put away.
  bool _foreground = true;

  /// Set when the microphone was refused. Distinct from [_handsFree]: this one
  /// is recoverable, and the learner is shown how.
  bool _micBlocked = false;

  /// Whether the microphone has ever produced audio in this conversation.
  ///
  /// Permission is asked once. Once it has been granted and used, a later
  /// failure to open the capture is not a refusal — it is a browser that lost
  /// the device for a moment. Latching the "allow the microphone" wall on that
  /// left learners looking at a permission prompt for a permission they had
  /// already given, with no way back except finding a button.
  bool _micEverWorked = false;

  /// Watchdog ticks, which is how reopening is paced — see the timer.
  int _watchTick = 0;

  /// Consecutive rebuilds that did not bring the capture back.
  ///
  /// Healing quietly is right the first few times — the learner should never
  /// see a device hiccup. But healing forever in silence is the failure this
  /// whole pass exists to end: at some point the honest thing is to say so.
  int _healAttempts = 0;

  /// The watchdog tick at which the tutor started talking, or null while it is
  /// not.
  ///
  /// Counted in ticks rather than measured against a clock, and that is not
  /// only for the tests. The watchdog is a one-second timer, which the platform
  /// throttles or suspends while the app is in the background — exactly when
  /// playback is legitimately paused too. Wall time would count that pause
  /// against the tutor and cut off an answer the learner deliberately stepped
  /// away from; ticks stop when the app does, which is the same clock the
  /// audio is on.
  int? _speakingSinceTick;

  /// How many times this conversation had to be prised out of that state.
  /// Reported with the turn, because the failure it stands for is otherwise
  /// completely silent — see [_breakSpeechDeadlock].
  int _speechDeadlocks = 0;

  /// The last tick at which `_busy` was seen to be FALSE.
  ///
  /// Derived in the watchdog rather than stamped at each site that sets the
  /// flag, deliberately: the sites are the thing that keeps being missed, and a
  /// guard that has to be remembered in seven places is the same kind of
  /// promise that failed here already.
  int _busyClearAtTick = 0;

  /// Times the turn state had to be broken out of. Zero on a healthy session.
  int _busyDeadlocks = 0;

  /// Consecutive listening windows that heard no speech at all.
  ///
  /// One is ordinary — somebody stepped away. Two in a row, while the app
  /// believes it is listening, is the app being wrong rather than the room
  /// being quiet.
  int _deafTurns = 0;

  /// How smooth the screen has been. Reported with the turn, because "it
  /// stutters on the phone" is the one complaint that cannot be checked from a
  /// desk — see [FrameWatch].
  final FrameWatch _frames = FrameWatch();

  /// The session is being wound up, so a long `_busy` is expected: `/end`
  /// grades the whole conversation with a 70B model and takes about sixteen
  /// seconds. Nothing should rescue the learner from that.
  bool _ending = false;

  final VoiceActivity _vad = VoiceActivity();

  /// Real time between level readings.
  ///
  /// The detector used to be told a flat 120 ms per reading, but on the web
  /// `onLevel` fires once per audio chunk — and chunks arrive far more often
  /// than that. Silence therefore accumulated several times faster than it
  /// actually passed, and a three-second pause was declared after about one.
  /// That is why the tutor kept interrupting.
  final Stopwatch _sinceLastLevel = Stopwatch();

  // ── session clock ───────────────────────────────────────────────────────
  /// Seconds since the conversation opened, shown at the top.
  ///
  /// Not decoration: the product sells minutes, and a learner who cannot see
  /// how long they have been talking has no basis for the one decision the
  /// End button offers them.
  /// When the conversation opened. The clock widget reads this and ticks
  /// itself; the screen does not rebuild for it.
  final DateTime _openedAt = DateTime.now();

  /// Re-opens the microphone whenever it should be open and is not.
  ///
  /// A safety net rather than the mechanism: the normal path arms as soon as
  /// the tutor stops speaking. This catches every way that path can be missed,
  /// which — with no button left to rescue the learner — is the difference
  /// between a pause and a dead session.
  Timer? _listenWatchdog;

  /// The pending fetch of a finished turn's correction. Cancelled on the way
  /// out so a closed screen never asks for anything.
  Timer? _coachTimer;
  bool _armed = false;
  Timer? _armTimer;
  /// Guards against two starts racing — the watchdog and a recycle can both
  /// decide the mic should be open in the same tick, and starting the recorder
  /// twice leaves it in a state where nothing is captured at all.
  bool _starting = false;
  // The greeting needs BOTH: a stage to speak on, and a settled voice to speak
  // in. See [_maybeGreet].
  bool _stageReady = false;
  bool _voiceSettled = false;

  // ── recording cap ───────────────────────────────────────────────────────
  /// The longest a single clip may run before it is sent regardless.
  ///
  /// A fuse, not a rule. Silence ends a turn, so this only fires when silence
  /// never comes — a microphone left in a noisy room. Ninety seconds was the
  /// old push-to-talk limit and it cut people off mid-answer; three minutes is
  /// still a fraction of the server's 25 MB ceiling (~13 minutes of PCM) and
  /// longer than anyone speaks without pausing.
  static const Duration _maxTurn = Duration(minutes: 3);
  Timer? _capTimer;
  int _recSeconds = 0;

  /// The last turn's opener, kept so a failed turn can be retried instead of
  /// being lost to a snackbar (the closure holds the recorded clip).
  Stream<SpeakingEvent> Function()? _lastTurn;
  bool _turnFailed = false;

  /// Latched when the server refuses a turn for want of daily speaking minutes.
  bool _outOfMinutes = false;

  /// True while a Translate/Hint request is in flight, so the two buttons
  /// cannot be double-fired into the server's cooldown.
  bool _assisting = false;

  /// What the server actually HEARD on the last spoken turn. Shown to the
  /// learner: when speech recognition mishears them the conversation goes
  /// sideways, and without this they have no way to tell why.
  String _heard = '';

  /// True when the recogniser struggled with the audio itself — a hint to say
  /// it again more clearly, never a score.
  bool _hardToHear = false;

  /// Typing is a first-class way to take a turn, not a fallback: a learner on a
  /// bus, in a library or with a dead microphone can still hold the
  /// conversation. The backend has always accepted text turns.
  bool _typing = false;
  final TextEditingController _composer = TextEditingController();
  final FocusNode _composerFocus = FocusNode();

  /// The replay rate for "slower" — slow enough to separate the words, not so
  /// slow it stops sounding like speech.
  static const double _slowRate = 0.7;

  /// Upload progress of the spoken turn, 0..1, or null when nothing is being
  /// sent. A 90-second answer is a few megabytes; on a weak connection the wait
  /// is long enough that silence reads as a crash. Kept in a notifier (not
  /// setState) because it ticks continuously — see [_line].
  final ValueNotifier<double?> _upload = ValueNotifier<double?>(null);

  /// When the current upload began, so a fast one is never announced.
  DateTime? _uploadStarted;

  // ── turn timing ───────────────────────────────────────────────────────────
  //
  // The number this feature is judged on is "how long after I stopped talking
  // did it answer", and neither end of it exists on the server. See
  // [TurnTimeline]; everything here is best-effort and behaviour-free.

  /// The turn being measured. Restarted at each silence-onset, because a
  /// learner who pauses and resumes has not finished their turn.
  final TurnTimeline _timing = TurnTimeline.create();

  /// Whether [_timing] has already been reported, so the two things that can
  /// trigger a report cannot both send one.
  bool _timingSent = true;

  /// Backstop for a turn that never reaches audible audio — a failure, a
  /// cancellation, a speech engine with no voice. Without it those turns would
  /// never be reported at all, and the sample would quietly consist only of
  /// successes.
  Timer? _timingBackstop;

  /// Whether the detector was already counting silence on the previous reading.
  /// The rising edge of that is when the learner stopped speaking.
  bool _wasSilent = false;

  /// Transcribes the answer during the grace period instead of after it. See
  /// [SpeculativeStt]; the two seconds it fills are the largest single item in
  /// the wait before the tutor replies.
  late final SpeculativeStt _speculation;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _recorder = ref.read(speechRecorderProvider);
    _speculation = SpeculativeStt(
      transcribe: (bytes, filename) => ref
          .read(speakingRepositoryProvider)
          .transcribeAhead(bytes, filename),
    );
    WidgetsBinding.instance.addObserver(this);
    _frames.start();
    _listenWatchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      _watchTick++;
      // Noticing is cheap and wants to be quick. Opening is neither: on the web
      // every attempt is a `getUserMedia`, and on a device that genuinely
      // cannot record, retrying once a second is a storm. So detection runs
      // every tick and reopening stays at the old, calmer two-second cadence.
      _healStalledCapture();
      _breakSpeechDeadlock();
      _breakBusyDeadlock();
      if (_watchTick.isEven) _ensureListening();
    });
    _tts.available.addListener(_onTtsChange);
    _tts.speaking.addListener(_onTtsChange);
    // The far end of the measurement. `_tts` is app-scoped and outlives this
    // screen, so both hooks are cleared in `dispose` — a disposed screen still
    // being called back is how a stale timeline would report against the next
    // conversation.
    _tts.onSpeechDispatched = () => _timing.mark(TurnTimeline.mTtsStart);
    _tts.onAudibleStart = _onAudibleStart;
    // Load the device speech engine while the learner is still looking at an
    // empty room. It is not resident on Android, and the load used to happen
    // inside the greeting — heard as the tutor pausing before its first word.
    if (_tts.usesDevice) DeviceTtsPlatform.warmUp();
    _checkBackground();
    // The greeting waits for the avatar stage to be ready (see [_greet]) so the
    // hero's mouth is on screen when it speaks. A safety timer guarantees the
    // welcome never stalls if the engine is slow to report in.
    // Seven seconds was chosen when every voice came off the network and a
    // slow catalogue was the thing to survive. It became the thing being
    // waited for: learners reported the tutor taking six seconds to say hello,
    // which is this timer nearly running out. Two and a half is still a
    // generous ceiling for a gate that should trip within a frame.
    _greetSafety = Timer(const Duration(milliseconds: 2500), _greetAnyway);
  }

  /// The avatar stage is live (2D avatar up, or the fallback engaged).
  void _onStageReady() {
    _stageReady = true;
    _maybeGreet();
  }

  /// Play the scenario's opening line exactly once — but only once BOTH the
  /// stage is up AND the voice is settled.
  ///
  /// Waiting for the voice is the point: the catalogue loads asynchronously, so
  /// greeting immediately synthesised the first sentence in the fallback voice
  /// and everything after it in the learner's real voice — the tutor audibly
  /// changed person mid-greeting. The safety timer still guarantees the welcome
  /// is never held hostage to a slow or failed catalogue.
  void _maybeGreet() {
    if (_greeted || !mounted || !_stageReady || !_voiceSettled) return;
    _greeted = true;
    _greetSafety?.cancel();
    _tts.enqueue(widget.launch.started.firstMessage.content);
  }

  /// Last resort: speak in whatever voice we have rather than stay silent.
  void _greetAnyway() {
    _stageReady = true;
    _voiceSettled = true;
    _maybeGreet();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetSafety?.cancel();
    _listenWatchdog?.cancel();
    _coachTimer?.cancel();
    _disarm();
    _capTimer?.cancel();
    _timingBackstop?.cancel();
    _tts.available.removeListener(_onTtsChange);
    _tts.speaking.removeListener(_onTtsChange);
    // `_tts` is app-scoped: leaving these attached would let a dead screen's
    // timeline collect marks from the next conversation's greeting.
    _tts.onSpeechDispatched = null;
    _tts.onAudibleStart = null;
    _composer.dispose();
    _composerFocus.dispose();
    _line.dispose();
    _upload.dispose();
    unawaited(_tts.stop());
    unawaited(_recorder.cancel());
    // The one place the microphone is given back. Between turns the stream
    // stays open on purpose — releasing it there is what asked permission
    // before every single thing the learner said.
    unawaited(_recorder.endSession());
    super.dispose();
  }

  /// Leaving the app must not leave the microphone open or the tutor talking
  /// out loud in the background: drop the recording and silence the voice the
  /// moment we lose the foreground, on every platform.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _ensureListening();
      return;
    }
    _foreground = false;
    unawaited(_tts.stop());
    if (_recording) {
      _capTimer?.cancel();
      unawaited(_recorder.cancel());
      if (mounted) setState(() => _recording = false);
    }
  }

  void _onTtsChange() {
    if (!mounted) return;
    if (!_tts.available.value && !_voiceWarned) {
      _voiceWarned = true;
      _snack(AppLocalizations.of(context).voiceUnavailable);
    }
    setState(() {});
    // The tutor has stopped talking, so it is the learner's turn. Waiting for
    // them to realise that and find a button is what lost people.
    if (_tts.speaking.value) {
      _speakingSinceTick ??= _watchTick;
    } else {
      _speakingSinceTick = null;
      _armAfterTutor();
    }
  }

  /// The tutor cannot still be talking, so stop believing that it is.
  ///
  /// The microphone is deliberately held shut while the tutor speaks, so that
  /// it does not record the tutor's own voice through the speaker. That makes
  /// "the tutor is speaking" a gate on the learner being heard at all — and a
  /// gate that never opens is a session that is over without saying so. It
  /// reads to the learner as the microphone breaking after a turn or two,
  /// because typing goes on working; three real Android sessions ended exactly
  /// there, on a server-spoken turn, with no further turn ever sent.
  ///
  /// The individual ways to get stuck are worth fixing on their own and have
  /// been — see [playbackBudget], and the `finally` that guarantees
  /// `endStream`. This is the guard that does not depend on having found them
  /// all, and it is here rather than in the speech queue because this is where
  /// the cost lands.
  ///
  /// The threshold is not a guess about the machinery. It is the longest a
  /// tutor's answer can honestly last: replies are capped at a handful of
  /// sentences, and a spoken sentence is a few seconds. Forty-five is well past
  /// any of them and still soon enough that the learner is very likely still
  /// holding the phone.
  static const _speechCeiling = 45; // watchdog ticks, one per second

  /// How long a turn may hold the screen before it is treated as abandoned.
  ///
  /// Measured turns finish in about seven seconds and the client gives a slow
  /// one sixty; but a turn that fails still clears the flag in its `finally`.
  /// What this catches is the case where that `finally` never runs at all, and
  /// twenty-five seconds is far past any turn that is still going to arrive.
  static const _busyCeiling = 25; // watchdog ticks

  /// The turn state that never ended.
  ///
  /// `_busy` means "a turn is in flight", and while it is set the microphone
  /// stays shut. Every early exit is supposed to clear it — `_resumeListening`
  /// exists so that none of them forget — and that is a convention, held in
  /// seven places, in a method that can throw. Its own doc comment names the
  /// consequence: "the flag that, left set, silently ends the conversation".
  ///
  /// This is the same complaint as [_breakSpeechDeadlock] wearing a different
  /// flag, and it gets the same answer: stop trusting the flag and watch what
  /// the learner can actually do. Eight separate causes have now been found for
  /// "the microphone stops working after a couple of turns"; each fix was
  /// right and none of them could be the last one. A guard that does not need
  /// to know the cause can be.
  void _breakBusyDeadlock() {
    if (!mounted) return;
    // Not stuck, or legitimately busy ending the session.
    if (!_busy || _ending) {
      _busyClearAtTick = _watchTick;
      return;
    }
    if (_watchTick - _busyClearAtTick < _busyCeiling) return;
    _busyClearAtTick = _watchTick;
    _busyDeadlocks++;
    // The in-flight request, if there really is one, is left alone: it owns its
    // own `finally` and will clear a flag that is already clear. What is taken
    // back is the microphone.
    setState(() => _busy = false);
    unawaited(_rebuildCapture());
  }

  void _breakSpeechDeadlock() {
    if (!mounted || !_tts.speaking.value) return;
    // A flag that was already true when this screen opened has no start tick.
    // Give it one rather than ignoring it, so it is timed from here.
    final since = _speakingSinceTick ??= _watchTick;
    if (_watchTick - since < _speechCeiling) return;
    _speakingSinceTick = null;
    _speechDeadlocks++;
    // `stop()` ends the drain's generation and lowers the flag, which is all
    // that is being asked for. Whatever it was waiting on is abandoned.
    unawaited(_tts.stop());
    // Not left to the next tick: the learner has already been waiting.
    _ensureListening();
  }

  /// Open the microphone once the tutor finishes, after a short beat.
  ///
  /// The beat matters: opening the instant the audio ends catches the tail of
  /// the tutor's own voice through the speaker on some phones, and the learner
  /// then hears themselves answered by an echo.
  void _armAfterTutor() {
    if (!mounted || _recording || _busy || !_session.isActive) return;
    _armTimer?.cancel();
    _armTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || _recording || _busy || _tts.speaking.value) return;
      // Rebuild the capture first when the tutor spoke through the device
      // engine: an utterance can leave the recorder's audio context suspended,
      // and the learner would then talk into a microphone that records nothing.
      // Two turns was all it took — after which typing worked and speaking did
      // not, which reads as a broken microphone permission.
      if (_tts.usesDevice) await _recorder.refreshCapture();
      if (!mounted || _recording || _busy || _tts.speaking.value) return;
      unawaited(_startRecording(autoStarted: true));
    });
  }

  /// A microphone that is open but has stopped delivering audio.
  ///
  /// This is the failure that had no symptom. A browser does not report it: the
  /// track mutes, or the audio context the capture worklet runs on is
  /// suspended — by the speech engine speaking, by a spell in the background,
  /// by memory pressure in a Telegram WebView — and the stream neither ends nor
  /// errors. Every flag the app owns still says "listening". The learner talks;
  /// nothing is recorded, so the silence detector never fires, so the turn
  /// never ends and no reply ever comes. Typing still works, which is why it
  /// reads as a microphone permission problem and never as what it is.
  ///
  /// It cannot be prevented, only noticed. So the app stops trusting its own
  /// flags and asks the one question that cannot be faked — has any audio
  /// arrived recently — and rebuilds when the answer is no.
  void _healStalledCapture() {
    if (!mounted || !_recording || _busy || !_foreground) return;
    // Two different deaths, one recovery. A capture that stopped delivering,
    // and one that delivers nothing but silence — the second was invisible to
    // every check this class had, because arrival was all it measured.
    if (!_recorder.isStalled && !_recorder.isDeaf) {
      _healAttempts = 0;
      return;
    }
    _healAttempts++;
    unawaited(_rebuildCapture());
  }

  Future<void> _rebuildCapture() async {
    _capTimer?.cancel();
    await _recorder.cancel();
    await _recorder.refreshCapture();
    if (!mounted) return;
    setState(() => _recording = false);
    // Say something only once the quiet fixes have visibly failed. Three
    // rebuilds is several seconds of a learner talking to nothing, which is
    // long enough that they deserve to know rather than be left guessing.
    if (_healAttempts >= 3 && !_deafWarned) {
      _deafWarned = true;
      _snack(AppLocalizations.of(context).cannotHearYou);
    }
    // A heal is a deliberate reopen, so it goes straight through rather than
    // waiting for an even tick — that pacing exists to space out failures, not
    // to delay a fix.
    _ensureListening();
  }

  /// The invariant: if it is the learner's turn, the microphone is open.
  ///
  /// Deliberately expressed as "what should be true now" rather than as a
  /// reaction to an event. Every event-driven version of this had a path that
  /// missed, and a missed path is a session that looks broken.
  void _ensureListening() {
    if (!mounted || _recording || _busy) return;
    if (!_foreground || _micBlocked) return;
    // Out of minutes is a wall, not a pause: reopening the microphone here
    // means the learner keeps talking into turns that can only ever 402.
    if (!_session.isActive || _typing || _outOfMinutes) return;
    if (_tts.speaking.value) return;
    if (_armTimer?.isActive ?? false) return; // already on its way
    unawaited(_startRecording(autoStarted: true));
  }

  /// Nobody spoke for a while. Start a fresh recording rather than stop.
  ///
  /// The reason to stop was never that listening should end — it was that an
  /// ever-growing buffer of silence costs memory and, if it were ever sent,
  /// an upload. Recycling keeps the buffer small AND keeps the door open,
  /// which is what the learner needs when there is no button.
  Future<void> _recycleListening() async {
    await _cancelRecording();
    if (!mounted) return;
    _ensureListening();
  }

  void _disarm() {
    _armTimer?.cancel();
    _armTimer = null;
    _armed = false;
  }

  /// Kept for the paths that must stop listening — a refused permission, or
  /// leaving the screen. There is no longer a switch: typing is the fallback
  /// for a library or a bus, and it was always there.

  Future<void> _checkBackground() async {
    try {
      await rootBundle.load(_backdrop.backgroundAsset);
      // The photo changes what the backdrop is, so drop the cached widget once.
      if (mounted) {
        setState(() {
          _hasBg = true;
          _bg = null;
        });
      }
    } catch (_) {
      /* no photo bundled — themed gradient backdrop is used */
    }
  }

  // ── derived avatar / mic state ─────────────────────────────────────────
  AvatarState get _avatarState {
    if (_recording) return AvatarState.listening;
    if (_tts.speaking.value) return AvatarState.talking;
    if (_busy) return AvatarState.thinking;
    return AvatarState.idle;
  }


  /// The voice to ask the server to speak the reply in — or null to fetch the
  /// audio ourselves, sentence by sentence, as before.
  ///
  /// Null on web, and the reason is the transport rather than the feature.
  /// `dio`'s web adapter is an `XMLHttpRequest` with `responseType =
  /// 'arraybuffer'`: it hands over the whole body on `onLoad`, so an SSE
  /// response is not a stream there — it arrives in one piece when the turn is
  /// already over. Carrying the audio inside that body therefore delays the
  /// FIRST sentence until the LAST one has been synthesised and transferred,
  /// which measured slower than the round trip it was meant to remove.
  ///
  /// Native has a real streaming adapter, so there it is the win it was
  /// designed to be. This goes back to `_tts.voice` unconditionally once the
  /// web SSE transport reads the body incrementally (browser `fetch` +
  /// `ReadableStream`).
  /// Also null when the device speaks for us: rendering audio nobody will play
  /// is billed all the same.
  String? get _serverVoice => (kIsWeb || _tts.usesDevice) ? null : _tts.voice;

  /// The voice to have ready, for a turn whose audio this client will fetch
  /// itself.
  ///
  /// Set exactly when the server will be asked for speech but cannot send it
  /// on the stream — the web, where the HTTP layer delivers the whole body at
  /// once, so audio inside it would delay the first word instead of hastening
  /// it. The server renders each sentence as the model writes the next, into
  /// the cache /tts reads, and the request that follows is a hit.
  ///
  /// Null when the device speaks (nothing to render) and null on native (the
  /// audio comes down the stream already).
  String? get _prerenderVoice =>
      (!_tts.usesDevice && _serverVoice == null) ? _tts.voice : null;

  String get _emotion {
    final s = _avatarState;
    if (s == AvatarState.talking || s == AvatarState.idle) {
      return _coaching?.emotion ?? s.fallbackEmotion;
    }
    return s.fallbackEmotion;
  }

  // ── turns ──────────────────────────────────────────────────────────────

  Future<void> _startRecording({bool autoStarted = false}) async {
    if (!_session.isActive || _starting) return;
    _starting = true;
    try {
      await _startRecordingInner(autoStarted: autoStarted);
    } finally {
      _starting = false;
    }
  }

  Future<void> _startRecordingInner({required bool autoStarted}) async {
    final l = AppLocalizations.of(context);
    await _tts.stop();
    // No pre-check on the web.
    //
    // There, `hasPermission()` and `start()` BOTH call `getUserMedia`, so
    // asking first meant two permission dialogs for every single thing the
    // learner said. The check bought nothing either: `start()` fails on its own
    // when permission is refused, and that failure is handled below.
    //
    // Kept on Android and iOS, where it is free — the permission is granted to
    // the app by the operating system once, not to a page by a WebView every
    // time — and where knowing before starting gives a cleaner message.
    if (!kIsWeb) {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        if (!autoStarted) _snack(l.micPermission);
        if (mounted) setState(() => _micBlocked = true);
        return;
      }
    }
    try {
      _vad.reset();
      _sinceLastLevel
        ..reset()
        ..start();
      _armed = autoStarted;
      await _recorder.start(onLevel: _onLevel, onSpan: _onLevelSpan);
      if (!mounted) {
        await _recorder.cancel();
        return;
      }
      setState(() {
        _recording = true;
        _recSeconds = 0;
      });
      // Tick the on-screen counter, and send automatically at the cap so a
      // long answer is still delivered rather than refused by the server.
      _capTimer?.cancel();
      _capTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted || !_recording) {
          t.cancel();
          return;
        }
        setState(() => _recSeconds++);
        if (_recSeconds >= _maxTurn.inSeconds) {
          t.cancel();
          unawaited(_stopAndSend());
        }
      });
    } catch (_) {
      // Two very different failures arrive here as the same exception.
      //
      // A refusal, which is permanent until the learner changes their mind, and
      // a device that could not be opened right now, which is not. Telling them
      // apart by the error is hopeless — browsers throw the same thing — but
      // the session's own history settles it: a microphone that has already
      // recorded in this conversation has already been granted. Latching the
      // permission wall on a hiccup was one of the ways speaking died after two
      // turns, because nothing clears that wall except a button most learners
      // never find.
      if (_micEverWorked) {
        await _recorder.refreshCapture();
        return; // the watchdog opens it again a moment from now
      }
      // The one place a refusal now lands. Latched rather than switched off for
      // good: the learner is shown a way to grant it and the loop resumes the
      // moment they do — and an automatic attempt that fails says nothing,
      // because nobody pressed anything.
      if (!autoStarted) _snack(l.micPermission);
      if (mounted) setState(() => _micBlocked = true);
    }
  }

  /// Live loudness from the recorder. Decides when the turn ended.
  ///
  /// Native only: the platform reports an amplitude on a timer and says nothing
  /// about how much audio it covers, so the wall clock is the only measure
  /// available. The web path knows exactly and uses [_onLevelSpan].
  void _onLevel(double level) {
    if (!_armed || !_recording || !mounted) return;
    final elapsed = _sinceLastLevel.isRunning
        ? _sinceLastLevel.elapsed
        : const Duration(milliseconds: 120);
    _sinceLastLevel
      ..reset()
      ..start();
    _judge(level, elapsed);
  }

  /// The same decision, with the reading's true length supplied by the capture.
  void _onLevelSpan(double level, Duration span) {
    if (!_armed || !_recording || !mounted) return;
    _judge(level, span);
  }

  /// Take the clip so far and start transcribing it, without ending the turn.
  ///
  /// Best-effort throughout: a platform that cannot snapshot, a browser that
  /// does not flush, a request that fails — all of them simply leave the turn
  /// to upload the recording the way it always has.
  Future<void> _speculate() async {
    try {
      if (!mounted || _busy) return;
      final clip = await _recorder.snapshot();
      if (clip == null || !mounted) return;
      // Re-checked after the await: the learner may have resumed while the
      // browser was flushing, in which case this clip is already stale.
      if (_vad.silence == Duration.zero) return;
      _speculation.begin(clip.bytes, clip.filename);
    } catch (_) {
      // Speculation never breaks a turn.
    }
  }

  /// Sound has started coming out. The end of the only metric that matters.
  ///
  /// [source] names the callback that reported it, because the browser's
  /// `onstart` and the native player's play call are not the same claim — see
  /// [TtsService.onAudibleStart].
  void _onAudibleStart(String source) {
    if (_timingSent) return;
    _timing
      ..note('first_audio_source', source)
      ..mark(TurnTimeline.mFirstAudio);
    unawaited(_shipTiming());
  }

  /// Send the turn's timeline, once. Never throws, never awaits the caller.
  Future<void> _shipTiming() async {
    if (_timingSent || !_timing.started) return;
    _timingSent = true;
    _timingBackstop?.cancel();
    _timingBackstop = null;
    _timing.end();
    try {
      await ref.read(speakingRepositoryProvider).reportTurnTiming(
            turnId: _timing.turnId,
            sessionId: _session.id,
            record: _timing.toJson(),
          );
    } catch (_) {
      // A turn that answered correctly and then failed to describe itself was
      // still a good turn. Nothing about measurement is worth a snackbar.
    }
  }

  /// The codec behind an upload filename, as a short label for the log.
  static String _formatOf(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot < 0 ? 'unknown' : filename.substring(dot + 1).toLowerCase();
  }

  void _judge(double level, Duration elapsed) {
    // Audio is arriving, so the device is real and permission is genuinely
    // held. Both healers read this.
    _micEverWorked = true;
    _healAttempts = 0;
    final verdict = _vad.onLevel(level, elapsed);
    // The rising edge of the detector's own silence counter: the learner has
    // just stopped making sound. This is the origin of the turn's clock and the
    // start of the metric — NOT `endOfTurn`, which is two seconds later and is
    // the app's decision rather than the learner's action.
    //
    // Read from the detector rather than counted again here, so the two can
    // never disagree about when the quiet began. It resets when a trailing
    // syllable clears the keep-alive band, so a learner who tails off and picks
    // up again restarts the clock — which is correct: the turn that eventually
    // gets sent begins at the LAST time they stopped.
    final silent = _vad.silence > Duration.zero;
    if (silent && !_wasSilent) {
      _timing.begin();
      _timing.mark(TurnTimeline.mSilenceStart);
      _timingSent = false;
      // The utterance is complete as of this instant — the grace period that
      // follows exists to let the learner take it back, not to finish hearing
      // it. So transcription starts now and runs inside the wait.
      if (_vad.heardSpeech) unawaited(_speculate());
    } else if (!silent && _wasSilent) {
      // They carried on. Whatever was sent described half a sentence, so it is
      // abandoned — and the generation moves on, so a late answer for it can
      // never be attached to the turn that eventually goes.
      _speculation.discard();
    }
    _wasSilent = silent;
    switch (verdict) {
      case VoiceVerdict.keepListening:
        return;
      case VoiceVerdict.endOfTurn:
        _armed = false;
        _timing.mark(TurnTimeline.mVadConfirmed);
        _deafTurns = 0; // heard them: the streak is broken
        unawaited(_stopAndSend());
      case VoiceVerdict.nothingHeard:
        // Say so, once. The loudness floor cannot be right for every phone and
        // every room, and a learner who is speaking into a microphone that
        // hears nothing gets no signal at all — they simply talk to a screen
        // that never answers. Telling them beats guessing better numbers.
        // A whole listening window with nothing above the bar. That is
        // evidence about the APP, not about the learner: a real microphone in a
        // real room does not produce nothing while somebody talks at it.
        //
        // Two things can cause it and both are silent, so both are undone here
        // rather than guessed between.
        _deafTurns++;
        // 1. The room estimate climbed past the learner's own voice. It only
        //    learns from readings BELOW the bar, so once the bar is out of
        //    reach it can never be corrected by anything it will accept — the
        //    only readings that could fix it are the ones it now rejects.
        //    Measured in production as two good turns and then permanent
        //    silence, with every deadlock guard reading zero.
        _vad.forgetRoom();
        // 2. The capture is delivering buffers that contain no sound — a track
        //    the browser muted without ending. `CaptureHealth` counts arrivals,
        //    so it calls that healthy. Rebuilding costs a moment and settles it.
        if (_deafTurns >= 2) {
          _deafTurns = 0;
          unawaited(_rebuildCapture());
          return;
        }
        if (!_deafWarned) {
          _deafWarned = true;
          _snack(AppLocalizations.of(context).cannotHearYou);
        }
        // Silence, so far. Swap the buffer for an empty one and carry on
        // listening — closing here is what stranded people, because there is
        // no longer a button to reopen it with.
        _armed = false;
        unawaited(_recycleListening());
    }
  }

  /// Drop out of the in-flight state and re-open the microphone.
  ///
  /// Every early exit from a turn goes through here, so none of them can
  /// forget to clear `_busy` — the flag that, left set, silently ends the
  /// conversation.
  void _resumeListening() {
    if (!mounted) return;
    setState(() => _busy = false);
    _ensureListening();
  }

  Future<void> _cancelRecording() async {
    _capTimer?.cancel();
    await _recorder.cancel();
    if (mounted) setState(() => _recording = false);
  }

  Future<void> _stopAndSend() async {
    final l = AppLocalizations.of(context);
    _capTimer?.cancel();
    // Both flags together, before the first await. Stopping the recorder is
    // asynchronous, and in the gap `_recording` was already false while
    // `_busy` was not yet true — so the watchdog saw an idle screen and opened
    // a second turn on top of the one being sent. The server rejected it with
    // a 409, which is how this was found in the production log rather than in
    // any test.
    setState(() {
      _recording = false;
      _busy = true;
    });
    _timing.mark(TurnTimeline.mStopBegin);
    // Not `final`: a speculated clip may replace the recording below, once the
    // server has confirmed it transcribed those exact bytes.
    AudioClip? clip;
    try {
      // The two stages inside `stop` — the recorder's flush and the encode or
      // file read after it — are reported through this hook rather than guessed
      // at from either side of the call.
      clip = await _recorder.stop(onStage: _timing.mark);
    } catch (_) {
      _snack(l.audioCaptureError);
      // Clear `_busy` before re-arming: it was set above to close the overlap
      // window, and `_ensureListening` refuses to open the mic while it is
      // set. Leaving it would strand the learner exactly as the old
      // dead-end paths did.
      _resumeListening();
      return;
    }
    // The clip to send, and whether transcription has already been paid for.
    //
    // The speculated bytes are used ONLY once the server has answered that it
    // transcribed them — which also proves those exact bytes decode, so a turn
    // is never handed audio nobody has successfully read. Anything else (still
    // running and then failing, a resumed sentence, an unsupported platform)
    // falls through to the full recording, which is what shipped before.
    final speculated = await _speculation.settle();
    final specName = _speculation.filename;
    if (speculated != null && specName != null) {
      clip = AudioClip(bytes: speculated, filename: specName);
      _timing.note('stt_speculated', true);
    }
    _speculation.reset();
    if (clip == null) {
      _resumeListening();
      return;
    }
    _uploadStarted = DateTime.now();
    // Measured per turn: a bad moment must not be averaged away by the calm
    // minutes around it.
    _frames.reset();
    _timing
      ..mark(TurnTimeline.mAudioReady)
      // Which codec actually ran. The web path falls back to WAV silently by
      // design, so without this a 550 KB upload and a 50 KB one are the same
      // number with very different causes.
      ..note('audio_format', _formatOf(clip.filename))
      ..note('audio_bytes', clip.bytes.length)
      ..note('tts_engine', _tts.usesDevice ? 'device' : 'server')
      ..note('server_voice', _serverVoice != null)
      // A phone on mobile data and a laptop on wifi run identical code and
      // behave nothing alike; `platform: web` cannot tell them apart.
      ..note('device', DeviceTtsPlatform.deviceKind)
      ..note('voice_name', _tts.deviceVoiceName)
      // Empty when Opus worked. Anything else explains a large upload.
      ..note('codec_fallback', _recorder.lastFallbackReason)
      // What the microphone is REALLY running at. The app asks for 16 kHz and
      // Safari is documented to refuse; anything other than 16000 here, or a
      // false beside it, is the difference between a readable recording and
      // one the transcriber hears at a third of speed. No iPhone has ever
      // opened this app, so this is how we will find out rather than be told.
      ..note('sample_rate', _recorder.sampleRate)
      ..note('rate_measured', _recorder.rateMeasured)
      // Zero on every healthy session. Anything else means the tutor was
      // believed to be talking long after it had stopped, and the learner
      // spent that time unable to be heard.
      ..note('speech_deadlocks', _speechDeadlocks)
      // Zero on a healthy session. Anything else means a turn ended without
      // handing the microphone back, and the learner spent that time mute.
      ..note('busy_deadlocks', _busyDeadlocks)
      // Smoothness, measured on the handset rather than guessed at. `jank_pct`
      // is the number to read: under ~5% nobody notices, over ~20% is what
      // "it freezes" means. The two worst times say WHICH half is slow —
      // build is our own layout and painting, raster is the GPU — and they
      // have entirely different fixes.
      // What the detector was actually hearing. A peak well below the bar is
      // the signature of a bar that has run away — the failure that reads as
      // "it stopped hearing me" and shows up nowhere else.
      ..note('vad_floor', (_vad.noiseFloor * 1000).round())
      ..note('vad_bar', (_vad.speechBar * 1000).round())
      ..note('vad_peak', (_vad.peakLevel * 1000).round())
      ..note('deaf_turns', _deafTurns)
      ..note('jank_pct', _frames.stats.jankPercent)
      ..note('worst_build_ms', _frames.stats.worstBuildMs)
      ..note('worst_raster_ms', _frames.stats.worstRasterMs)
      ..mark(TurnTimeline.mUploadStart);
    await _runTurn(
      () => ref.read(speakingRepositoryProvider).streamAudioReply(
            _session.id,
            clip!.bytes,
            clip.filename,
            voice: _serverVoice,
            prerender: _prerenderVoice,
            requestId: _timing.turnId,
            onProgress: (sent, total) {
              if (total > 0 && _uploadStarted != null) {
                // Only surfaces once an upload has visibly stalled — see
                // [_UploadBar]. A fast one finishes before this ever shows.
                final ms =
                    DateTime.now().difference(_uploadStarted!).inMilliseconds;
                _upload.value = ms >= 1000 ? sent / total : null;
              }
            },
          ),
    );
  }

  /// [heard] is what the learner submitted when we already know it (a typed
  /// turn); for a spoken turn it stays null and is filled in by the server's
  /// transcript event. Either way the previous turn's line must not linger.
  Future<void> _runTurn(
    Stream<SpeakingEvent> Function() openStream, {
    String? heard,
  }) async {
    final l = AppLocalizations.of(context);
    _lastTurn = openStream;
    _line.value = '';
    setState(() {
      _hasLine = false;
      _coaching = null;
      _busy = true;
      _turnFailed = false;
      _heard = heard ?? '';
      _hardToHear = false;
    });
    final reply = StringBuffer();
    // Kept running even though the server normally speaks for us: if audio
    // stops arriving (an older backend, its voice provider down, a stream that
    // broke mid-reply) this is what still has the sentences to say. A tutor
    // that has gone mute is not an acceptable way to find out the server is
    // old. It splits by the same rule the server does, so sentence N here is
    // the sentence the Nth `audio` event covered.
    final chunker = SentenceChunker();
    final sentences = <String>[];
    var spokenByServer = 0;
    await _tts.stop();
    // Tell the player the reply is arriving in pieces. Between sentences the
    // queue is briefly empty, and without this the tutor was treated as
    // finished at the first gap — the microphone re-opened and the rest of the
    // answer was never spoken.
    _tts.beginStream();

    try {
      await for (final event in openStream()) {
        // Leaving the screen mid-reply must end the turn: `break` cancels the
        // underlying subscription, which stops both the setState-after-dispose
        // and — because the TTS service outlives this screen — the tutor
        // carrying on talking out loud after the learner has walked away.
        if (!mounted) break;
        // The body is fully uploaded the moment the server starts answering;
        // from here the wait is thinking, not sending.
        _upload.value = null;
        _uploadStarted = null;
        // Any event means the first byte of the reply has reached the app. On a
        // transport that does not stream this is the WHOLE body arriving at
        // once, which is precisely the difference worth being able to see.
        _timing.mark(TurnTimeline.mFirstChunk);
        switch (event) {
          case TranscriptEvent(:final text, :final wasHardToHear):
            _timing.mark(TurnTimeline.mTranscript);
            // Show what was heard: a mis-transcription is the single most
            // confusing failure in a spoken lesson, and it is invisible unless
            // we say so. When the audio itself was hard to make out, say that
            // too — it is the only pronunciation feedback that comes from the
            // sound rather than from the text.
            setState(() {
              _heard = text.trim();
              _hardToHear = wasHardToHear;
            });
          case ChunkEvent(:final text):
            reply.write(text);
            // Split and hold, do not speak: the server's rendering of this
            // same sentence is on its way, and speaking both would say it
            // twice. `add` consumes what it returns, so the sentences have to
            // be kept here or the fallback would only have the last fragment.
            final completed = chunker.add(text);
            sentences.addAll(completed);
            // The first thing that COULD be spoken. The gap from here to
            // `tts_start_ms` is how long the client sits on a sentence it
            // already has.
            if (completed.isNotEmpty) {
              _timing.mark(TurnTimeline.mFirstSentence);
            }
            // The hot path: notifier only — no setState, no tree rebuild.
            _line.value = reply.toString();
            if (!_hasLine) setState(() => _hasLine = true);
          case AudioEvent(:final text, :final bytes):
            spokenByServer++;
            // The native path speaks from server-rendered audio, so a sentence
            // becomes speakable when its audio lands rather than when its text
            // does. Marked here too so the field means the same thing on both
            // platforms: "the first thing the tutor could say".
            _timing.mark(TurnTimeline.mFirstSentence);
            // No bytes means the server could not render this sentence — say it
            // the old way rather than skip it.
            if (bytes != null) {
              _tts.enqueueRendered(text, bytes);
            } else {
              _tts.enqueue(text);
            }
          case CoachingEvent(:final coaching):
            setState(() => _coaching = coaching);
          case DoneEvent(:final session):
            // Nothing to queue here any more: every sentence the tutor will say
            // arrived before this event, and the `finally` below both covers the
            // case where none did and closes the stream for the player.
            //
            // Re-read the budget now the server has metered this turn.
            //
            // It used to be fetched once when the screen opened and refreshed
            // only when the minutes ran out — so the header said the same
            // number for the whole lesson and then jumped straight to nothing
            // left. The server is the only thing that knows how many seconds
            // were actually charged, so ask it rather than estimating here.
            ref.invalidate(speakingQuotaProvider);
            setState(() => _session = session);
            _lastTurn = null; // the turn landed; nothing to retry
            // The correction is fetched, not pushed — see
            // `coachingForTurn`. Started here and deliberately not awaited:
            // the turn is over, and the tutor should already be speaking.
            _scheduleCoaching(session.id, session.turnCount);
          case StreamErrorEvent(:final message):
            _fail(message.isEmpty ? l.aiUnavailable : message);
        }
      }
    } on ApiException catch (e) {
      // 402 = out of speaking minutes, 422 = nothing intelligible was heard.
      // Neither is worth retrying with the same clip; anything else (a dropped
      // connection mid-turn being the common one) is.
      if (e.statusCode == 402) {
        _lastTurn = null;
        // Out of minutes is a wall, not a hiccup: latch it so the mic goes
        // quiet and the learner is offered the way forward once, instead of
        // tapping into the same failure until they give up.
        if (mounted) setState(() => _outOfMinutes = true);
        ref.invalidate(speakingQuotaProvider);
      } else if (e.statusCode == 422) {
        _lastTurn = null;
        _snack(l.speechNotRecognized);
      } else {
        _fail(e.localized(l));
      }
    } catch (_) {
      _fail(l.aiUnavailable);
    } finally {
      // Whatever the server did not speak, we speak — from the first sentence
      // it never sent audio for. Usually that is none of them; it is all of
      // them against an older backend, and the tail when a stream broke
      // part-way through a reply.
      //
      // Here rather than on `done`, because a turn that ends by failing had its
      // partial reply spoken before this change and should still be. Not when
      // the learner has left the screen: they are owed silence, not the rest of
      // an answer they walked away from.
      if (mounted) {
        final said = [...sentences, ...chunker.finish()];
        for (final sentence in said.skip(spokenByServer)) {
          _tts.enqueue(sentence);
        }
      }
      // Always, not just on the happy path: a stream that errors or is cut off
      // would otherwise leave the player believing more sentences are coming,
      // and it would hold the turn open for ever — the microphone would never
      // re-open and the session would be dead with nothing on screen to say so.
      _tts.endStream();
      _timing.mark(TurnTimeline.mStreamDone);
      // The turn is over as far as the network is concerned, but the tutor has
      // not necessarily made a sound yet: on the device engine the sentences
      // were only just queued above, and `onstart` follows a microtask and an
      // engine load. So the report is normally sent by [_onAudibleStart].
      //
      // This is the backstop for the turns that never get there — a failure, a
      // cancelled stream, a handset with no English voice. Without it the only
      // turns ever reported would be the ones that worked, which is the sample
      // least worth having.
      _timingBackstop?.cancel();
      _timingBackstop = Timer(
        const Duration(seconds: 3),
        () => unawaited(_shipTiming()),
      );
      _upload.value = null; // never leave a progress reading behind
      _uploadStarted = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Fetch the correction for a finished turn, once the tutor is talking.
  ///
  /// The wait is on purpose. The analysis leaves the reply stream so that
  /// nothing delays the first audio; fetching it immediately would put a
  /// request back into exactly the moment that was freed up. So it goes after
  /// the tutor has started, when nobody is watching the network.
  ///
  /// On a cancellable timer rather than an awaited delay, and that is not only
  /// tidiness: a learner who leaves mid-turn would otherwise have a request
  /// fire from a screen that no longer exists.
  ///
  /// Asked for by TURN. A slow analysis can still be in flight when the
  /// learner speaks again, and a late answer applied to the new turn would
  /// correct a sentence they have already moved on from.
  void _scheduleCoaching(String sessionId, int turnIndex, [int attempt = 0]) {
    // One short wait, then one retry: the analysis usually lands within a
    // second of the reply, and a learner who has moved on is owed no third.
    const waits = [Duration(milliseconds: 900), Duration(seconds: 2)];
    if (attempt >= waits.length) return;
    _coachTimer?.cancel();
    _coachTimer = Timer(waits[attempt], () async {
      if (!mounted || _session.id != sessionId) return;
      final coaching = await ref
          .read(speakingRepositoryProvider)
          .coachingForTurn(sessionId, turnIndex);
      if (!mounted || _session.id != sessionId) return;
      if (coaching == null) {
        _scheduleCoaching(sessionId, turnIndex, attempt + 1);
        return;
      }
      // Nothing to show for a sentence that was already right — which is most
      // of them, and an empty panel would read as "we found something".
      if (coaching.correction.isEmpty && coaching.naturalVersion.isEmpty) return;
      // The guard the turn index exists for: never label this turn with an
      // answer computed for a different one.
      if (_session.turnCount != turnIndex) return;
      setState(() => _coaching = coaching);
    });
  }

  /// Surface a turn failure as recoverable state, not a vanishing snackbar:
  /// the learner keeps their recorded answer and can send it again.
  void _fail(String message) {
    if (!mounted) return;
    setState(() => _turnFailed = _lastTurn != null);
    _snack(message);
  }

  Future<void> _retryTurn() async {
    final again = _lastTurn;
    if (again == null || _busy) return;
    await _runTurn(again);
  }

  /// Take the turn by typing. The backend has always accepted text turns; this
  /// is simply the client finally offering them.
  Future<void> _sendTyped() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _busy || !_session.isActive || _outOfMinutes) return;
    _composer.clear();
    _composerFocus.unfocus();
    await _runTurn(
      () => ref
          .read(speakingRepositoryProvider)
          .streamReply(
            _session.id,
            text,
            voice: _serverVoice,
            prerender: _prerenderVoice,
          ),
      heard: text, // typed words are exactly what was received
    );
  }

  /// Say the last line again — at normal pace, or slowly for a learner who is
  /// still catching the words. Costs no turn and no speaking minutes.
  Future<void> _replay({required bool slow}) async {
    if (_aiLine.isEmpty || _busy) return;
    // Asking to hear the line again means they have not answered yet, so the
    // open recording holds nothing worth keeping. Drop it rather than send a
    // clip with the replay talking over the top of it.
    if (_recording) await _cancelRecording();
    _disarm();
    unawaited(_tts.prime()); // keep web autoplay unlocked (this is a gesture)
    await _tts.replay(_aiLine, speed: slow ? _slowRate : 1.0);
    // The mic re-opens on its own once the replay finishes — `_onTtsChange`
    // fires when speaking stops, and the watchdog covers it either way.
  }

  /// Best-effort silence before the report: microphone closed, tutor quiet.
  /// Everything here is courtesy, and [_end] treats it as such.
  Future<void> _hush() async {
    if (_recording) await _recorder.cancel();
    await _tts.stop();
  }

  Future<void> _end() async {
    // Read before the first await: everything below runs across async gaps.
    final l = AppLocalizations.of(context);
    _capTimer?.cancel();

    // Grading the conversation takes about sixteen seconds, and the screen is
    // deliberately held for it. Nothing below should be rescued from that.
    _ending = true;

    // Going quiet is courtesy. Finishing is the promise.
    //
    // Closing the microphone and stopping the tutor is what makes the room
    // quiet while the report is prepared. It is not what finishing a session
    // MEANS, and it must never be able to prevent one — so it gets a budget
    // and the session ends either way.
    //
    // It could prevent one, and it did. `TtsService.stop()` waits for the
    // speech queue to unwind, and a queue parked on a clip that never reports
    // finishing never unwinds — so Finish did nothing at all, silently, with
    // no request ever leaving the phone and nothing on screen to say why.
    // Measured over thirty-six hours of production: thirty-two spoken turns
    // reached the server and not one session ending.
    await _hush().timeout(const Duration(seconds: 3), onTimeout: () {});
    if (!mounted) return;
    setState(() {
      _recording = false;
      _busy = true;
    });
    try {
      final feedback =
          await ref.read(speakingRepositoryProvider).endSession(_session.id);
      if (!mounted) return;
      if (feedback == null) {
        // The session is closed and the conversation is safe; only the grading
        // failed. Offer to build the report again instead of dropping the
        // learner on the home screen with nothing to show for the session.
        final again = await _askToRebuildReport();
        if (!mounted) return;
        if (again) {
          setState(() => _busy = false);
          return _end();
        }
        context.go('/home');
        return;
      }
      await showFeedbackSheet(context, feedback, sessionId: _session.id);
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      // A timeout here almost never means the session is still open.
      //
      // Closing it is the first thing the server does; what takes the time is
      // grading the conversation. So the learner who waited, saw "check your
      // internet" and pressed Finish again got the report instantly — the call
      // is idempotent and returns the stored one. Offering that beats a snack
      // that reads as "your session was lost", which is what it looked like.
      if (e.code == 'NETWORK_ERROR') {
        final again = await _askToRebuildReport();
        if (!mounted) return;
        if (again) {
          setState(() => _busy = false);
          return _end();
        }
        context.go('/home');
        return;
      }
      _snack(e.localized(l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _askToRebuildReport() async {
    final l = AppLocalizations.of(context);
    final answer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.feedbackNotReadyTitle),
        content: Text(l.feedbackNotReadyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.close),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.retry),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _effectiveVoice(List<Voice> voices, String? selected) {
    if (voices.isEmpty) return _tts.voice;
    if (selected != null && voices.any((v) => v.id == selected)) return selected;
    return voices.first.id;
  }

  // ── Translate / Hint ───────────────────────────────────────────────────
  /// Both helpers ask the server about the partner's *last spoken line* and
  /// answer in the learner's own language. The sheet opens immediately with a
  /// spinner so a tap always has a visible response, then fills in.
  Future<void> _assist(String kind) async {
    if (_assisting || _aiLine.isEmpty) return;
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final translate = kind == 'translate';
    setState(() => _assisting = true);

    final completer = Completer<String>();
    unawaited(
      _sheet(
        icon: translate ? Icons.translate_rounded : Icons.lightbulb_rounded,
        title: translate ? l.actionTranslate : l.hintTitle,
        body: completer.future,
      ),
    );
    try {
      final text = await ref
          .read(speakingRepositoryProvider)
          .assist(sessionId: _session.id, kind: kind, lang: lang);
      completer.complete(text.isEmpty ? l.aiUnavailable : text);
    } on ApiException catch (e) {
      // 409 is the anti-spam cooldown: say "a moment", not "failed".
      completer.complete(
        e.statusCode == 409 ? l.assistTooFast : e.localized(l),
      );
    } catch (_) {
      completer.complete(l.aiUnavailable);
    } finally {
      if (mounted) setState(() => _assisting = false);
    }
  }

  Future<void> _sheet({
    required IconData icon,
    required String title,
    required Future<String> body,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: GlassPanel(
          opacity: 0.16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: _backdrop.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              FutureBuilder<String>(
                future: body,
                builder: (_, snap) => snap.hasData
                    ? Text(
                        snap.data!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accent = _backdrop.accent;
    final active = _session.isActive && !_outOfMinutes;

    final listening = ref.watch(listenModeProvider);
    final voicesAsync = ref.watch(voicesProvider);
    final voices = voicesAsync.valueOrNull ?? const <Voice>[];
    final selection = ref.watch(selectedVoiceProvider);
    _tts.voice = _effectiveVoice(voices, selection.id);
    // BOTH answers are required before the tutor may speak: the catalogue says
    // which voices exist, persistence says which one this learner picked.
    // Waiting only on the catalogue meant greeting in a default voice and
    // switching to theirs from the second reply. Deferred a frame because this
    // runs inside build.
    // The device engine needs no catalogue at all — the voice is on the phone
    // and `getVoices()` is synchronous. Waiting on a network list that will
    // never be used is pure delay, and it was most of the wait before the tutor
    // said hello. The learner's saved choice is still honoured: the engine
    // holds it, and the picker re-applies it the moment the roster loads.
    final needsCatalogue = !_tts.usesDevice;
    if (!_voiceSettled &&
        selection.isLoaded &&
        (!needsCatalogue || voicesAsync.hasValue || voicesAsync.hasError)) {
      _voiceSettled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGreet());
    }

    return Theme(
      data: AppTheme.dark(),
      // Unlock autoplay on the first touch anywhere on this screen.
      //
      // It used to be unlocked only by the "say it again" button, so a learner
      // who never pressed it heard nothing at all: the tutor speaks first, and
      // the Telegram webview refuses to play audio that no gesture asked for.
      // A pointer listener catches whatever they touch first — the mic, a
      // topic, the screen itself — and `prime()` is a no-op once it has worked.
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => unawaited(_tts.prime()),
        child: Scaffold(
        backgroundColor: AppColors.canvasDark,
        body: Stack(
          children: [
            // 1 ─ the scenario scene, then the full-screen avatar standing in it.
            // Built once per backdrop state and then reused by identity: a
            // rebuild of this screen must never re-create a full-screen
            // gaussian blur. (Flutter skips a child whose widget instance is
            // unchanged, so this genuinely costs nothing on later builds.)
            Positioned.fill(child: _bg ??= _background(accent)),
            Positioned.fill(
              child: AvatarStage(
                backdrop: _backdrop,
                emotion: _emotion,
                state: _avatarState,
                level: _tts.level,
                fillScreen: true,
                onReady: _onStageReady,
              ),
            ),
            // 2 ─ scrims so the header (top) and controls (bottom) stay legible
            // over the figure without boxing it in.
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 180,
              child: IgnorePointer(child: _Scrim(top: true)),
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 320,
              child: IgnorePointer(child: _Scrim(top: false)),
            ),
            // 3 ─ overlaid UI: header, the floating speech bubble, and controls.
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    title: widget.launch.title ?? l.lessonsTitle,
                    onEnd: _busy ? null : _end,
                    onVoice: () => showVoicePicker(context),
                    voiceOff: !_tts.available.value,
                    // Chrome belongs in the chrome. Down in the panel stack it
                    // landed across the avatar's mouth.
                    clock: _SessionClock(
                      openedAt: _openedAt,
                      // `valueOrNull`, not `asData`: a refresh briefly puts the
                      // provider back into loading, and `asData` would go null
                      // there — the minutes would vanish from the header after
                      // every turn and reappear a moment later. This holds the
                      // last known figure while the new one is on its way.
                      budget: ref.watch(speakingQuotaProvider).valueOrNull,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  // AI speech bubble floats near the top, in the head's
                  // headroom. Rebuilt on its own as the reply streams in.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                    child: ValueListenableBuilder<String>(
                      valueListenable: _line,
                      builder: (_, text, _) => AiChatBubble(
                        // The bubble IS the switch: tap it to hide the line and
                        // make the turn listening practice, tap again to read
                        // it. One target, no extra chrome, and the hidden state
                        // says how to undo itself.
                        text: listening ? '' : text,
                        thinking: _avatarState == AvatarState.thinking,
                        placeholder: (listening && _hasLine) ? l.tapToReveal : null,
                        hint: listening ? l.tapToReveal : l.tapToHide,
                        onTap: _hasLine
                            ? () => ref.read(listenModeProvider.notifier).toggle()
                            : null,
                      ),
                    ),
                  ),
                  // The state of the conversation, with the line it is about.
                  // It used to sit three panels lower, across the avatar's
                  // face, describing something the learner had to look away
                  // from to read.
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: _StatusChip(state: _avatarState, accent: accent),
                  ),
                  // Hearing it again is practice, not a failure — so the two
                  // replay actions sit right under the line they replay.
                  if (_hasLine)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.sm),
                      child: _ReplayRow(
                        accent: accent,
                        // Not gated on `_recording`. The microphone opens the
                        // instant the tutor stops, so gating on it disabled
                        // "again" and "slower" at the one moment they are for
                        // — right after a line the learner did not catch.
                        enabled: !_busy,
                        onAgain: () => _replay(slow: false),
                        onSlower: () => _replay(slow: true),
                      ),
                    ),
                  const Spacer(),
                  // Sending a spoken turn: show it moving, so a slow upload is
                  // visibly progress rather than a hang.
                  ValueListenableBuilder<double?>(
                    valueListenable: _upload,
                    builder: (_, p, _) => p == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, AppSpace.sm),
                            child: _UploadBar(progress: p, accent: accent),
                          ),
                  ),
                  if (_heard.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpace.sm),
                      child: _HeardChip(text: _heard, hardToHear: _hardToHear),
                    ),
                  // No countdown. Nothing is held open any more, so a clock
                  // ticking down over someone hunting for a word is pressure
                  // with nothing on the other side of it.
                  if (_micBlocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.xs),
                      child: _MicBlockedChip(
                        onTap: () async {
                          // Asking again is the whole point: the first refusal
                          // may have been a mis-tap, and without this the
                          // learner cannot speak for the rest of the session.
                          setState(() => _micBlocked = false);
                          await _startRecording();
                        },
                      ),
                    )
                  else
                  const SizedBox(height: AppSpace.md),
                  if (_turnFailed && !_busy)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpace.md),
                      child: _RetryStrip(accent: accent, onRetry: _retryTurn),
                    ),
                  if (_coaching != null && _coaching!.hasErrors)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, AppSpace.md),
                      child: CoachingStrip(
                        coaching: _coaching!,
                        accent: accent,
                        collapsed: ref.watch(correctionPanelProvider),
                        onToggle: () =>
                            ref.read(correctionPanelProvider.notifier).toggle(),
                      ),
                    ),
                  if (_outOfMinutes)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, AppSpace.sm),
                      child: GlassPanel(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.quotaExhausted,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpace.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: _busy ? null : _end,
                                  child: Text(l.finishSession),
                                ),
                                const SizedBox(width: AppSpace.sm),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accent,
                                  ),
                                  onPressed: () =>
                                      context.push('/subscriptions'),
                                  child: Text(l.quotaUpgrade),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (!active)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, AppSpace.sm),
                      child: GlassPanel(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l.turnLimitBanner,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  // Bottom controls — speak, or type. Both are real ways to
                  // take a turn; the learner picks whichever their situation
                  // allows.
                  if (_typing)
                    _Composer(
                      controller: _composer,
                      focusNode: _composerFocus,
                      accent: accent,
                      enabled: active && !_busy,
                      onSend: _sendTyped,
                      onSpeakInstead: () => setState(() => _typing = false),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpace.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GlassAction(
                                icon: Icons.translate_rounded,
                                label: l.actionTranslate,
                                accent: accent,
                                onTap: (!_hasLine || _assisting)
                                    ? null
                                    : () => _assist('translate'),
                              ),
                            ),
                          ),
                          // The centre used to be the microphone. Nothing
                          // needs pressing to speak any more, so the space goes
                          // to the one control still worth reaching for: the
                          // way out. Whether the mic is live is answered by the
                          // status pill under the avatar.
                          _EndButton(onTap: _busy ? null : _end),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GlassAction(
                                icon: Icons.lightbulb_outline_rounded,
                                label: l.actionHint,
                                accent: accent,
                                onTap: (active && !_assisting && _hasLine)
                                    ? () => _assist('hint')
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                      child: TextButton.icon(
                        // Enabled while recording too. Hands-free means the
                        // microphone is open almost all the time, so gating
                        // this on "not recording" made it unreachable — the
                        // one route out for a learner on a bus.
                        onPressed: active
                            ? () {
                                if (_recording) unawaited(_cancelRecording());
                                _disarm();
                                setState(() => _typing = true);
                                _composerFocus.requestFocus();
                              }
                            : null,
                        icon: const Icon(Icons.keyboard_alt, size: 18),
                        label: Text(l.switchToTyping),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _background(Color accent) {
    final gradient = ImmersiveBackground(
      top: _backdrop.top,
      bottom: _backdrop.bottom,
      accent: accent,
      watermark: _backdrop.icon,
    );
    if (!_hasBg) return gradient;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Scenario photo — only lightly softened, so it reads as the real room
        // the figure is standing in (the sharp 3D avatar pops against it). The
        // header/control scrims handle legibility, so this stays a scene, not a
        // dark wash.
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Image.asset(
            _backdrop.backgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => gradient,
          ),
        ),
        // A whisper of the accent + a gentle overall darken to seat the avatar
        // in the scene and keep white text readable anywhere.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.22),
                _backdrop.bottom.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A top- or bottom-anchored fade-to-black so the header and the bottom controls
/// stay readable over the full-screen avatar without a hard panel.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.top});

  final bool top;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: top ? Alignment.topCenter : Alignment.bottomCenter,
          end: top ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: top ? 0.55 : 0.82),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Minimal frosted top bar: scenario name + voice + finish.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onEnd,
    required this.onVoice,
    required this.voiceOff,
    this.clock,
  });

  /// Elapsed time and today's remaining budget.
  final Widget? clock;

  final String title;
  final VoidCallback? onEnd;
  final VoidCallback onVoice;
  final bool voiceOff;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          IconButton(
            onPressed: onVoice,
            tooltip: l.selectVoice,
            icon: Icon(
              voiceOff
                  ? Icons.voice_over_off_rounded
                  : Icons.record_voice_over_rounded,
              color: voiceOff ? AppColors.warning : Colors.white,
            ),
          ),
          // No end control here. There is a red one in the middle of the
          // screen, and two ways to finish — with two different words on them
          // ("Yakunlash" and "Tugatish") — is a choice the learner has to stop
          // and make about something that is not a choice at all.
          if (clock != null) ...[const SizedBox(width: AppSpace.xs), clock!],
        ],
      ),
    );
  }
}

/// A small "Speaking / Listening / Thinking" pill under the avatar.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state, required this.accent});

  final AvatarState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (String text, Color color) = switch (state) {
      AvatarState.talking => (l.statusSpeaking, accent),
      AvatarState.listening => (l.statusListening, AppColors.brand),
      AvatarState.thinking => (l.statusThinking, AppColors.inkFaint),
      AvatarState.idle => ('', Colors.transparent),
    };
    return AnimatedOpacity(
      opacity: text.isEmpty ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text.isEmpty ? ' ' : text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// The spoken turn on its way to the server. A determinate bar, not a spinner:
/// on a weak connection the learner needs to see that something is actually
/// moving, and how much is left.
class _UploadBar extends StatelessWidget {
  const _UploadBar({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassPanel(
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload, size: 16, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l.sendingLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Say it again" / "Slower" — the two things a learner reaches for when a
/// sentence went past too fast. Neither spends a turn or a speaking minute, so
/// they can be used as freely as replaying a track.
class _ReplayRow extends StatelessWidget {
  const _ReplayRow({
    required this.accent,
    required this.enabled,
    required this.onAgain,
    required this.onSlower,
  });

  final Color accent;
  final bool enabled;
  final VoidCallback onAgain;
  final VoidCallback onSlower;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pill(Icons.replay, l.sayAgain, enabled ? onAgain : null),
        const SizedBox(width: AppSpace.sm),
        _pill(Icons.slow_motion_video, l.saySlower,
            enabled ? onSlower : null),
      ],
    );
  }

  Widget _pill(IconData icon, String label, VoidCallback? onTap) {
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      child: Material(
      color: Colors.white.withValues(alpha: on ? 0.14 : 0.06),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color: on ? Colors.white : Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: on ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// What the tutor actually heard. When speech recognition mishears a learner
/// the reply makes no sense and — without this line — there is nothing to tell
/// them why. Seeing it also teaches: it is the clearest pronunciation feedback
/// in the whole session.
class _HeardChip extends StatelessWidget {
  const _HeardChip({required this.text, this.hardToHear = false});

  final String text;

  /// The audio was hard to make out. Shown as an invitation to repeat, not as
  /// a verdict on the learner.
  final bool hardToHear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassPanel(
      opacity: 0.10,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hardToHear ? Icons.hearing_disabled : Icons.hearing,
                size: 15,
                color: hardToHear ? AppColors.warning : Colors.white54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: '${l.youSaidLabel}: ',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: '“$text”'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Only when the SOUND was unclear — phrased as an invitation, since
          // a noisy room lowers the reading exactly as much as unclear speech.
          if (hardToHear) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 23),
              child: Text(
                l.speakingUnclearAudio,
                style: TextStyle(
                  color: AppColors.warning.withValues(alpha: 0.95),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The typed turn. Same conversation, same grading — just entered with a
/// keyboard, for the many moments when speaking out loud is not an option.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.accent,
    required this.enabled,
    required this.onSend,
    required this.onSpeakInstead,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accent;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onSpeakInstead;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // No manual viewInsets padding here: the Scaffold already resizes the body
    // above the keyboard, and adding it again double-counts the inset and
    // pushes the field off screen.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpace.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassPanel(
            opacity: 0.14,
            padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 4,
                    // The server caps a turn at 500 characters; stop the
                    // learner writing an essay the API would reject.
                    maxLength: 500,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: accent,
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      hintText: l.composerHint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: enabled ? onSend : null,
                  tooltip: l.sendAction,
                  icon: Icon(Icons.send, color: accent),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onSpeakInstead,
            icon: const Icon(Icons.mic, size: 18),
            label: Text(l.switchToSpeaking),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// Offers the failed turn back to the learner: their recorded answer is still
/// held, so a dropped connection costs a tap rather than the whole turn.
class _RetryStrip extends StatelessWidget {
  const _RetryStrip({required this.accent, required this.onRetry});

  final Color accent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassPanel(
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.turnFailedRetry,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.retry),
            style: TextButton.styleFrom(foregroundColor: accent),
          ),
        ],
      ),
    );
  }
}

/// A compact one-line correction strip (full coaching lives in the feedback).
/// Public only so a screenshot test can render it on its own; nothing
/// outside this file constructs one.
class CoachingStrip extends StatelessWidget {
  const CoachingStrip({
    super.key,
    required this.coaching,
    required this.accent,
    required this.collapsed,
    required this.onToggle,
  });

  final Coaching coaching;
  final Color accent;

  /// Folded down to the fix alone, leaving the tutor's face visible.
  ///
  /// Three labelled rows is four lines of text on a phone, and it sat squarely
  /// over the avatar — which is most of what makes this feel like talking to
  /// somebody rather than filling in a form. Collapsed is not hidden: the
  /// correction itself, the thing the learner came for, stays on screen. What
  /// folds away is the explanation, which is read once and then not needed.
  final bool collapsed;
  final VoidCallback onToggle;

  /// One labelled line, or nothing at all when there is nothing to say.
  ///
  /// Every row is optional because the model answers honestly: a sentence that
  /// was already correct has no correction, and one that was correct but stiff
  /// has no correction and a better version. Rendering an empty row would tell
  /// the learner something was found when nothing was.
  Widget _row(
    String label,
    String value, {
    bool emphasise = false,
    int maxLines = 3,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      // `Text.rich`, not `RichText`: the latter takes the style it is handed
      // and merges nothing into it, so a style without a family renders in the
      // platform default — this panel was the one place in the app not set in
      // the app's own typeface, and nothing said so.
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: emphasise ? Colors.white : Colors.white70,
          fontSize: emphasise ? 13.5 : 12.5,
          height: 1.35,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final correction = coaching.correction.trim();
    final why = coaching.why.trim();
    final natural = coaching.naturalVersion.trim();

    // Said correctly and said well: the panel stays away. Most turns are this,
    // and a strip that appeared every time would stop being read.
    if (correction.isEmpty && natural.isEmpty) return const SizedBox.shrink();

    // Nothing to unfold to: the panel is already one row, so a control that
    // promised more would open onto nothing.
    final expandable = why.isNotEmpty || natural.isNotEmpty;
    final folded = collapsed && expandable;

    return Semantics(
      button: expandable,
      label: expandable ? (folded ? l.coachMore : l.coachLess) : null,
      child: GlassPanel(
        opacity: 0.12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        // The whole panel is the target, not just the chevron: it is the
        // largest thing on screen at that moment and a learner reaching for it
        // should not have to find a 24-pixel arrow.
        child: InkWell(
          onTap: expandable ? onToggle : null,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child:
                    Icon(Icons.auto_fix_high_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The fix first — it is what the learner came for, and the
                    // one row that survives folding. Kept to two lines there so
                    // a long sentence cannot quietly grow the panel back.
                    _row(
                      l.coachCorrection,
                      correction,
                      emphasise: true,
                      maxLines: folded ? 2 : 3,
                    ),
                    if (!folded) ...[
                      // Then the reason, in their own language. `grammarPoint`
                      // names the rule; this explains it, and only the second
                      // is any use to somebody who does not know the label yet.
                      _row(l.coachWhy, why),
                      // And how a fluent speaker would have put it. Shown even
                      // when nothing was wrong: "correct" and "natural" are not
                      // the same thing, and the gap between them is most of
                      // fluency.
                      _row(l.coachNatural, natural),
                    ],
                  ],
                ),
              ),
              if (expandable)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 6),
                  child: Icon(
                    folded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: Colors.white54,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}







/// Time spent in this conversation, at the top of the screen.
///
/// Plain and quiet. It exists so the decision to stop is an informed one —
/// minutes are what the learner is spending — not to put a countdown over a
/// conversation and make them hurry.
class _SessionClock extends StatefulWidget {
  const _SessionClock({required this.openedAt, this.budget});

  final DateTime openedAt;

  /// Today's speaking allowance. Null while it is still loading — the clock
  /// shows on its own rather than waiting, because a blank header at the top
  /// of a conversation reads as something being broken.
  final SpeakingQuota? budget;

  /// Below this, the remaining budget is worth pointing at.
  ///
  /// Two minutes: late enough that nobody is nagged through a lesson, early
  /// enough to finish the thought they are in the middle of.
  static const _lowSeconds = 120;

  @override
  State<_SessionClock> createState() => _SessionClockState();
}

class _SessionClockState extends State<_SessionClock> {
  Timer? _tick;
  int _seconds = 0;

  /// The server's last word on the budget, and when we heard it.
  ///
  /// The allowance is wall-clock time now, so between refreshes the client can
  /// work out the remainder exactly — it is the same clock. What it must not do
  /// is subtract the whole session from a figure the server has already charged
  /// part of: every turn settles server-side, so a fresh figure resets the
  /// baseline and the countdown continues from there.
  int? _baseLeft;
  int _baseAt = 0;

  int? get _left {
    final base = _baseLeft;
    if (base == null) return null;
    final live = base - (_seconds - _baseAt);
    return live < 0 ? 0 : live;
  }

  @override
  void initState() {
    super.initState();
    _syncBudget();
    // Owned here so the tick rebuilds one line of text instead of the whole
    // conversation screen — the difference between a clock and a stutter.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(
          () => _seconds = DateTime.now().difference(widget.openedAt).inSeconds,
        );
      }
    });
  }

  @override
  void didUpdateWidget(_SessionClock old) {
    super.didUpdateWidget(old);
    if (widget.budget?.secondsRemaining != old.budget?.secondsRemaining) {
      _syncBudget();
    }
  }

  void _syncBudget() {
    final left = widget.budget?.secondsRemaining;
    if (left == null) return;
    _baseLeft = left;
    _baseAt = _seconds;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_seconds % 60).toString().padLeft(2, '0');
    final left = _left;
    final low = left != null && left <= _SessionClock._lowSeconds;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$m:$sec',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 0.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (left != null) ...[
          const SizedBox(width: 6),
          const Text('·', style: TextStyle(color: Colors.white24, fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            // Rounded up: telling someone they have "0 minutes left" while
            // they still have fifty seconds would be a lie they can hear.
            // Short form. This sits in the header now, where a full sentence
            // is simply clipped — and a clipped number is worse than none.
            l.minutesShort((left / 60).ceil()),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: low ? AppColors.warning : Colors.white38,
            ),
          ),
        ],
      ],
    );
  }
}

/// End the conversation.
///
/// Given the middle of the screen because it is now the only thing a learner
/// has to press at all, and because a conversation with no visible way out is
/// one people leave by closing the app — which loses the report they earned.
class _EndButton extends StatelessWidget {
  const _EndButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: l.actionEnd,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(999),
              boxShadow: AppShadow.glow(AppColors.danger),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stop, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  l.actionEnd,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Shown when the microphone was refused.
///
/// Tappable, because the alternative is a session the learner cannot speak in
/// and no way to discover why — the first refusal is often a mis-tap on a
/// dialog that appeared while they were reading something else.
class _MicBlockedChip extends StatelessWidget {
  const _MicBlockedChip({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: InkWell(
        onTap: () => unawaited(onTap()),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic_off, size: 16, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                l.micBlockedTapToAllow,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
