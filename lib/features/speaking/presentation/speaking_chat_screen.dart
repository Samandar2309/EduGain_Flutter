import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme.dart';
import '../../../core/ui/glass.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../data/audio_recorder.dart';
import '../data/tts_service.dart';
import '../domain/models.dart';
import 'avatar/avatar_state.dart';
import 'avatar/edu_gain_avatar_25d.dart';
import 'feedback_view.dart';
import 'scenario_theme.dart';
import 'voice_picker_sheet.dart';
import 'widgets/ai_chat_bubble.dart';
import 'widgets/glass_action.dart';
import 'widgets/mic_button.dart';

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

class _SpeakingChatScreenState extends ConsumerState<SpeakingChatScreen> {
  late final TtsService _tts = ref.read(ttsServiceProvider);
  late final SpeechRecorder _recorder = ref.read(speechRecorderProvider);

  // A track lesson carries its theme key directly; a scenario / free topic is
  // matched from its text.
  late final ScenarioBackdrop _backdrop = widget.launch.backdropKey != null
      ? backdropForKey(widget.launch.backdropKey!)
      : backdropFor(
          slug: widget.launch.scenario?.slug,
          title: widget.launch.scenario?.title,
          category: widget.launch.scenario?.category,
          freeTopic: widget.launch.freeTopic,
        );
  bool _hasBg = false;

  late SpeakingSession _session = widget.launch.started.session;
  late String _aiLine = widget.launch.started.firstMessage.content;
  Coaching? _coaching;
  bool _busy = false;
  bool _recording = false;
  bool _voiceWarned = false;
  bool _greeted = false;
  Timer? _greetSafety;

  @override
  void initState() {
    super.initState();
    _tts.available.addListener(_onTtsChange);
    _tts.speaking.addListener(_onTtsChange);
    _checkBackground();
    // The greeting waits for the avatar stage to be ready (see [_greet]) so the
    // hero's mouth is on screen when it speaks. A safety timer guarantees the
    // welcome never stalls if the engine is slow to report in.
    _greetSafety = Timer(const Duration(seconds: 7), _greet);
  }

  /// Play the scenario's opening line exactly once, the moment the stage is
  /// ready (2D avatar live or fallback engaged).
  void _greet() {
    if (_greeted || !mounted) return;
    _greeted = true;
    _greetSafety?.cancel();
    _tts.enqueue(widget.launch.started.firstMessage.content);
  }

  @override
  void dispose() {
    _greetSafety?.cancel();
    _tts.available.removeListener(_onTtsChange);
    _tts.speaking.removeListener(_onTtsChange);
    unawaited(_tts.stop());
    unawaited(_recorder.cancel());
    super.dispose();
  }

  void _onTtsChange() {
    if (!mounted) return;
    if (!_tts.available.value && !_voiceWarned) {
      _voiceWarned = true;
      _snack(AppLocalizations.of(context).voiceUnavailable);
    }
    setState(() {});
  }

  Future<void> _checkBackground() async {
    try {
      await rootBundle.load(_backdrop.backgroundAsset);
      if (mounted) setState(() => _hasBg = true);
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

  MicState get _micState {
    if (_recording) return MicState.recording;
    if (_tts.speaking.value) return MicState.aiSpeaking;
    if (_busy) return MicState.processing;
    return MicState.ready;
  }

  String get _emotion {
    final s = _avatarState;
    if (s == AvatarState.talking || s == AvatarState.idle) {
      return _coaching?.emotion ?? s.fallbackEmotion;
    }
    return s.fallbackEmotion;
  }

  // ── turns ──────────────────────────────────────────────────────────────
  Future<void> _toggleMic() async {
    if (_busy || _tts.speaking.value) return;
    if (_recording) {
      await _stopAndSend();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!_session.isActive) return;
    final l = AppLocalizations.of(context);
    await _tts.stop();
    final granted = await _recorder.hasPermission();
    if (!granted) {
      _snack(l.micPermission);
      return;
    }
    try {
      await _recorder.start();
      if (mounted) setState(() => _recording = true);
    } catch (_) {
      _snack(l.recordStartError);
    }
  }

  Future<void> _stopAndSend() async {
    final l = AppLocalizations.of(context);
    setState(() => _recording = false);
    final AudioClip? clip;
    try {
      clip = await _recorder.stop();
    } catch (_) {
      _snack(l.audioCaptureError);
      return;
    }
    if (clip == null) return;
    await _runTurn(
      () => ref
          .read(speakingRepositoryProvider)
          .streamAudioReply(_session.id, clip!.path, clip.filename),
    );
  }

  Future<void> _runTurn(Stream<SpeakingEvent> Function() openStream) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _aiLine = '';
      _coaching = null;
      _busy = true;
    });
    final reply = StringBuffer();
    final chunker = SentenceChunker();
    await _tts.stop();

