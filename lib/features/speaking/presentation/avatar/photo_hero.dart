import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'vector_hero.dart' show HeroPose;

/// The production hero: the official EduGain key-visual render (closed-mouth
/// base + pixel-aligned open-mouth patch) brought to life at 60 FPS. The
/// [HeroPose] contract is unchanged — the same driver that animated the
/// procedural hero now drives the photo hero: whole-head motion (bob / sway /
/// roll / yaw / pitch parallax), procedural eyelids for blinking, and the
/// open-mouth patch cross-faded and syllable-scaled for lip-sync.
class PhotoHeroImages {
  const PhotoHeroImages({
    required this.base,
    required this.mouthOpen,
    required this.sclera,
    required this.iris,
    required this.glint,
  });

  final ui.Image base;
  final ui.Image mouthOpen;
  /// Per eye (left, right): the reconstructed iris-free opening, and the
  /// iris disc cut from the art (masked to the opening, feathered).
  final List<ui.Image> sclera;
  final List<ui.Image> iris;
  /// The catchlights, luminance-keyed: they stay pinned to the LIGHT while
  /// the iris glides beneath them — the anchor of a natural glance.
  final List<ui.Image> glint;

  /// Loaded once per app run; [cached] gives synchronous access afterwards
  /// so the hero paints the art on its very first frame.
  static Future<PhotoHeroImages>? _inFlight;
  static PhotoHeroImages? _ready;
  static PhotoHeroImages? get cached => _ready;

  static Future<PhotoHeroImages> load(AssetBundle bundle) =>
      _inFlight ??= _load(bundle).then((p) => _ready = p);

  static Future<PhotoHeroImages> _load(AssetBundle bundle) async {
    Future<ui.Image> img(String key) async {
      final data = await bundle.load(key);
      final codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    }

    final base = await img('assets/hero/hero_base.png');
    final mouth = await img('assets/hero/hero_mouth_open.png');
    final scl = [
      await img('assets/hero/hero_scl_l.png'),
      await img('assets/hero/hero_scl_r.png'),
    ];
    final iris = [
      await img('assets/hero/hero_iris_l.png'),
      await img('assets/hero/hero_iris_r.png'),
    ];
    final glint = [
      await img('assets/hero/hero_glint_l.png'),
      await img('assets/hero/hero_glint_r.png'),
    ];
    return PhotoHeroImages(
        base: base, mouthOpen: mouth, sclera: scl, iris: iris, glint: glint);
  }
}

/// The stage backdrop alone (the art's night gradient) — painted while the
/// images finish decoding so the procedural hero never flashes through.
void paintPhotoBackdrop(Canvas canvas, Size size) {
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [const Color(0xFF0A0726), const Color(0xFF030116)],
      ),
  );
}

// ── measured geometry of the key visual (in source-image pixels) ──
const _imgW = 723.0;
const _imgH = 1087.0;
// ── MOUTH GEOMETRY ──
// CAVITY only (image px): teeth → cavity → lower lip. The base upper lip is
// NEVER overdrawn, so no upper-lip line ever appears while talking, and the
// mouth stays contained (the jaw drops, the upper lip does not lift). The
// aperture opens between the lips and collapses onto the closed-lip seam.
const _mouthSrc = Rect.fromLTRB(302, 526, 462, 585);
const _mouthCenterX = 381.0;
// The mouth is drawn as THREE anatomical bands, not one squashed rectangle:
// the upper teeth hang off the skull and never move, the lower lip rides the
// jaw at its own true size, and only the cavity between them opens and closes.
// (Uniformly scaling the whole patch — the old way — thinned the teeth into a
// bright hairline and the sub-lip shadow into a dark one: the "lines" seen
// while talking.) Boundaries measured off the asset's luminance profile.
const _mouthTeethBotY = 536.0; // end of the upper-teeth band
const _mouthCavityBotY = 556.0; // end of the cavity, start of the lower lip
// The base's own closed-lip seam is y=533; the asset's alpha ramps 0→opaque
// across exactly that span, so the patch can never paint over the base's upper
// lip (doing so shaved the lip and made it read thinner than the art).
// Each eye's OPENING measured from the art (image px): the two canthi
// (outer/inner corners), the upper-lid peak and the lower-lid bottom.
// The blink never paints outside this almond.
const _eyes = [
  // (outerX, outerY, innerX, innerY, upX, upY, loX, loY)
  // tightened to the real eye opening — the outer corners and lower lid were
  // a touch wider/lower than the art, so the closing lid read slightly big
  (263.0, 398.0, 348.0, 404.0, 301.0, 375.0, 302.0, 423.0), // left
  (502.0, 398.0, 412.0, 404.0, 455.0, 376.0, 456.0, 423.0), // right
];
// The iris discs' centres and the sclera patches' top-left corners
// (image px), matching the extracted assets exactly.
const _irisC = [Offset(302, 400), Offset(455, 401)];
const _irisHalf = 34.0; // the 68px disc asset, centred
const _fillR = 34.0; // home-fill clip radius — MUST match the asset build
const _sclTL = [Offset(251, 371), Offset(408, 372)];
// how far the pupil may roam (image px) — subtle, never theatrical
const _gazeMaxX = 3.6;
const _gazeMaxY = 2.2;
// the catchlight sprites' top-left corners (image px) — FIXED in eye space
const _glintTL = [Offset(284, 380), Offset(436, 379)];
// Clean under-eye skin strips (image px): stretched over the opening they
// become the closed lid — the colour matches the face EXACTLY because it IS
// the face.
const _lidSrc = [
  Rect.fromLTRB(248.0, 436.0, 354.0, 462.0),
  Rect.fromLTRB(408.0, 436.0, 510.0, 462.0),
];

