import 'package:flutter/material.dart';

/// Flags, drawn rather than typed.
///
/// The obvious way to put a flag in a list is the emoji, and it is the one way
/// that cannot be relied on: Windows ships no flag glyphs at all, so 🇬🇧 renders
/// as the letters "GB" there — and this app is built and reviewed on Windows,
/// which means the picture used to judge a screen would not be the picture a
/// learner sees. Browsers disagree about them too. Geometry renders identically
/// everywhere and stays sharp at any size.
///
/// Adding a language means adding a painter here and an entry to the catalogue
/// on the screen. Deliberately small work — the list is meant to grow.
class FlagBadge extends StatelessWidget {
  const FlagBadge({super.key, required this.painter, this.width = 34});

  final CustomPainter painter;
  final double width;

  @override
  Widget build(BuildContext context) {
    // 3:2, the shape most flags are drawn at and the one a row of them reads
    // best in — a circle crops the crosses of some and the fields of others.
    final height = width * 2 / 3;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: painter),
            // A hairline inside the edge. Without it a pale flag on a white
            // card has no boundary at all, and this row is mostly white card.
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Union Flag: a 2:1 field, St George's cross a fifth of the height with
/// white fimbriation, and the two saltires counterchanged.
class UnionJackPainter extends CustomPainter {
  const UnionJackPainter();

  static const _blue = Color(0xFF012169);
  static const _red = Color(0xFFC8102E);
  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = _blue)
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, w, h));

    // St Andrew's white saltire, then St Patrick's red over it.
    final white = Paint()
      ..color = _white
      ..strokeWidth = h / 5
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(Offset.zero, Offset(w, h), white)
      ..drawLine(Offset(w, 0), Offset(0, h), white);

    final red = Paint()
      ..color = _red
      ..strokeWidth = h / 15
      ..style = PaintingStyle.stroke;
    // Offset to one side of each diagonal rather than centred on it — that
    // offset is what "counterchanged" means, and dropping it is the usual way
    // a hand-drawn Union Flag comes out looking almost right.
    final o = h / 15;
    canvas
      ..drawLine(Offset(0, -o), Offset(w / 2, h / 2 - o), red)
      ..drawLine(Offset(w / 2, h / 2 + o), Offset(w, h + o), red)
      ..drawLine(Offset(w, -o), Offset(w / 2, h / 2 - o), red)
      ..drawLine(Offset(w / 2, h / 2 + o), Offset(0, h + o), red);

    // St George's cross, over everything.
    final cross = h / 5;
    final fim = cross * 5 / 3;
    final centre = Offset(w / 2, h / 2);
    canvas
      ..drawRect(
        Rect.fromCenter(center: centre, width: w, height: fim),
        Paint()..color = _white,
      )
      ..drawRect(
        Rect.fromCenter(center: centre, width: fim, height: h),
        Paint()..color = _white,
      )
      ..drawRect(
        Rect.fromCenter(center: centre, width: w, height: cross),
        Paint()..color = _red,
      )
      ..drawRect(
        Rect.fromCenter(center: centre, width: cross, height: h),
        Paint()..color = _red,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(UnionJackPainter oldDelegate) => false;
}
