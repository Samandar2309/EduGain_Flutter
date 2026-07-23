import 'dart:io';
import 'dart:ui' as ui;

import 'package:edugain/features/speaking/presentation/avatar/vector_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the from-scratch vector character in representative poses/outfits
/// and (when VECTOR_DUMP_DIR is set) saves PNGs for human review.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> render(String name, HeroPose pose, HeroLook look,
      String? dumpDir) async {
    const size = Size(360, 640);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final isSil = name == 'head_silhouette';
    // The silhouette test judges the CONTOUR alone: solid fill on a light
    // ground. Otherwise render over the dark in-app backdrop.
    canvas.drawRect(
      Offset.zero & size,
      isSil
          ? (Paint()..color = const Color(0xFFECECEC))
          : (Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, size.height),
              [const Color(0xFF141B2B), const Color(0xFF0A0F1A)],
            )),
    );
    // Head-anatomy closeup: zoom in on the skull so it can be judged on its own.
    if (name.startsWith('head_')) {
      final cx = size.width * 0.5;
      final cy = size.height * 0.32; // head visual centre (crown..chin)
      canvas.translate(cx, size.height * 0.48);
      canvas.scale(1.9);
      canvas.translate(-cx, -cy);
    }
    if (isSil) {
      canvas.drawPath(
        heroSilhouette(size),
        Paint()..color = const Color(0xFF15151C),
      );
    } else {
      paintHero(canvas, size, pose: pose, look: look);
    }
    final img = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    expect(img.width, size.width.toInt());
    if (dumpDir != null) {
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$dumpDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  }

  test('vector hero renders across poses and outfits', () async {
    final dumpDir = Platform.environment['VECTOR_DUMP_DIR'];
    const indigo = Color(0xFF6366F1);
    const concierge = HeroLook(outfit: HeroOutfit.concierge, accent: indigo);

    await render('neutral', const HeroPose(), concierge, dumpDir);
    await render('smile',
        const HeroPose(smile: 0.9, browRaise: 0.3), concierge, dumpDir);
    // the silhouette test — the CONTOUR alone, filled solid
    await render('head_silhouette', const HeroPose(), concierge, dumpDir);
    // head-anatomy closeups (zoomed) — judge the head on its own
    await render('head_neutral', const HeroPose(smile: 0.18), concierge, dumpDir);
    await render('head_turn',
        const HeroPose(smile: 0.2, yaw: 0.22, gazeX: 0.2), concierge, dumpDir);
    // feature states (Phase 2.2): blink, viseme, warm smile
    await render('head_blink', const HeroPose(blink: 1.0), concierge, dumpDir);
    await render('head_talk',
        const HeroPose(mouthOpen: 0.7, mouthWide: 1.05, smile: 0.25),
        concierge, dumpDir);
    await render('head_smile',
        const HeroPose(smile: 0.65, browRaise: 0.2), concierge, dumpDir);
    await render(
        'talk_wide',
        const HeroPose(mouthOpen: 0.8, mouthWide: 1.12, smile: 0.4),
        concierge,
        dumpDir);
    await render(
        'talk_round',
        const HeroPose(mouthOpen: 0.6, mouthWide: 0.75),
        concierge,
        dumpDir);
    await render('blink', const HeroPose(blink: 1.0), concierge, dumpDir);
    await render(
        'turn',
        const HeroPose(yaw: 0.3, pitch: -0.05, gazeX: 0.4),
        concierge,
        dumpDir);
    await render('surprised',
        const HeroPose(browRaise: 0.9, eyeWiden: 0.8, mouthOpen: 0.4),
        concierge, dumpDir);
    // outfits
    await render('outfit_doctor', const HeroPose(smile: 0.4),
        const HeroLook(outfit: HeroOutfit.doctor, accent: Color(0xFF22D3EE)),
        dumpDir);
    await render('outfit_barista', const HeroPose(smile: 0.5),
        const HeroLook(outfit: HeroOutfit.barista, accent: Color(0xFFF59E0B)),
        dumpDir);
  });
}
