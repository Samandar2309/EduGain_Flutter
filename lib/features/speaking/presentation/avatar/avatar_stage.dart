import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../scenario_theme.dart';
import 'avatar_state.dart';
import 'vector_hero_view.dart';

/// The tutor's stage — a fully code-drawn ([VectorHeroView]) character in the
/// Pixar-render style. Because it's built from scratch (no photo, no assets),
/// it's dressed for the scenario, posed freely, lip-syncs to the AI's voice
/// with syllable-shaped visemes, and reacts to the learner's words through the
/// AI's coaching emotion.
///
/// No engine, no platform views, no image decode: it renders through Flutter's
/// own pipeline at 60 FPS on low-end devices and inside the Telegram Mini App
/// WebView, and is live on the first frame ([onReady] fires immediately; the
/// greeting never waits).
class AvatarStage extends StatelessWidget {
  const AvatarStage({
    required this.backdrop,
    required this.emotion,
    required this.state,
    required this.level,
    this.size = 230,
    this.fillScreen = false,
    this.onReady,
    super.key,
  });

  final ScenarioBackdrop backdrop;
  final String emotion;
  final AvatarState state;
  final ValueListenable<double> level;
  final double size;

  /// When true the avatar is the whole stage: an edge-to-edge figure framed
  /// head-and-chest over the scenario backdrop. When false it's a framed bust.
  final bool fillScreen;

  /// Fires once, after the first frame — the stage is live immediately.
  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) {
    if (onReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onReady!.call());
    }
    final hero = VectorHeroView(
      outfit: backdrop.heroOutfit,
      emotion: emotion,
      state: state,
      level: level,
      accent: backdrop.accent,
    );
    if (fillScreen) return hero;
    return _framed(hero);
  }

  /// The compact framed bust — a rounded, themed "portrait stage".
  Widget _framed(Widget face) {
    final accent = backdrop.accent;
    return Container(
      width: size,
      height: size * 1.18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.26),
            blurRadius: 32,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backdrop.top, backdrop.bottom],
            ),
          ),
          child: face,
        ),
      ),
    );
  }
}
