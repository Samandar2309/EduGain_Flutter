import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/ui/tokens.dart';

/// The countdown, drawn as a draining ring.
///
/// A bare number tells you how long is left; a ring tells you at a glance,
/// which is what a fifteen-second question needs — the player should never
/// have to read the timer to feel it.
///
/// The colour shift is the urgency: brand while there is room to think, amber
/// at a third left, red in the last few seconds.
class QuizTimerRing extends StatelessWidget {
  const QuizTimerRing({
    required this.secondsLeft,
    required this.total,
    this.size = 76,
    super.key,
  });

  final double secondsLeft;
  final double total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (secondsLeft / total).clamp(0.0, 1.0);
    final colour = switch (fraction) {
      < 0.2 => AppColors.danger,
      < 0.4 => AppColors.warning,
      _ => AppColors.brand,
    };
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Not animated between frames: the value already arrives twenty
          // times a second, and an implicit animation on top of that lags
          // behind the number in the middle.
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(fraction: fraction, colour: colour),
          ),
          Text(
            secondsLeft.ceil().toString(),
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              color: colour,
              // Digits must not jitter as the width of "9" and "1" differ.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.colour});

  final double fraction;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.line,
    );
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = colour,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.colour != colour;
}
