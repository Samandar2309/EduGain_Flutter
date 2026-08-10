import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:edugain/features/speaking/presentation/avatar/photo_hero.dart';
import 'package:edugain/features/speaking/presentation/avatar/vector_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Frame sequence for the mouth GIF: a simulated sentence driven through the
/// EXACT envelope the live avatar uses (`vector_hero_view` — attack 40 /
/// release 13, viseme width kicked on syllable onsets), so what the GIF shows
/// is what the tutor actually does while speaking. Env-gated.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const size = Size(1086, 1630);
  const imgW = 723.0, imgH = 1087.0;
  const win = Rect.fromLTRB(272, 462, 492, 618);
  const outScale = 1.6;
  const fps = 25.0;
  const seconds = 4.4;

  test('photo hero mouth GIF frames', () async {
    final dumpDir = Platform.environment['VECTOR_DUMP_DIR'];
    if (dumpDir == null) return;
    Directory(dumpDir).createSync(recursive: true);
    final images = await PhotoHeroImages.load(rootBundle);

    final scale = size.width / imgW > size.height / imgH
        ? size.width / imgW
        : size.height / imgH;
    final dstH = imgH * scale;
    final dx = (size.width - imgW * scale) / 2;
    final dy = ((size.height - dstH) * 0.30).clamp(size.height - dstH, 0.0);
    final src = Rect.fromLTRB(
      dx + win.left * scale,
      dy + win.top * scale,
      dx + win.right * scale,
      dy + win.bottom * scale,
    );
    final outW = (win.width * outScale).round();
    final outH = (win.height * outScale).round();

    // ── a plausible spoken sentence: syllable pulses, word gaps, one breath ──
    // (start, duration, peak) in seconds — roughly "Hi there! How are you
    // doing today?" at a calm tutor pace.
    const syllables = <(double, double, double)>[
      (0.30, 0.16, 0.85), (0.52, 0.20, 0.70), // Hi there
      (0.95, 0.14, 0.90), (1.13, 0.13, 0.62), (1.30, 0.16, 0.78), // How are you
      (1.62, 0.15, 0.55), (1.82, 0.17, 0.88), // do-ing
      (2.10, 0.14, 0.66), (2.30, 0.20, 0.95), // to-day
      // breath, then a shorter follow-up
      (3.00, 0.15, 0.72), (3.20, 0.13, 0.58), (3.38, 0.18, 0.86),
      (3.66, 0.16, 0.64),
    ];
    double levelAt(double t) {
      var v = 0.0;
      for (final (s, d, p) in syllables) {
        if (t >= s && t <= s + d) {
          // raised cosine — a syllable swells and falls, never a square edge
          final u = (t - s) / d;
          v = math.max(v, p * (0.5 - 0.5 * math.cos(2 * math.pi * u)));
        }
      }
      return v;
    }

    // the live envelope, replicated exactly
    final rng = math.Random(7);
    var mouth = 0.0, prev = 0.0, visW = 1.0, visWT = 1.0;
    const dt = 1 / fps;
    final total = (seconds * fps).round();

    for (var i = 0; i < total; i++) {
      final t = i * dt;
      final target = levelAt(t).clamp(0.0, 1.0);
      mouth += (target - mouth) *
          (1 - math.exp(-dt * (target > mouth ? 40 : 13)));
      final rising = (target - prev) / math.max(dt, 1e-3);
      if (target > 0.2 && rising > 1.2) {
        visWT = 0.66 + rng.nextDouble() * 0.55;
      }
      visW += (visWT - visW) * (1 - math.exp(-dt * 17));
      prev = target;

      final rec = ui.PictureRecorder();
      paintPhotoHero(
        Canvas(rec),
        size,
        pose: HeroPose(mouthOpen: mouth, mouthWide: visW),
        images: images,
      );
      final full = await rec
          .endRecording()
          .toImage(size.width.toInt(), size.height.toInt());

      final rec2 = ui.PictureRecorder();
      Canvas(rec2).drawImageRect(
        full,
        src,
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final cropped = await rec2.endRecording().toImage(outW, outH);
      final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
      final name = 'f${i.toString().padLeft(3, '0')}';
      File('$dumpDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
