import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// A white, softly-shadowed rounded card. The premium building block — use this
/// instead of [Card] for the new look. Optionally tappable.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.onTap,
    this.color,
    this.radius = AppRadius.lg,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadow.card,
        border: border,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A rounded-square icon chip filled with an accent gradient — used as the
/// leading element on module/list cards.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.iconSize = 24,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.accent(color),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: AppShadow.glow(color),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

/// The EduGain brand mark: a graduation cap on an emerald gradient tile.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(size * 0.30),
        boxShadow: AppShadow.glow(AppColors.brand),
      ),
      child: Icon(Icons.school_rounded, color: Colors.white, size: size * 0.52),
    );
  }
}

/// A section title with an optional trailing action (e.g. "Barchasi").
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// A small pill showing an icon + value + label (XP, streak, level…).
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onLight = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  /// When placed on a coloured/gradient header, render in white.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = onLight ? Colors.white : AppColors.ink;
    final sub = onLight ? Colors.white70 : AppColors.inkSoft;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: onLight ? Colors.white : color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: sub),
            ),
          ],
        ),
      ],
    );
  }
}

/// A circular progress ring with a label in the centre. Used for the daily goal.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 84,
    this.stroke = 9,
    this.color = Colors.white,
    this.trackColor,
    this.center,
  });

  /// 0..1
  final double progress;
  final double size;
  final double stroke;
  final Color color;
  final Color? trackColor;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0, 1),
          stroke: stroke,
          color: color,
          trackColor: trackColor ?? color.withValues(alpha: 0.22),
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double stroke;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}

/// A full-bleed brand gradient panel with rounded bottom corners — the hero
/// header used at the top of primary screens.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.xl,
      AppSpace.lg,
      AppSpace.xl,
      AppSpace.xxl,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2610B981),
            blurRadius: 24,
            offset: Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: SafeArea(bottom: false, child: Padding(padding: padding, child: child)),
    );
  }
}

/// A full-screen centred loader on the page background.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.brand, strokeWidth: 3),
  );
}