void paintPhotoHero(
  Canvas canvas,
  Size size, {
  required HeroPose pose,
  required PhotoHeroImages images,
  double t = 0,
}) {
  // the image's own deep-blue night backdrop, extended so cover-fit gaps and
  // head motion can never flash a foreign colour
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [const Color(0xFF0A0726), const Color(0xFF030116)],
      ),
  );

  // cover-fit biased toward the top so the full hair stays in frame
  final scale = math.max(size.width / _imgW, size.height / _imgH);
  final dstW = _imgW * scale, dstH = _imgH * scale;
  final dx = (size.width - dstW) / 2;
  final dy = ((size.height - dstH) * 0.30).clamp(size.height - dstH, 0.0);

  Offset ip(double x, double y) => Offset(dx + x * scale, dy + y * scale);

  // whole-head life: breathing bob, sway, roll and yaw/pitch parallax
  canvas.save();
  final cx = size.width / 2, cy = size.height * 0.45;
  canvas.translate(
    cx + (pose.sway * 2.0 + pose.yaw * 26) * scale,
    cy + (pose.bob * 2.4 + pose.pitch * 20) * scale,
  );
  canvas.rotate(pose.roll * 0.55);
  canvas.scale(1 + pose.lean * 0.012);
  canvas.translate(-cx, -cy);

  final imgPaint = Paint()..filterQuality = FilterQuality.medium;
  canvas.drawImageRect(
    images.base,
    Rect.fromLTWH(
        0, 0, images.base.width.toDouble(), images.base.height.toDouble()),
    Rect.fromLTWH(dx, dy, dstW, dstH),
    imgPaint,
  );

  // ── MOUTH — the open-mouth art rides the voice envelope. At rest (speech
  //    ended) NOTHING is drawn: the mouth returns exactly to the base's own
  //    closed lips. As the jaw opens, the aperture grows from zero height —
  //    height AND alpha both start at 0, so the close is perfectly seamless
  //    (no residual line, no ambient ghost over the closed lips).
  final open = pose.mouthOpen.clamp(0.0, 1.0);
  if (open > 0.04) {
    final j = math.pow(open, 0.85).toDouble();
    // fade in over the same low range the height grows, so the tiny opening
    // is both short AND faint as it appears/vanishes — invisible at the seam
    final alpha = ((open - 0.04) / 0.11).clamp(0.0, 1.0);
    // NATURAL-SIZE JAW DROP: the art is drawn at its true panel size; only the
    // aperture between the fixed teeth and the riding lower lip opens, so the
    // mouth is always the mouth the artist drew.
    final vScale = j; // 0 at rest → 1 fully open (jaw hinge)
    // HORIZONTAL ALIGNMENT IS THE WHOLE GAME. The patch carries a margin of
    // SKIN either side of the cavity; at scale 1 those margins sit pixel-exact
    // over the base's own skin and are therefore invisible. Scale the patch
    // horizontally and they slide off register — the feathered rim then lands
    // outside the lip commissures and reads as a dark wire drawn across the
    // cheeks (worst around 15-40% open, where the squashed art is darkest).
    // A dropping jaw does not narrow the lips anyway, so width stays ~1 and
    // only the viseme shapes it, within a range small enough to stay aligned.
    // WIDTH IS NEVER SCALED. The patch is the artist's own open mouth; drawn at
    // exactly 1:1 it lands pixel-for-pixel on the base, so its skin margins are
    // literally the base's skin and its corners land on the base's corners.
    // Any horizontal scaling (even 2%) slides those margins off register, which
    // both widened the mouth past the drawn lips and left the closed-lip seam
    // showing as a dark spur at each corner. A single fixed-shape patch cannot
    // honestly make an "O" versus an "E" anyway — the aperture carries the
    // speech, and alignment is worth more than a few percent of wobble.
    const w = 1.0;
    // A JAW, NOT A CONCERTINA. Teeth stay put at their true size; the lower lip
    // keeps its true size and simply rides down; the dark cavity between them
    // is the only thing that stretches — and being a flat dark field, stretching
    // it is invisible. So the mouth reads naturally at every opening instead of
    // flattening into stripes.
    final cx = ip(_mouthCenterX, 0).dx;
    final halfW = _mouthSrc.width / 2 * scale * w;
    final l = cx - halfW, r = cx + halfW;

    final teethH = (_mouthTeethBotY - _mouthSrc.top) * scale; // fixed
    final cavityH = (_mouthCavityBotY - _mouthTeethBotY) * scale * vScale; // opens
    final lipH = (_mouthSrc.bottom - _mouthCavityBotY) * scale; // fixed, rides

    final yTeethTop = ip(0, _mouthSrc.top).dy;
    final yCavityTop = yTeethTop + teethH;
    final yLipTop = yCavityTop + cavityH;

    // Bands are drawn with a hairline overlap so bilinear sampling can never
    // leave a seam between them.
    const ov = 0.75;
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withValues(alpha: alpha);
    final srcLocal = _mouthSrc.shift(-_mouthSrc.topLeft);
    final sTeethBot = _mouthTeethBotY - _mouthSrc.top;
    final sCavityBot = _mouthCavityBotY - _mouthSrc.top;

    void band(double srcTop, double srcBot, double dstTop, double dstBot) {
      if (dstBot - dstTop <= 0.01) return;
      canvas.drawImageRect(
        images.mouthOpen,
        Rect.fromLTRB(srcLocal.left, srcTop, srcLocal.right, srcBot),
        Rect.fromLTRB(l, dstTop, r, dstBot),
        paint,
      );
    }

    band(0, sTeethBot, yTeethTop, yCavityTop + ov);
    band(sTeethBot, sCavityBot, yCavityTop, yLipTop + ov);
    band(sCavityBot, srcLocal.height, yLipTop, yLipTop + lipH);
  }

  // ── GAZE — the iris glides inside the exact opening: the art's own
  //    sclera shows behind it, so a glance reads exactly like the render
  final gx = pose.gazeX.clamp(-1.0, 1.0) * _gazeMaxX;
  final gy = pose.gazeY.clamp(-1.0, 1.0) * _gazeMaxY;
  if (gx.abs() > 0.15 || gy.abs() > 0.15) {
    for (var i = 0; i < _eyes.length; i++) {
      final (ox, oy, ixx, iyy, upx, upy, lox, loy) = _eyes[i];
      final o = ip(ox, oy), inr = ip(ixx, iyy);
      final up = ip(upx, upy), lo = ip(lox, loy);
      final avgY = (o.dy + inr.dy) / 2;
      double ctrl(double peakY) => 2 * peakY - avgY;
      canvas.save();
      canvas.clipPath(Path()
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(up.dx, ctrl(up.dy), inr.dx, inr.dy)
        ..quadraticBezierTo(lo.dx, ctrl(lo.dy), o.dx, o.dy)
        ..close());
      // MINIMAL DELTA: the art stays untouched everywhere — only the tiny
      // crescent the iris VACATES is refilled (with sclera rebuilt from the
      // art's own rim pixels, so the boundary matches by construction)
      final home = ip(_irisC[i].dx, _irisC[i].dy);
      final scl = images.sclera[i];
      final tl = ip(_sclTL[i].dx, _sclTL[i].dy);
      canvas.save();
      canvas.clipPath(Path()
        ..addOval(Rect.fromCircle(center: home, radius: _fillR * scale)));
      canvas.drawImageRect(
        scl,
        Rect.fromLTWH(0, 0, scl.width.toDouble(), scl.height.toDouble()),
        Rect.fromLTWH(
            tl.dx, tl.dy, scl.width * scale, scl.height * scale),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
      // the iris (catchlight-free) in its glanced position, art-sharp
      final irisImg = images.iris[i];
      final icp = ip(_irisC[i].dx + gx, _irisC[i].dy + gy);
      canvas.drawImageRect(
        irisImg,
        Rect.fromLTWH(
            0, 0, irisImg.width.toDouble(), irisImg.height.toDouble()),
        Rect.fromCenter(
            center: icp,
            width: _irisHalf * 2 * scale,
            height: _irisHalf * 2 * scale),
        Paint()..filterQuality = FilterQuality.high,
      );
      // the catchlights stay pinned to the light source — the eye moves
      // beneath them (the single strongest cue of a living glance)
      final g = images.glint[i];
      final gtl = ip(_glintTL[i].dx, _glintTL[i].dy);
      canvas.drawImageRect(
        g,
        Rect.fromLTWH(0, 0, g.width.toDouble(), g.height.toDouble()),
        Rect.fromLTWH(
            gtl.dx, gtl.dy, g.width * scale, g.height * scale),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }
  }

  // strong glances carry a whisper of lid with them — eyes never dart
  // around fully wide open in a living face
  final glanceLid =
      (pose.gazeX.abs() * 0.055 + math.max(0.0, -pose.gazeY) * 0.045)
          .clamp(0.0, 0.09);
  final blinkRaw = math.max(pose.blink.clamp(0.0, 1.0), glanceLid);
  if (blinkRaw > 0.02) {
    // eased travel — the lid accelerates shut and settles, never linear
    final b = blinkRaw * blinkRaw * (3 - 2 * blinkRaw);
    for (var i = 0; i < _eyes.length; i++) {
      final (ox, oy, ixx, iyy, upx, upy, lox, loy) = _eyes[i];
      final o = ip(ox, oy), inr = ip(ixx, iyy);
      final up = ip(upx, upy), lo = ip(lox, loy);
      final avgY = (o.dy + inr.dy) / 2;
      // a quadratic passes halfway to its control: to run through peak P the
      // control must sit at 2P − avg(endpoints)
      double ctrl(double peakY) => 2 * peakY - avgY;

      // the EXACT opening — nothing outside the eye itself is ever touched
      final opening = Path()
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(up.dx, ctrl(up.dy), inr.dx, inr.dy)
        ..quadraticBezierTo(lo.dx, ctrl(lo.dy), o.dx, o.dy)
        ..close();
      canvas.save();
      canvas.clipPath(opening);

      // the lid fill = the art's own under-eye skin, stretched to the
      // opening's box — identical colour to the face by construction
      final bbox = Rect.fromLTRB(
        math.min(o.dx, inr.dx) - 2 * scale,
        up.dy - 2 * scale,
        math.max(o.dx, inr.dx) + 2 * scale,
        lo.dy + 2 * scale,
      );
      final span = lo.dy - up.dy;
      final marginPeak = up.dy + (lo.dy - span * 0.24 - up.dy) * b;
      // upper lid: fixed top curve → moving margin, corners pinned
      final upperLid = Path()
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(up.dx, ctrl(up.dy), inr.dx, inr.dy)
        ..quadraticBezierTo(up.dx, ctrl(marginPeak), o.dx, o.dy)
        ..close();
      canvas.save();
      canvas.clipPath(upperLid);
      canvas.drawImageRect(images.base, _lidSrc[i], bbox,
          Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
      // lower lid rises ~20% to meet it
      final risePeak = lo.dy - span * 0.20 * b;
      canvas.save();
      canvas.clipPath(Path()
        ..moveTo(o.dx, o.dy)
        ..quadraticBezierTo(lo.dx, ctrl(risePeak), inr.dx, inr.dy)
        ..quadraticBezierTo(lo.dx, ctrl(lo.dy), o.dx, o.dy)
        ..close());
      canvas.drawImageRect(images.base, _lidSrc[i], bbox,
          Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
      // the lash line rides the moving margin, in the art's liner tone
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..quadraticBezierTo(up.dx, ctrl(marginPeak), inr.dx, inr.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0 * scale
          ..color = const Color(0xFF120A05).withValues(alpha: 0.9 * b),
      );
      canvas.restore();
    }
  }

  canvas.restore();
}
