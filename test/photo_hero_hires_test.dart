import 'dart:io';
import 'dart:ui' as ui;

import 'package:edugain/features/speaking/presentation/avatar/photo_hero.dart';
import 'package:edugain/features/speaking/presentation/avatar/vector_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// High-resolution gaze frames for edge-integration judgement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('photo hero renders hi-res gaze frames', () async {
    final dumpDir = Platform.environment['VECTOR_DUMP_DIR'];
    if (dumpDir == null) return;
    final images = await PhotoHeroImages.load(rootBundle);
    const size = Size(1086, 1630);
    for (final (name, pose) in [
      ('hires_center', const HeroPose()),
      ('hires_left', const HeroPose(gazeX: -0.9, gazeY: 0.1)),
      ('hires_right', const HeroPose(gazeX: 0.9, gazeY: 0.2)),
      ('hires_talk_o', const HeroPose(mouthOpen: 0.9, mouthWide: 0.72)),
      ('hires_talk_e', const HeroPose(mouthOpen: 0.7, mouthWide: 1.14)),
      ('hires_talk_mid', const HeroPose(mouthOpen: 0.4, mouthWide: 0.95)),
      ('close_0', const HeroPose(mouthOpen: 0.60, mouthWide: 0.9)),
      ('close_1', const HeroPose(mouthOpen: 0.30, mouthWide: 0.9)),
      ('close_2', const HeroPose(mouthOpen: 0.12, mouthWide: 0.9)),
      ('close_3', const HeroPose(mouthOpen: 0.05, mouthWide: 0.9)),
      ('close_4', const HeroPose(mouthOpen: 0.0)),
      ('lo_06', const HeroPose(mouthOpen: 0.06)),
      ('lo_15', const HeroPose(mouthOpen: 0.15)),
      ('lo_30', const HeroPose(mouthOpen: 0.30)),
    ]) {
      final rec = ui.PictureRecorder();
      paintPhotoHero(Canvas(rec), size, pose: pose, images: images);
      final img = await rec
          .endRecording()
          .toImage(size.width.toInt(), size.height.toInt());
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$dumpDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