    try {
      await for (final event in openStream()) {
        switch (event) {
          case TranscriptEvent():
            break; // the learner's words aren't shown on the avatar stage
          case ChunkEvent(:final text):
            reply.write(text);
            for (final sentence in chunker.add(text)) {
              _tts.enqueue(sentence);
            }
            setState(() => _aiLine = reply.toString());
          case CoachingEvent(:final coaching):
            setState(() => _coaching = coaching);
          case DoneEvent(:final session):
            for (final sentence in chunker.finish()) {
              _tts.enqueue(sentence);
            }
            setState(() => _session = session);
          case StreamErrorEvent(:final message):
            _snack(message.isEmpty ? l.aiUnavailable : message);
        }
      }
    } on ApiException catch (e) {
      if (e.statusCode == 402) {
        _snack(l.turnLimitReached);
      } else if (e.statusCode == 422) {
        _snack(l.speechNotRecognized);
      } else {
        _snack(e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    if (_recording) {
      await _recorder.cancel();
      if (mounted) setState(() => _recording = false);
    }
    await _tts.stop();
    setState(() => _busy = true);
    try {
      final feedback =
          await ref.read(speakingRepositoryProvider).endSession(_session.id);
      if (mounted) await showFeedbackSheet(context, feedback);
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

  // ── Translate / Hint sheets ────────────────────────────────────────────
  void _showTranslate() {
    final l = AppLocalizations.of(context);
    _sheet(
      icon: Icons.translate_rounded,
      title: l.actionTranslate,
      body: _aiLine.isEmpty ? '—' : _aiLine,
    );
  }

  void _showHint() {
    final l = AppLocalizations.of(context);
    _sheet(icon: Icons.lightbulb_rounded, title: l.hintTitle, body: l.hintTip);
  }

  void _sheet({required IconData icon, required String title, required String body}) {
    showModalBottomSheet<void>(
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
              Text(
                body,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  height: 1.4,
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
    final active = _session.isActive;
    final canTalk = active && _micState == MicState.ready;

    final voices = ref.watch(voicesProvider).valueOrNull ?? const <Voice>[];
    _tts.voice = _effectiveVoice(voices, ref.watch(selectedVoiceProvider));

    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: AppColors.canvasDark,
        body: Stack(
          children: [
            // 1 ─ the scenario scene, then the full-screen avatar standing in it.
            Positioned.fill(child: _background(accent)),
            Positioned.fill(
              child: EduGainAvatar25D(
                backdrop: _backdrop,
                emotion: _emotion,
                state: _avatarState,
                level: _tts.level,
                fillScreen: true,
                onReady: _greet,
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
                    title: widget.launch.scenario?.title ??
                        widget.launch.title ??
                        l.lessonsTitle,
                    onEnd: _busy ? null : _end,
                    onVoice: () => showVoicePicker(context),
                    voiceOff: !_tts.available.value,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  // AI speech bubble floats near the top, in the head's headroom.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                    child: AiChatBubble(
                      text: _aiLine,
                      thinking: _avatarState == AvatarState.thinking,
                    ),
                  ),
                  const Spacer(),
                  _StatusChip(state: _avatarState, accent: accent),
                  const SizedBox(height: AppSpace.md),
                  if (_coaching != null && _coaching!.hasErrors)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, AppSpace.md),
                      child: _CoachingStrip(coaching: _coaching!, accent: accent),
                    ),
                  if (!active)
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
                  // Bottom controls: Translate · Mic · Hint.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpace.lg),
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
                              onTap: _aiLine.isEmpty ? null : _showTranslate,
                            ),
                          ),
                        ),
                        MicButton(
                          state: _micState,
                          accent: accent,
                          onTap: canTalk || _recording ? _toggleMic : null,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GlassAction(
                              icon: Icons.lightbulb_outline_rounded,
                              label: l.actionHint,
                              accent: accent,
                              onTap: active ? _showHint : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  });

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
          TextButton.icon(
            onPressed: onEnd,
            icon: const Icon(Icons.flag_rounded, size: 18),
            label: Text(l.finishSession),
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
          ),
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
