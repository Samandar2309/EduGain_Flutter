import 'dart:ui';

import 'package:flutter/material.dart';

import 'tokens.dart';

/// A frosted-glass surface (glassmorphism): a blurred, translucent panel with a
/// hairline highlight border. The backdrop blur is real (`BackdropFilter`), so
/// it reads against the dark gradient / scenario background behind it. Used for
/// every floating surface in the immersive speaking screen.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.radius = AppRadius.lg,
    this.blur = 18,
    this.opacity = 0.10,
    this.borderOpacity = 0.18,
    this.color = Colors.white,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // A soft top-down sheen makes the glass feel lit from above.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: opacity + 0.04),
                color.withValues(alpha: opacity),
              ],
            ),
            borderRadius: r,
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The immersive dark backdrop for the speaking screen — a deep vertical
/// gradient (scenario-tinted), two soft radial accent glows for depth, and an
/// optional huge faint icon watermark that gives each scenario its own
/// character without any image assets. Sits behind the avatar and glass panels.
class ImmersiveBackground extends StatelessWidget {
  const ImmersiveBackground({
    this.top = const Color(0xFF131A2A),
    this.bottom = const Color(0xFF0B1120),
    this.accent = AppColors.speaking,
    this.watermark,
    super.key,
  });

  final Color top;
  final Color bottom;
  final Color accent;
  final IconData? watermark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      child: Stack(
        children: [
          if (watermark != null)
            Positioned(
              right: -40,
              bottom: 40,
              child: Transform.rotate(
                angle: -0.18,
                child: Icon(
                  watermark,
                  size: 260,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(color: accent, size: 320, opacity: 0.24),
          ),
          Positioned(
            bottom: -100,
            left: -90,
            child: _Glow(
              color: Color.lerp(accent, AppColors.brand, 0.5)!,
              size: 280,
              opacity: 0.14,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
