import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../scenario_theme.dart';
import 'speaking_avatar.dart';

/// The on-screen tutor. If a realistic rendered character image exists for the
/// scenario (`assets/avatars/<key>.png`) it is shown and brought to life —
/// gentle breathing, a voice-synced "speaking" scale + glow, and lip-sync by
/// cross-fading to a mouth-open variant (`<key>_talk.png`) with the live level.
/// When no image is bundled, it falls back to the procedural [SpeakingAvatar],
/// so the app always works and gets photoreal the moment art is dropped in.
class AvatarView extends StatefulWidget {
  const AvatarView({
    required this.backdrop,
    required this.emotion,
    required this.level,
    this.size = 200,
    super.key,
  });

  final ScenarioBackdrop backdrop;
  final String emotion;
  final ValueListenable<double> level;
  final double size;

  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  bool _checked = false;
  bool _hasImage = false;
  bool _hasTalk = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(AvatarView old) {
    super.didUpdateWidget(old);
    if (old.backdrop.key != widget.backdrop.key) _check();
  }

  Future<void> _check() async {
    final img = await _exists(widget.backdrop.avatarAsset);
    final talk = await _exists(widget.backdrop.avatarTalkAsset);
    if (mounted) {
      setState(() {
        _checked = true;
        _hasImage = img;
        _hasTalk = talk;
      });
    }
  }

  static Future<bool> _exists(String asset) async {
    try {
      await rootBundle.load(asset);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Until we know, and whenever there's no rendered art, use the procedural one.
    if (!_checked || !_hasImage) {
      return SpeakingAvatar(
        emotion: widget.emotion,
        level: widget.level,
        accent: widget.backdrop.accent,
        size: widget.size,
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) {
          final bob = math.sin(_breath.value * 2 * math.pi);
          return ValueListenableBuilder<double>(
            valueListenable: widget.level,
            builder: (context, lvl, __) {
              final scale = 1 + bob * 0.012 + lvl * 0.022;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Soft glow that breathes with the voice.
                  Container(
                    width: widget.size * 0.8,
                    height: widget.size * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.backdrop.accent
                              .withValues(alpha: 0.18 + lvl * 0.3),
                          widget.backdrop.accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -bob * widget.size * 0.01),
                    child: Transform.scale(
                      scale: scale,
                      // Realistic renders carry their own scene background, so
                      // they're framed as a premium rounded portrait tile (like
                      // the mockups) rather than a floating cut-out.
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.size * 0.16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.backdrop.accent
                                  .withValues(alpha: 0.22 + lvl * 0.3),
                              blurRadius: 30,
                              spreadRadius: -6,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.size * 0.16),
                          child: SizedBox(
                            width: widget.size,
                            height: widget.size,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  widget.backdrop.avatarAsset,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                ),
                                // Lip-sync: mouth-open frame fades in with loudness.
                                if (_hasTalk && lvl > 0.02)
                                  Opacity(
                                    opacity: lvl.clamp(0.0, 1.0),
                                    child: Image.asset(
                                      widget.backdrop.avatarTalkAsset,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
