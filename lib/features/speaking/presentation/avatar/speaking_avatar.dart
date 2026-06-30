import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A fully procedural, 60 FPS tutor avatar — a friendly character *bust*
/// (shoulders, vest, tie, head) drawn with a single [CustomPainter], no assets
/// and no 3D engine. It is built to feel alive:
///  • idle — breathing, slow head sway + micro-tilt, natural blinks and gaze
///    saccades, tiny eyebrow drift;
///  • reacts — the whole expression (eyes, brows, mouth, head tilt) eases toward
///    the AI's `emotion`;
///  • talks — the mouth (with teeth) opens to the live voice `level` (0..1).
///
/// Swappable for a Rive / Ready Player Me 3D avatar behind the same
/// (`emotion`, `level`) interface.
class SpeakingAvatar extends StatefulWidget {
  const SpeakingAvatar({
    required this.emotion,
    required this.level,
    this.accent = const Color(0xFF6366F1),
    this.size = 200,
    super.key,
  });

  /// One of: neutral, happy, encouraging, surprised, thinking, proud, curious.
  final String emotion;

  /// Live mouth openness (0..1) of the AI's voice — drives the mouth + glow.
  final ValueListenable<double> level;

  /// Scenario accent, used for the glow halo.
  final Color accent;
  final double size;

  @override
  State<SpeakingAvatar> createState() => _SpeakingAvatarState();
}

class _SpeakingAvatarState extends State<SpeakingAvatar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  final math.Random _rng = math.Random();

  Duration _last = Duration.zero;
  double _t = 0; // elapsed seconds

  _Face _face = _faceFor('neutral');
  double _blink = 0; // 0 open .. 1 closed
  double _blinkPhase = 0;
  double _blinkIn = 2.5;
  double _mouth = 0; // 0 closed .. 1 open

  // Eye gaze: a target the eyes saccade to and hold, then drift on.
  Offset _gaze = Offset.zero;
  Offset _gazeTarget = Offset.zero;
  double _gazeIn = 1.5;

  @override
  void initState() {
    super.initState();
    _face = _faceFor(widget.emotion);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  static const double _blinkDur = 0.13;

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _t += dt;

    // Ease the expression toward the target (frame-rate-safe exponential).
    _face = _Face.lerp(_face, _faceFor(widget.emotion), 1 - math.exp(-dt * 6));

    // Blink: a quick close-open pulse every few seconds.
    if (_blinkPhase > 0) {
      _blinkPhase -= dt;
      _blink = math.sin((1 - _blinkPhase / _blinkDur).clamp(0.0, 1.0) * math.pi);
    } else {
      _blink = 0;
      _blinkIn -= dt;
      if (_blinkIn <= 0) {
        _blinkPhase = _blinkDur;
        _blinkIn = 2.0 + _rng.nextDouble() * 3.5;
      }
    }

    // Gaze saccades: hop to a new nearby target, then ease toward it.
    _gazeIn -= dt;
    if (_gazeIn <= 0) {
      _gazeIn = 1.2 + _rng.nextDouble() * 2.8;
      _gazeTarget = Offset(
        (_rng.nextDouble() * 2 - 1) * 0.5,
        (_rng.nextDouble() * 2 - 1) * 0.35,
      );
    }
    _gaze = Offset.lerp(_gaze, _gazeTarget, 1 - math.exp(-dt * 9))!;

    // Mouth follows the live voice loudness, smoothed to 60 FPS.
    _mouth = lerpDouble(_mouth, widget.level.value.clamp(0.0, 1.0),
        1 - math.exp(-dt * 22))!;

    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AvatarPainter(
            repaint: _frame,
            state: this,
            accent: widget.accent,
          ),
        ),
      ),
    );
  }
}

/// Smoothable expression parameters (all normalised).
@immutable
class _Face {
  const _Face(this.smile, this.brow, this.wide, this.narrow, this.tilt);

  final double smile; // -1 frown .. 1 big smile
  final double brow; // 0 .. 1 raised
  final double wide; // 0 .. 1 eyes widened (surprise)
  final double narrow; // 0 .. 1 eyes narrowed (focus)
  final double tilt; // head tilt in radians (signed)

  static _Face lerp(_Face a, _Face b, double t) => _Face(
    lerpDouble(a.smile, b.smile, t)!,
    lerpDouble(a.brow, b.brow, t)!,
    lerpDouble(a.wide, b.wide, t)!,
    lerpDouble(a.narrow, b.narrow, t)!,
    lerpDouble(a.tilt, b.tilt, t)!,
  );
}

