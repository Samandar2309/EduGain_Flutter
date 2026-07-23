import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:edugain/features/speaking/presentation/avatar/photo_hero.dart';
import 'package:edugain/features/speaking/presentation/avatar/vector_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders a ~5s "living" timeline (idle blink → talking with gaze + head
/// motion → settle → blink) as individual frames, for assembling a preview
/// GIF that shows exactly how the eyes/mouth/head behave. Dump-only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('photo hero renders an animation timeline', () async {
    final dumpDir = Platform.environment['VECTOR_DUMP_DIR'];
    if (dumpDir == null) return;
    final images = await PhotoHeroImages.load(rootBundle);
    const size = Size(360, 640);
    final rng = math.Random(7);

    // asymmetric blink envelope (0..1) given progress p through a 0.34s blink
    double blinkEnv(double p) {
      if (p < 0 || p > 1) return 0;
      if (p < 0.28) {
        final q = p / 0.28;
        return q * q;
      } else if (p < 0.40) {
        return 1;
      }
      final q = (p - 0.40) / 0.60;
      return math.pow(1 - q, 2.2).toDouble();
    }

    const dt = 1 / 30.0; // 30 fps
    const total = 150; // 5 s
    // blinks fire at these start times (s)
    final blinkStarts = [0.6, 3.5, 4.6];
    // talking window
    const talkStart = 1.2, talkEnd = 3.2;
    var mouth = 0.0, visW = 1.0, visWT = 1.0;
    var gazeX = 0.0, gazeY = 0.0, gazeXT = 0.0, gazeYT = 0.0, gazeIn = 1.6;

    for (var f = 0; f < total; f++) {
      final t = f * dt;

      // blink
      var blink = 0.0;
      for (final bs in blinkStarts) {
        final p = (t - bs) / 0.34;
        blink = math.max(blink, blinkEnv(p));
      }

      // mouth (voice envelope): band-limited noise while talking
      final talking = t >= talkStart && t <= talkEnd;
      final target = talking
          ? (0.5 +
                  0.5 *
                      math.sin(t * 17) *
                      math.sin(t * 6.3) *
                      (0.6 + 0.4 * math.sin(t * 2.1)))
              .clamp(0.0, 1.0)
          : 0.0;
      mouth += (target - mouth) *
          (1 - math.exp(-dt * (target > mouth ? 40 : 13)));
      if (talking && rng.nextDouble() < 0.25) {
        visWT = 0.66 + rng.nextDouble() * 0.55;
      }
      if (!talking) visWT = 1.0;
      visW += (visWT - visW) * (1 - math.exp(-dt * 17));

      // gaze wander
      gazeIn -= dt;
      if (gazeIn <= 0) {
        gazeIn = 1.2 + rng.nextDouble() * 1.6;
        gazeXT = (rng.nextDouble() * 2 - 1) * (talking ? 0.5 : 0.3);
        gazeYT = (rng.nextDouble() * 2 - 1) * 0.3;
      }
      final gE = 1 - math.exp(-dt * 9);
      gazeX += (gazeXT - gazeX) * gE;
      gazeY += (gazeYT - gazeY) * gE;

      // gentle head life
      final bob = math.sin(t * 1.7) * 0.5 + (talking ? math.sin(t * 9) * 0.3 : 0);
      final sway = math.sin(t * 0.9) * 0.5;
      final yaw = math.sin(t * 0.6) * 0.02 + gazeX * 0.03;
      final pitch = math.sin(t * 1.1) * 0.01;
      final roll = math.sin(t * 0.7) * 0.02;

      final pose = HeroPose(
        blink: blink,
        mouthOpen: mouth,
        mouthWide: visW,
        gazeX: gazeX,
        gazeY: gazeY,
        bob: bob,
        sway: sway,
        yaw: yaw,
        pitch: pitch,
        roll: roll,
        smile: talking ? 0.5 : 0.56,
      );

      final rec = ui.PictureRecorder();
      paintPhotoHero(Canvas(rec), size, pose: pose, images: images);
      final img = await rec
          .endRecording()
          .toImage(size.width.toInt(), size.height.toInt());
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      final name = 'anim_${f.toString().padLeft(3, '0')}';
      File('$dumpDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
