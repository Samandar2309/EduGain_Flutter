import 'dart:io';
import 'dart:ui' as ui;

import 'package:edugain/features/speaking/presentation/avatar/photo_hero.dart';
import 'package:edugain/features/speaking/presentation/avatar/vector_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Zoomed mouth crops — the only way to judge lip-sync art by eye. Renders the
/// hero at production size, then magnifies the mouth region so seams, lip lines
/// and aperture size are actually visible. Env-gated (`VECTOR_DUMP_DIR`) so it
/// is inert in CI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Production render size, and the mouth window in SOURCE-IMAGE pixels.
  const size = Size(1086, 1630);
  const imgW = 723.0, imgH = 1087.0;
  const win = Rect.fromLTRB(276, 470, 488, 614); // generous margin around lips
  const zoom = 5.0;

  test('photo hero mouth QA crops', () async {
    final dumpDir = Platform.environment['VECTOR_DUMP_DIR'];
    if (dumpDir == null) return;
    Directory(dumpDir).createSync(recursive: true);
    final images = await PhotoHeroImages.load(rootBundle);

    // Mirror paintPhotoHero's cover-fit so the crop lands on the mouth.
    final scale =
        size.width / imgW > size.height / imgH ? size.width / imgW : size.height / imgH;
    final dstH = imgH * scale;
    final dx = (size.width - imgW * scale) / 2;
    final dy = ((size.height - dstH) * 0.30).clamp(size.height - dstH, 0.0);
    final src = Rect.fromLTRB(
      dx + win.left * scale,
      dy + win.top * scale,
      dx + win.right * scale,
      dy + win.bottom * scale,
    );
    final outW = (win.width * zoom).round();
    final outH = (win.height * zoom).round();

    Future<ui.Image> frame(HeroPose pose) async {
      final rec = ui.PictureRecorder();
      paintPhotoHero(Canvas(rec), size, pose: pose, images: images);
      return rec.endRecording().toImage(size.width.toInt(), size.height.toInt());
    }

    Future<void> crop(String name, HeroPose pose) async {
      final full = await frame(pose);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawImageRect(
        full,
        src,
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final img = await rec.endRecording().toImage(outW, outH);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$dumpDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }

    // 1 ─ the closing ramp: does it converge onto the base lips with no line?
    for (final (n, o) in [
      ('ramp_00_closed', 0.0),
      ('ramp_01', 0.06),
      ('ramp_02', 0.15),
      ('ramp_03', 0.30),
      ('ramp_04', 0.50),
      ('ramp_05', 0.75),
      ('ramp_06_open', 1.0),
    ]) {
      await crop(n, HeroPose(mouthOpen: o, mouthWide: 0.9));
    }

    // 1b ─ a filmstrip of the same ramp: the only way to judge whether the
    //      motion reads as a jaw opening rather than a shape being squashed.
    {
      const steps = [0.0, 0.08, 0.16, 0.26, 0.38, 0.52, 0.70, 1.0];
      const tileW = 300.0;
      final tileH = tileW * win.height / win.width;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(
        Rect.fromLTWH(0, 0, tileW * steps.length, tileH),
        Paint()..color = const Color(0xFF12102A),
      );
      for (var i = 0; i < steps.length; i++) {
        final full = await frame(HeroPose(mouthOpen: steps[i], mouthWide: 0.92));
        c.drawImageRect(
          full,
          src,
          Rect.fromLTWH(i * tileW, 0, tileW, tileH),
          Paint()..filterQuality = FilterQuality.high,
        );
      }
      final img = await rec
          .endRecording()
          .toImage((tileW * steps.length).round(), tileH.round());
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$dumpDir/_filmstrip.png').writeAsBytesSync(png!.buffer.asUint8List());
    }

    // 2 ─ the two extreme visemes at full voice.
    await crop('viseme_O', const HeroPose(mouthOpen: 0.95, mouthWide: 0.70));
    await crop('viseme_E', const HeroPose(mouthOpen: 0.75, mouthWide: 1.18));

    // 3 ─ reference: the hero's OWN open mouth, straight from the panel at its
    //     natural size/position — the target the animated mouth must match.
    {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
          Paint()..color = const Color(0xFF0A0726));
      // base panel, then the open-mouth asset pinned at its own coordinates
      c.save();
      c.scale(zoom / 1.0);
      c.translate(-win.left, -win.top);
      c.drawImageRect(
        images.base,
        Rect.fromLTWH(
            0, 0, images.base.width.toDouble(), images.base.height.toDouble()),
        const Rect.fromLTWH(0, 0, imgW, imgH),
        Paint()..filterQuality = FilterQuality.high,
      );
      c.drawImageRect(
        images.mouthOpen,
        Rect.fromLTWH(0, 0, images.mouthOpen.width.toDouble(),
            images.mouthOpen.height.toDouble()),
        // the asset's own panel rect — see _mouthSrc in photo_hero.dart
        const Rect.fromLTRB(302, 526, 462, 585),
        Paint()..filterQuality = FilterQuality.high,
      );
      c.restore();
      final img = await rec.endRecording().toImage(outW, outH);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$dumpDir/ref_panel_open.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