_Face _faceFor(String emotion) => switch (emotion) {
  'happy' => const _Face(0.9, 0.35, 0.15, 0, 0.02),
  'proud' => const _Face(0.7, 0.3, 0.1, 0.1, 0.0),
  'encouraging' => const _Face(0.6, 0.4, 0.2, 0, 0.03),
  'surprised' => const _Face(0.2, 0.95, 0.9, 0, 0.0),
  'thinking' => const _Face(-0.05, 0.2, 0, 0.45, -0.07),
  'curious' => const _Face(0.35, 0.7, 0.55, 0, -0.06),
  _ => const _Face(0.25, 0.28, 0.2, 0, 0.0), // neutral
};

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({
    required Listenable repaint,
    required this.state,
    required this.accent,
  }) : super(repaint: repaint);

  final _SpeakingAvatarState state;
  final Color accent;

  // ── palette (warm Pixar-ish concierge) ──────────────────────────────────
  static const _skinHi = Color(0xFFF7CBA3);
  static const _skinMid = Color(0xFFECB084);
  static const _skinShadow = Color(0xFFD8966E);
  static const _hairDark = Color(0xFF2C2017);
  static const _hairHi = Color(0xFF4A3526);
  static const _brow = Color(0xFF2A1D14);
  static const _eyeWhite = Color(0xFFFBFCFF);
  static const _iris = Color(0xFF6E4A2C);
  static const _pupil = Color(0xFF180F08);
  static const _lip = Color(0xFFC1766A);
  static const _mouthIn = Color(0xFF5C2B2F);
  static const _teeth = Color(0xFFFAFBFF);
  static const _shirt = Color(0xFFE9EDF4);
  static const _vestTop = Color(0xFF2C3344);
  static const _vestBot = Color(0xFF1A2030);
  static const _tieTop = Color(0xFF2E3E60);
  static const _tieBot = Color(0xFF1E2A45);

  @override
  void paint(Canvas canvas, Size size) {
    final f = state._face;
    final t = state._t;
    final w = size.width;

    final breathe = math.sin(t * 1.7) * w * 0.009;
    final swayX = math.sin(t * 0.55) * w * 0.012 + math.sin(t * 0.21) * w * 0.008;
    final tilt = f.tilt + math.sin(t * 0.4) * 0.022;

    final headC = Offset(w * 0.5 + swayX * 0.6, w * 0.40 + breathe);
    final rx = w * 0.205;
    final ry = w * 0.245;

    _drawGlow(canvas, headC, w);
    _drawTorso(canvas, size, breathe, swayX);

    // Head group: sway + tilt around the head centre.
    canvas.save();
    canvas.translate(headC.dx, headC.dy);
    canvas.rotate(tilt);
    canvas.translate(-headC.dx, -headC.dy);
    _drawNeck(canvas, headC, rx, ry, w);
    _drawHead(canvas, headC, rx, ry, w, f);
    canvas.restore();
  }

  void _drawGlow(Canvas canvas, Offset c, double w) {
    final glow = 0.16 + state._mouth * 0.32;
    canvas.drawCircle(
      c,
      w * 0.42,
      Paint()
        ..color = accent.withValues(alpha: glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
  }

  // ── torso: shoulders, shirt, vest, tie, badge ───────────────────────────
  void _drawTorso(Canvas canvas, Size size, double breathe, double swayX) {
    final w = size.width;
    final topY = w * 0.74 + breathe * 0.5;
    final cx = w * 0.5 + swayX * 0.2;

    // Shoulders/vest body — a wide rounded shape running off the bottom edges.
    final vest = Path()
      ..moveTo(cx - w * 0.50, w + 4)
      ..lineTo(cx - w * 0.46, topY + w * 0.06)
      ..quadraticBezierTo(cx - w * 0.30, topY - w * 0.02, cx - w * 0.13, topY + w * 0.02)
      ..lineTo(cx + w * 0.13, topY + w * 0.02)
      ..quadraticBezierTo(cx + w * 0.30, topY - w * 0.02, cx + w * 0.46, topY + w * 0.06)
      ..lineTo(cx + w * 0.50, w + 4)
      ..close();
    canvas.drawPath(
      vest,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_vestTop, _vestBot],
        ).createShader(Rect.fromLTWH(0, topY, w, w - topY)),
    );

    // Shirt: a light triangle in the chest opening + the collar.
    final shirt = Path()
      ..moveTo(cx - w * 0.13, topY + w * 0.02)
      ..lineTo(cx, w)
      ..lineTo(cx + w * 0.13, topY + w * 0.02)
      ..close();
    canvas.drawPath(shirt, Paint()..color = _shirt);

    // Collar shadow lines.
    final collar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..color = Colors.black.withValues(alpha: 0.10);
    canvas.drawLine(Offset(cx - w * 0.12, topY + w * 0.03),
        Offset(cx - w * 0.03, topY + w * 0.14), collar);
    canvas.drawLine(Offset(cx + w * 0.12, topY + w * 0.03),
        Offset(cx + w * 0.03, topY + w * 0.14), collar);

    // Tie.
    final tie = Path()
      ..moveTo(cx - w * 0.035, topY + w * 0.05)
      ..lineTo(cx + w * 0.035, topY + w * 0.05)
      ..lineTo(cx + w * 0.05, w)
      ..lineTo(cx - w * 0.05, w)
      ..close();
    canvas.drawPath(
      tie,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_tieTop, _tieBot],
        ).createShader(Rect.fromLTWH(cx - w * 0.06, topY, w * 0.12, w - topY)),
    );
    // Tie knot.
    canvas.drawCircle(
      Offset(cx, topY + w * 0.055),
      w * 0.028,
      Paint()..color = _tieTop,
    );

    // Name badge (accent chip) on the chest.
    final badge = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + w * 0.20, topY + w * 0.15),
        width: w * 0.16,
        height: w * 0.05,
      ),
      Radius.circular(w * 0.012),
    );
    canvas.drawRRect(badge, Paint()..color = accent.withValues(alpha: 0.9));
  }

  void _drawNeck(Canvas canvas, Offset c, double rx, double ry, double w) {
    final neck = Path()
      ..moveTo(c.dx - rx * 0.32, c.dy + ry * 0.66)
      ..lineTo(c.dx - rx * 0.38, w * 0.80)
      ..lineTo(c.dx + rx * 0.38, w * 0.80)
      ..lineTo(c.dx + rx * 0.32, c.dy + ry * 0.66)
      ..close();
    canvas.drawPath(neck, Paint()..color = _skinMid);
    // Jaw shadow where the neck meets the chin.
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - rx * 0.34, c.dy + ry * 0.62)
        ..quadraticBezierTo(c.dx, c.dy + ry * 0.74, c.dx + rx * 0.34, c.dy + ry * 0.62)
        ..quadraticBezierTo(c.dx, c.dy + ry * 0.70, c.dx - rx * 0.34, c.dy + ry * 0.62)
        ..close(),
      Paint()..color = _skinShadow.withValues(alpha: 0.5),
    );
  }

  // ── head + face ─────────────────────────────────────────────────────────
  void _drawHead(Canvas canvas, Offset c, double rx, double ry, double w, _Face f) {
    final headRect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);

    // Ears.
    for (final s in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(c.dx + s * rx * 0.98, c.dy + ry * 0.06),
        rx * 0.16,
        Paint()..color = _skinMid,
      );
    }

    // Face (oval) with vertical warm gradient + soft jaw shading.
    canvas.drawOval(
      headRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skinHi, _skinMid, _skinShadow],
          stops: [0.0, 0.62, 1.0],
        ).createShader(headRect),
    );
    // 3D volume: a key light from the top-left, ambient occlusion toward the
    // edges — turns the flat oval into a rounded, lit face.
    canvas.drawOval(
      headRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.98,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            const Color(0x00000000),
            _skinShadow.withValues(alpha: 0.34),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(headRect),
    );
    // Soft shadow the hair casts across the forehead.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy - ry * 0.40),
        width: rx * 1.5,
        height: ry * 0.5,
      ),
      Paint()
        ..color = _skinShadow.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ry * 0.12),
    );

    _drawHairBack(canvas, c, rx, ry);
    _drawBrows(canvas, c, rx, ry, f);
    _drawEyes(canvas, c, rx, ry, f);
    _drawNose(canvas, c, rx, ry);
    _drawMouth(canvas, c, rx, ry, f);
    _drawCheeks(canvas, c, rx, ry, f);
    _drawHairFront(canvas, c, rx, ry);
  }

  void _drawHairBack(Canvas canvas, Offset c, double rx, double ry) {
    // A rounded cap behind the head, slightly wider than the skull.
    final cap = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - ry * 0.06),
          width: rx * 2.16,
          height: ry * 2.0,
        ),
        math.pi,
        math.pi,
      )
      ..close();
    canvas.drawPath(cap, Paint()..color = _hairDark);
  }

  void _drawHairFront(Canvas canvas, Offset c, double rx, double ry) {
    // Swept fringe across the forehead with a side parting on the left.
    final top = c.dy - ry * 0.78;
    final fringe = Path()
      ..moveTo(c.dx - rx * 1.02, c.dy - ry * 0.30)
      ..quadraticBezierTo(c.dx - rx * 1.06, top, c.dx - rx * 0.2, top - ry * 0.06)
      ..quadraticBezierTo(c.dx + rx * 0.5, top - ry * 0.10, c.dx + rx * 1.02, c.dy - ry * 0.22)
      ..quadraticBezierTo(c.dx + rx * 0.7, c.dy - ry * 0.46, c.dx + rx * 0.10, c.dy - ry * 0.40)
      ..quadraticBezierTo(c.dx - rx * 0.5, c.dy - ry * 0.36, c.dx - rx * 0.72, c.dy - ry * 0.18)
      ..quadraticBezierTo(c.dx - rx * 0.95, c.dy - ry * 0.20, c.dx - rx * 1.02, c.dy - ry * 0.30)
      ..close();
    canvas.drawPath(fringe, Paint()..color = _hairDark);
    // Subtle highlight strand.
    final hi = Path()
      ..moveTo(c.dx - rx * 0.1, top + ry * 0.02)
      ..quadraticBezierTo(c.dx + rx * 0.4, top - ry * 0.02, c.dx + rx * 0.85, c.dy - ry * 0.26);
    canvas.drawPath(
      hi,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rx * 0.05
        ..strokeCap = StrokeCap.round
        ..color = _hairHi.withValues(alpha: 0.7),
    );
  }

  void _drawBrows(Canvas canvas, Offset c, double rx, double ry, _Face f) {
    // Thick, low, fairly straight brows sitting just above the eyes.
    final y = c.dy - ry * 0.20 - f.brow * ry * 0.11;
    final paint = Paint()
      ..color = _brow
      ..style = PaintingStyle.stroke
      ..strokeWidth = ry * 0.11
      ..strokeCap = StrokeCap.round;
    final wiggle = math.sin(state._t * 0.9) * ry * 0.012;
    for (final s in [-1.0, 1.0]) {
      final inner = Offset(c.dx + s * rx * 0.22, y + f.narrow * ry * 0.11 + wiggle);
      final mid = Offset(c.dx + s * rx * 0.50, y - ry * 0.03);
      final outer = Offset(c.dx + s * rx * 0.76, y);
      canvas.drawPath(
        Path()
          ..moveTo(inner.dx, inner.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, outer.dx, outer.dy),
        paint,
      );
    }
  }

  // A pointed-corner almond eye (looks like an eye, not a round lens).
  Path _almond(Offset e, double w, double h) => Path()
    ..moveTo(e.dx - w, e.dy)
    ..quadraticBezierTo(e.dx, e.dy - h, e.dx + w, e.dy)
    ..quadraticBezierTo(e.dx, e.dy + h * 0.85, e.dx - w, e.dy)
    ..close();

  void _drawEyes(Canvas canvas, Offset c, double rx, double ry, _Face f) {
    final open = (1 - state._blink).clamp(0.0, 1.0);
    final dx = rx * 0.50;
    final ey = c.dy - ry * 0.02;
    final ew = rx * 0.30;
    final eh = ry * 0.16 * (1 + f.wide * 0.4 - f.narrow * 0.4);
    final look = Offset(state._gaze.dx * rx * 0.09, state._gaze.dy * ry * 0.07);

    for (final s in [-1.0, 1.0]) {
      final eye = Offset(c.dx + s * dx, ey);
      if (open < 0.10) {
        canvas.drawPath(
          Path()
            ..moveTo(eye.dx - ew, eye.dy)
            ..quadraticBezierTo(eye.dx, eye.dy + eh * 0.5, eye.dx + ew, eye.dy),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ry * 0.03
            ..strokeCap = StrokeCap.round
            ..color = _brow,
        );
        continue;
      }
      final almond = _almond(eye, ew, eh * open);
      canvas.save();
      canvas.clipPath(almond);
      canvas.drawRect(
        Rect.fromCenter(center: eye, width: ew * 2.2, height: eh * 2.4),
        Paint()..color = _eyeWhite,
      );
      // Big iris that touches top & bottom — white only peeks at the corners.
      final iris = Offset(eye.dx + look.dx, eye.dy + look.dy + eh * 0.10);
      final irisR = eh * 1.18;
      canvas.drawCircle(iris, irisR, Paint()..color = _iris);
      canvas.drawCircle(iris, irisR * 0.52, Paint()..color = _pupil);
      canvas.drawCircle(
        iris.translate(-irisR * 0.32, -irisR * 0.36),
        irisR * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
      canvas.restore();
      // Dark upper-lid / lash line frames it as an eye (kills the lens look).
      canvas.drawPath(
        Path()
          ..moveTo(eye.dx - ew, eye.dy)
          ..quadraticBezierTo(eye.dx, eye.dy - eh * open, eye.dx + ew, eye.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ry * 0.034
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF3A2A1E),
      );
    }
  }

  void _drawNose(Canvas canvas, Offset c, double rx, double ry) {
    final bridgeTop = c.dy - ry * 0.10;
    final tip = Offset(c.dx, c.dy + ry * 0.20);
    // Bridge shadow down one side for depth.
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - rx * 0.05, bridgeTop)
        ..quadraticBezierTo(c.dx - rx * 0.075, c.dy + ry * 0.06, c.dx - rx * 0.02, tip.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rx * 0.045
        ..strokeCap = StrokeCap.round
        ..color = _skinShadow.withValues(alpha: 0.32),
    );
    // Soft lit tip with an under-shadow.
    canvas.drawCircle(
      tip.translate(0, ry * 0.02),
      rx * 0.12,
      Paint()
        ..color = _skinShadow.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rx * 0.07),
    );
    canvas.drawCircle(
      tip.translate(-rx * 0.02, -rx * 0.02),
      rx * 0.07,
      Paint()
        ..color = _skinHi.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rx * 0.05),
    );
    // Nostrils.
    for (final s in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(c.dx + s * rx * 0.085, tip.dy + ry * 0.02),
        rx * 0.022,
        Paint()..color = _skinShadow.withValues(alpha: 0.6),
      );
    }
  }

  void _drawMouth(Canvas canvas, Offset c, double rx, double ry, _Face f) {
    final my = c.dy + ry * 0.50;
    final mw = rx * 0.66;
    final openH = state._mouth * ry * 0.42;
    final smile = f.smile * ry * 0.24;

    if (openH > ry * 0.03) {
      // Mouth interior.
      final interior = Path()
        ..moveTo(c.dx - mw / 2, my)
        ..quadraticBezierTo(c.dx, my - smile * 0.5, c.dx + mw / 2, my)
        ..quadraticBezierTo(c.dx, my + openH, c.dx - mw / 2, my)
        ..close();
      canvas.drawPath(interior, Paint()..color = _mouthIn);
      // Top teeth strip.
      final teeth = Path()
        ..moveTo(c.dx - mw * 0.42, my)
        ..quadraticBezierTo(c.dx, my - smile * 0.5, c.dx + mw * 0.42, my)
        ..quadraticBezierTo(c.dx, my + openH * 0.30, c.dx - mw * 0.42, my)
        ..close();
      canvas.drawPath(teeth, Paint()..color = _teeth);
    }
    // Lips — upper (smile) line, lower a touch fuller.
    final lip = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ry * 0.05
      ..strokeCap = StrokeCap.round
      ..color = _lip;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - mw / 2, my)
        ..quadraticBezierTo(c.dx, my + smile, c.dx + mw / 2, my),
      lip,
    );
    if (openH <= ry * 0.03) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - mw * 0.4, my + ry * 0.03)
          ..quadraticBezierTo(c.dx, my + smile + ry * 0.07, c.dx + mw * 0.4, my + ry * 0.03),
        lip..strokeWidth = ry * 0.035,
      );
    }
  }

  void _drawCheeks(Canvas canvas, Offset c, double rx, double ry, _Face f) {
    final blush = math.max(0.0, f.smile) * 0.22;
    if (blush < 0.01) return;
    final p = Paint()
      ..color = const Color(0xFFFF9E8E).withValues(alpha: blush)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, rx * 0.14);
    for (final s in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(c.dx + s * rx * 0.52, c.dy + ry * 0.30),
        rx * 0.17,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) => false; // repaint drives it
}
