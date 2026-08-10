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

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _recorder = ref.read(speechRecorderProvider);
    WidgetsBinding.instance.addObserver(this);
    _listenWatchdog = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _ensureListening(),
    );
    _tts.available.addListener(_onTtsChange);
    _tts.speaking.addListener(_onTtsChange);
    _checkBackground();
    // The greeting waits for the avatar stage to be ready (see [_greet]) so the
    // hero's mouth is on screen when it speaks. A safety timer guarantees the
    // welcome never stalls if the engine is slow to report in.
    _greetSafety = Timer(const Duration(seconds: 7), _greetAnyway);
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
    _disarm();
    _capTimer?.cancel();
    _tts.available.removeListener(_onTtsChange);
    _tts.speaking.removeListener(_onTtsChange);
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
    if (!_tts.speaking.value) _armAfterTutor();
  }

  /// Open the microphone once the tutor finishes, after a short beat.
  ///
  /// The beat matters: opening the instant the audio ends catches the tail of
  /// the tutor's own voice through the speaker on some phones, and the learner
  /// then hears themselves answered by an echo.
  void _armAfterTutor() {
    if (!mounted || _recording || _busy || !_session.isActive) return;
    _armTimer?.cancel();
    _armTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || _recording || _busy || _tts.speaking.value) return;
      unawaited(_startRecording(autoStarted: true));
    });
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
      await _recorder.start(onLevel: _onLevel);
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
      // The one place a refusal now lands. Latched rather than switched off for
      // good: the learner is shown a way to grant it and the loop resumes the
      // moment they do — and an automatic attempt that fails says nothing,
      // because nobody pressed anything.
      if (!autoStarted) _snack(l.micPermission);
      if (mounted) setState(() => _micBlocked = true);
    }
  }

  /// Live loudness from the recorder. Decides when the turn ended.
  void _onLevel(double level) {
    if (!_armed || !_recording || !mounted) return;
    final elapsed = _sinceLastLevel.isRunning
        ? _sinceLastLevel.elapsed
        : const Duration(milliseconds: 120);
    _sinceLastLevel
      ..reset()
      ..start();
    switch (_vad.onLevel(level, elapsed)) {
      case VoiceVerdict.keepListening:
        return;
      case VoiceVerdict.endOfTurn:
        _armed = false;
        unawaited(_stopAndSend());
      case VoiceVerdict.nothingHeard:
        // Say so, once. The loudness floor cannot be right for every phone and
        // every room, and a learner who is speaking into a microphone that
        // hears nothing gets no signal at all — they simply talk to a screen
        // that never answers. Telling them beats guessing better numbers.
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
    final AudioClip? clip;
    try {
      clip = await _recorder.stop();
    } catch (_) {
      _snack(l.audioCaptureError);
      // Clear `_busy` before re-arming: it was set above to close the overlap
      // window, and `_ensureListening` refuses to open the mic while it is
      // set. Leaving it would strand the learner exactly as the old
      // dead-end paths did.
      _resumeListening();
      return;
    }
    if (clip == null) {
      _resumeListening();
      return;
    }
    _uploadStarted = DateTime.now();
    await _runTurn(
      () => ref.read(speakingRepositoryProvider).streamAudioReply(
            _session.id,
            clip!.bytes,
            clip.filename,
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
    final chunker = SentenceChunker();
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
        switch (event) {
          case TranscriptEvent(:final text, :final wasHardToHear):
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
            for (final sentence in chunker.add(text)) {
              _tts.enqueue(sentence);
            }
            // The hot path: notifier only — no setState, no tree rebuild.
            _line.value = reply.toString();
            if (!_hasLine) setState(() => _hasLine = true);
          case CoachingEvent(:final coaching):
            setState(() => _coaching = coaching);
          case DoneEvent(:final session):
            for (final sentence in chunker.finish()) {
              _tts.enqueue(sentence);
            }
            // Everything that will be said has been queued; the player may end
            // the turn once it drains.
            _tts.endStream();
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
      // Always, not just on the happy path: a stream that errors or is cut off
      // would otherwise leave the player believing more sentences are coming,
      // and it would hold the turn open for ever — the microphone would never
      // re-open and the session would be dead with nothing on screen to say so.
      _tts.endStream();
      _upload.value = null; // never leave a progress reading behind
      _uploadStarted = null;
      if (mounted) setState(() => _busy = false);
    }
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
      () => ref.read(speakingRepositoryProvider).streamReply(_session.id, text),
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

  Future<void> _end() async {
    // Read before the first await: everything below runs across async gaps.
    final l = AppLocalizations.of(context);
    _capTimer?.cancel();
    if (_recording) {
      await _recorder.cancel();
      if (mounted) setState(() => _recording = false);
    }
    await _tts.stop();
    if (!mounted) return;
    setState(() => _busy = true);
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
    if (!_voiceSettled &&
        selection.isLoaded &&
        (voicesAsync.hasValue || voicesAsync.hasError)) {
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
                      child: _CoachingStrip(coaching: _coaching!, accent: accent),
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
class _CoachingStrip extends StatelessWidget {
  const _CoachingStrip({required this.coaching, required this.accent});

  final Coaching coaching;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final correction = coaching.correction;
    if (correction.isEmpty) return const SizedBox.shrink();
    return GlassPanel(
      opacity: 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.auto_fix_high_rounded, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                children: [
                  TextSpan(
                    text: '${l.coachCorrection}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: correction),
                ],
              ),
            ),
          ),
        ],
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
