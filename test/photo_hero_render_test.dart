import 'dart:io';
import 'dart:ui' as ui;

import 'package:edugain/features/speaking/presentation/avatar/photo_hero.dart';
import 'package:edugain/features/speaking/presentation/avatar/vector_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the photo hero (official key-visual art + live overlays) in
/// representative poses and (when VECTOR_DUMP_DIR is set) saves PNGs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('photo hero renders base, blink, talk and smile frames', () async {
    final dumpDir = Platform.environment['VECTOR_DUMP_DIR'];
    final images = await PhotoHeroImages.load(rootBundle);

    Future<void> render(String name, HeroPose pose) async {
      const size = Size(360, 640);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      paintPhotoHero(canvas, size, pose: pose, images: images);
      final img = await recorder
          .endRecording()
          .toImage(size.width.toInt(), size.height.toInt());
      expect(img.width, size.width.toInt());
      if (dumpDir != null) {
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$dumpDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      }
    }

    await render('photo_neutral', const HeroPose());
    await render('photo_blink', const HeroPose(blink: 1));
    await render('photo_half_blink', const HeroPose(blink: 0.55));
    await render(
        'photo_talk',
        const HeroPose(mouthOpen: 0.9, mouthWide: 1.1, smile: 0.6));
    await render(
        'photo_talk_soft', const HeroPose(mouthOpen: 0.35, smile: 0.4));
    await render('photo_smile', const HeroPose(smile: 0.95));
    await render(
        'photo_motion',
        const HeroPose(yaw: 0.08, pitch: -0.03, roll: 0.05, bob: 1, sway: -1));

    // motion-feel sequences (the driver's asymmetric blink + syllable talk)
    const blinkSeq = [0.0, 0.16, 0.54, 1.0, 1.0, 0.62, 0.22, 0.03, 0.0];
    for (var i = 0; i < blinkSeq.length; i++) {
      await render('seq_blink_${i.toString().padLeft(2, '0')}',
          HeroPose(blink: blinkSeq[i]));
    }
    const gazeSeq = [
      (0.0, 0.0), (-0.9, 0.1), (-0.5, -0.4), (0.0, -0.6), (0.6, -0.2),
      (0.9, 0.2), (0.4, 0.5), (0.0, 0.0),
    ];
    for (var i = 0; i < gazeSeq.length; i++) {
      await render('seq_gaze_${i.toString().padLeft(2, '0')}',
          HeroPose(gazeX: gazeSeq[i].$1, gazeY: gazeSeq[i].$2));
    }
    const openSeq = [0.05, 0.55, 0.95, 0.65, 0.9, 0.35, 0.75, 0.25, 0.85, 0.1];
    const wideSeq = [1.0, 0.70, 0.72, 1.16, 1.1, 0.85, 0.68, 1.05, 0.95, 1.0];
    for (var i = 0; i < openSeq.length; i++) {
      await render(
          'seq_talk_${i.toString().padLeft(2, '0')}',
          HeroPose(
              mouthOpen: openSeq[i], mouthWide: wideSeq[i], smile: 0.55));
    }
  });
}