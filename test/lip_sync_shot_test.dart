@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/features/speaking/data/audio_playback.dart'
    show syntheticLipLevel;
import 'package:edugain/features/speaking/data/lip_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

/// What the tutor's mouth does, before and after.
///
/// The complaint was that the mouth did not go with the voice. Two curves say
/// why better than any description: the old one is a steady flap that knows
/// nothing about the words, and the new one opens on each word and CLOSES
/// between them — the seam is the whole effect.
///
///     flutter test test/lip_sync_shot_test.dart --tags shot --run-skipped --update-goldens
void main() {
  setUpAll(() async {
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(
          Future.value(File(path).readAsBytesSync().buffer.asByteData()),
        );
      await loader.load();
    }
  });

  testWidgets('mouth openness, old flap vs word-driven', (tester) async {
    tester.view.physicalSize = const Size(760 * 2, 460 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0B1020),
          body: Padding(padding: EdgeInsets.all(20), child: _Chart()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('shots/lip_sync_curves.png'),
    );
  }, skip: !Platform.isWindows);
}

class _Chart extends StatelessWidget {
  const _Chart();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ChartPainter(), child: const SizedBox.expand());
}

class _ChartPainter extends CustomPainter {
  static const _line = 'Hello there, how are you today?';
  static const _rate = 1.15;

  /// The word starts, as the engine would report them.
  static List<int> _boundaries() {
    final out = <int>[0];
    for (var i = 0; i < _line.length; i++) {
      if (_line[i] == ' ' && i + 1 < _line.length) out.add(i + 1);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final boundaries = _boundaries();
    // Lay the words out on a timeline the way the engine would say them.
    final starts = <double>[];
    final spans = <double>[];
    var t = 0.0;
    for (final b in boundaries) {
      final chars = wordLengthAt(_line, b);
      final span = wordDuration(chars, rate: _rate).inMicroseconds / 1e6;
      starts.add(t);
      spans.add(span);
      // A real gap after each word: this is what the mouth has to sit out.
      t += span + 0.09;
    }
    final total = t;

    final rowH = (size.height - 134) / 2;
    _row(
      canvas,
      size,
      44,
      rowH,
      'Before — a clock, not the words',
      (x) => syntheticLipLevel(x * total),
    );
    _row(
      canvas,
      size,
      44 + rowH + 52,
      rowH,
      'After — one arch per word, closed between',
      (x) {
        final now = x * total;
        for (var i = 0; i < starts.length; i++) {
          final p = (now - starts[i]) / spans[i];
          if (p >= 0 && p < 1) {
            return lipLevelInWord(p, wordLengthAt(_line, boundaries[i]));
          }
        }
        return 0.0;
      },
    );

    // The words, under the second row, at the times they are said.
    final left = 130.0;
    final right = size.width - 16;
    final base = 44 + rowH + 52 + rowH + 8;
    for (var i = 0; i < starts.length; i++) {
      final word = _line.substring(
        boundaries[i],
        boundaries[i] + wordLengthAt(_line, boundaries[i]),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: word,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = left + (starts[i] / total) * (right - left);
      // Staggered: at this scale consecutive words overlap on one line.
      tp.paint(canvas, Offset(x, base + (i.isEven ? 0 : 16)));
    }
  }

  void _row(
    Canvas canvas,
    Size size,
    double top,
    double height,
    String label,
    double Function(double x) f,
  ) {
    final left = 130.0;
    final right = size.width - 16;

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 118);
    tp.paint(canvas, Offset(8, top + height / 2 - tp.height / 2));

    canvas.drawLine(
      Offset(left, top + height),
      Offset(right, top + height),
      Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 1,
    );

    final path = Path();
    const steps = 600;
    for (var i = 0; i <= steps; i++) {
      final x = i / steps;
      final px = left + x * (right - left);
      final py = top + height - f(x).clamp(0.0, 1.0) * height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF94A3B8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
