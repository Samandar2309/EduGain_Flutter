import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// EduGain Hero — Generation 2, built FOUNDATION-FIRST.
///
/// STAGE 1 — ANATOMICAL FOUNDATION (current). Only the head VOLUME and the neck.
/// No eyes, nose, mouth, ears, hair or wardrobe. The head is NOT an oval with a
/// gradient — it is constructed from the planes of the head (Loomis / Asaro):
/// a dominant cranium, receding temporal planes, a frontal plane with a brow
/// ridge, zygomatic (cheekbone) planes as the widest point of the face, a
/// soft-square mandible, a soft-square chin plane, and a neck that grows from
/// beneath the jaw into the trapezius with sternocleidomastoid ridges. Each
/// plane is shaded by its orientation to a single warm key (upper-left) so the
/// light reads the form. A faint construction overlay validates the proportions
/// by measurement. Reference: a warm, professional young-adult male teacher.
///
/// 100% procedural Flutter Canvas. [HeroPose] is preserved so the live rig is
/// untouched while the hero is rebuilt.

/// Proportion overlay (Stage-1 validation). Off now that features are layered.
const bool _showGuides = false;

/// Phase gate: while Phase 2.1 (facial planes) is under review the features
/// (brows/eyes/nose/mouth) are hidden so the PLANES are judged alone. The
/// feature code stays intact — flipped back on for Phase 2.2. Ears stay
/// rendered (locked, unchanged).
const bool _showFeatures = false;

/// Phase 2.2B — the eyes are built and reviewed on their own (nose/mouth
/// still hidden until their phases).
const bool _showEyes = true;

/// Phase 2.2C — the eyebrows.
const bool _showBrows = true;

/// Phase 2.1A — the anatomical construction landmarks (faint, 15–20% opacity):
/// centre axis, eye/brow/nose/mouth/chin lines, orbital borders, cheekbone
/// guides, nasal root and philtrum guide. A sculptor's construction sheet,
/// not artwork. Off once construction is approved.
const bool _showLandmarks = true;

/// Phase 2.1C gate: the volume-polish stage is judged with NO features at all —
/// ears included ("Quloq YO'Q"). Ear code stays intact for Phase 2.2.
const bool _showEars = false;

enum HeroOutfit { concierge, barista, doctor, business, casual }

@immutable
class HeroLook {
  const HeroLook({required this.outfit, required this.accent});

  final HeroOutfit outfit;
  final Color accent;

  // ── skin: warm, MATTE, five values + a cool shadow bias on the fill side ──
  static const skinBase = Color(0xFFE3AC80);
  static const skinLit = Color(0xFFF0C79A); // key plane
  static const skinMid = Color(0xFFD19870);
  static const skinShadow = Color(0xFFB27E5C);
  static const skinDeep = Color(0xFF8C5F46);
  static const skinCool = Color(0xFF9E7C7A); // mauve ambient in deep shadow
  static const bounce = Color(0xFFCE7E62); // warm subsurface under the jaw

  // ── hair (Phase 2.7): thick natural dark-brown mass, warm not black ──
  static const hairBase = Color(0xFF261A13);
  static const hairLit = Color(0xFF5C4630); // warm curl-top response
  static const hairDeep = Color(0xFF120C08); // seams + back volume

  // ── facial features (Phase 2.2) ──
  static const sclera = Color(0xFFF1EBDF); // warm grey-white, never pure white
  static const iris = Color(0xFF74492A); // warm glossy brown (brand reference)
  static const irisHi = Color(0xFF9A6A3C);
  static const irisDeep = Color(0xFF39220F);
  static const pupil = Color(0xFF171008);
  static const lash = Color(0xFF1F1410); // bold dark lash line (reference)
  static const brow = Color(0xFF261911); // near-black, matches the curls
  static const lipUp = Color(0xFFBE7D66); // upper lip — darker (faces down)
  static const lipLow = Color(0xFFD69579); // lower lip — fuller, catches light
  static const mouthIn = Color(0xFF56302D);
  static const teeth = Color(0xFFF1EADB); // warm ivory, never Hollywood white

  // ── stage backdrop + construction guides ──
  static const bgTop = Color(0xFF221C34);
  static const bgBottom = Color(0xFF14101F);
  static const guide = Color(0xFF6FE0E0);
}

@immutable
class HeroPose {
  const HeroPose({
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
    this.bob = 0,
    this.sway = 0,
    this.blink = 0,
    this.gazeX = 0,
    this.gazeY = 0,
    this.browRaise = 0,
    this.browFurrow = 0,
    this.eyeWiden = 0,
    this.smile = 0.2,
    this.mouthOpen = 0,
    this.mouthWide = 1.0,
    this.lean = 0,
    this.pupilDilate = 0,
  });

  final double yaw;
  final double pitch;
  final double roll;
  final double bob;
  final double sway;
  final double blink;
  final double gazeX;
  final double gazeY;
  final double browRaise;
  final double browFurrow;
  final double eyeWiden;
  final double smile;
  final double mouthOpen;
  final double mouthWide;
  final double lean;
  final double pupilDilate;
}

// crown 0.0 → chin 1.0 — Loomis-anchored landmarks. The eye line sits at
// ~50% of the head's height (52.5% — the "taxminan 50%" youth bias); every
// later feature seats onto these exact lines.
const double _fHairline = 0.30;
const double _fBrow = 0.487; // brow-ridge centre, just above the eye line
const double _fEye = 0.525; // ≈ half the head height
const double _fNose = 0.75; // nose base
const double _fMouth = 0.835; // lip centre
const double _fChin = 1.0;

void paintHero(
  Canvas canvas,
  Size size, {
  required HeroPose pose,
  required HeroLook look,
  double t = 0,
}) {
  final w = size.width;
  final h = size.height;
  final hw = w * 0.205; // max half-width (at the parietal / cranium)
  final hh = hw * 1.305; // half-height — head ~1.3× as tall as wide (+2%)
  final headX = w * 0.5 + pose.sway * w * 0.006 + math.sin(t * 0.5) * w * 0.002;
  final headY = h * 0.40 + pose.bob * h * 0.005;
  final headC = Offset(headX, headY);

  _drawBackground(canvas, size);
  _drawNeck(canvas, headC, hw, hh);
  // Phase 2.7A — the back hair mass lives BEHIND the skull (painted first,
  // the head then overlaps it: the junction is seamless by construction).
  _drawHairBack(canvas, headC, hw, hh);
  _drawHeadForm(canvas, headC, hw, hh);
  _drawFacialStructure(canvas, headC, hw, hh);
  // Phase 2.2A — the anatomical eye sockets (no eyes yet), part of the
  // locked foundation from here on.
  _drawEyeSockets(canvas, headC, hw, hh);
  // Phase 2.3A — the nasal foundation (the pyramid blockout; no tip/nostrils).
  _drawNoseFoundation(canvas, headC, hw, hh);
  // Phase 2.2G — midface integration: forehead↔brow↔glabella↔nasion↔cheek
  // transitions fused into one continuous skull.
  _drawMidfaceIntegration(canvas, headC, hw, hh);
  // Phase 2.3B — primary nose anatomy: tip, alar cartilage, columella,
  // nostril openings — sculpted into the reserved lower-nose space.
  _drawNosePrimary(canvas, headC, hw, hh);
  // Phase 2.4A — the oral foundation: the mouth's supporting anatomy
  // (oral cylinder, maxilla/mandible support, philtrum channel, neutral
  // resting line) — NO lips yet.
  _drawOralFoundation(canvas, headC, hw, hh);
  // Phase 2.4B — primary lip anatomy: the orbicularis-oris masses on the
  // oral cylinder (no expression, no teeth, no cosmetics).
  _drawLipsPrimary(canvas, headC, hw, hh);
  // Phase 2.5A — the facial soft-tissue layer: living tissue over the locked
  // skull (fat-pad influence only — nothing exposed, nothing textured).
  _drawSoftTissue(canvas, headC, hw, hh);
  // Phase 2.6A — the ear foundation: the primary shell volume growing out of
  // the temporal region (no internal anatomy yet).
  _drawEarFoundation(canvas, headC, hw, hh);
  // The 2.2-era detailed ears remain gated off — superseded by the 2.6 ear
  // system being built foundation-first.
  if (_showEars) _drawEars(canvas, headC, hw, hh);
  if (_showEyes) _drawEyes(canvas, headC, hw, hh, pose);
  if (_showBrows) _drawBrows(canvas, headC, hw, hh, pose);
  // Phase 2.7A — hairline + primary hair volume (mass only; curls later).
  _drawHairFoundation(canvas, headC, hw, hh);
  if (_showFeatures) {
    _drawNose(canvas, headC, hw, hh, pose);
    _drawMouth(canvas, headC, hw, hh, pose);
  }
  if (_showLandmarks) _drawLandmarks(canvas, headC, hw, hh);
  if (_showGuides) _drawGuides(canvas, headC, hw, hh);
}

double _y(Offset c, double hh, double f) => c.dy + (2 * f - 1) * hh;

// ── PHASE 2.1A — FACIAL LANDMARKS (construction pass) ───────────────────────
// A sculptor's construction sheet over the locked head: faint lines only —
// no volume, no gradients, no features. Everything the next phases will seat
// into is measured and marked here.
void _drawLandmarks(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  // Blueprint precision: hairline strokes (≈1 px), 15–20% opacity, antialiased.
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = hw * 0.0095
    ..color = HeroLook.guide.withValues(alpha: 0.20);
  final soft = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = hw * 0.0085
    ..color = HeroLook.guide.withValues(alpha: 0.17);

  final left = c.dx - hw * 1.12;
  final right = c.dx + hw * 1.12;

  // 1. vertical centre axis — forehead centre, glabella, nasal root, philtrum
  //    and chin centre all live on this one line
  canvas.drawLine(Offset(c.dx, y(-0.04)), Offset(c.dx, y(1.07)), line);

  // 2–6. the horizontal construction lines (Loomis)
  canvas.drawLine(Offset(left, y(_fEye)), Offset(right, y(_fEye)), line);
  canvas.drawLine(Offset(left, y(_fBrow)), Offset(right, y(_fBrow)), soft);
  canvas.drawLine(Offset(left, y(_fNose)), Offset(right, y(_fNose)), line);
  canvas.drawLine(Offset(left, y(_fMouth)), Offset(right, y(_fMouth)), soft);
  canvas.drawLine(Offset(left, y(_fChin)), Offset(right, y(_fChin)), soft);

  // 7. ORBITAL BORDERS — anatomical socket rims, NOT ovals: the upper
  //    (supraorbital) rim is the heavier, flatter arc; the lower (infraorbital)
  //    rim is softer and gentler; inner corner (lacrimal) sits a touch lower,
  //    outer corner a touch high.
  for (final s in [-1.0, 1.0]) {
    final ex = c.dx + s * hw * 0.36;
    final ey = y(_fEye);
    final w2 = hw * 0.235; // socket half-width
    final inC = Offset(ex - s * w2, ey + hh * 0.012); // lacrimal, lower
    final outC = Offset(ex + s * w2, ey - hh * 0.014); // outer, higher
    // upper rim — heavier, flatter (the brow-bone edge)
    canvas.drawPath(
      Path()
        ..moveTo(inC.dx, inC.dy)
        ..cubicTo(ex - s * w2 * 0.5, ey - hh * 0.062, ex + s * w2 * 0.55,
            ey - hh * 0.058, outC.dx, outC.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.0120
        ..color = HeroLook.guide.withValues(alpha: 0.20),
    );
    // lower rim — softer, shallower
    canvas.drawPath(
      Path()
        ..moveTo(inC.dx, inC.dy)
        ..cubicTo(ex - s * w2 * 0.45, ey + hh * 0.048, ex + s * w2 * 0.5,
            ey + hh * 0.040, outC.dx, outC.dy),
      soft,
    );
  }

  // 8. CHEEKBONE GUIDES — the zygomatic-arch flow: born beside each orbit,
  //    sweeping down-and-in across the midface.
  for (final s in [-1.0, 1.0]) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + s * hw * 0.80, y(_fEye + 0.045))
        ..quadraticBezierTo(c.dx + s * hw * 0.62, y(0.665),
            c.dx + s * hw * 0.33, y(0.72)),
      soft,
    );
  }

  // 9. NASAL ROOT — where the nose will begin (a small tick on the axis)
  canvas.drawOval(
    Rect.fromCenter(center: Offset(c.dx, y(0.548)), width: hw * 0.12,
        height: hh * 0.032),
    soft,
  );

  // 10. PHILTRUM GUIDE — the faint centre segment, nose base → lip centre
  canvas.drawLine(Offset(c.dx, y(_fNose + 0.006)), Offset(c.dx, y(_fMouth - 0.006)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.0100
        ..color = HeroLook.guide.withValues(alpha: 0.18));
}

void _drawBackground(Canvas canvas, Size size) {
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [HeroLook.bgTop, HeroLook.bgBottom],
      ),
  );
}

// ── the head silhouette. Anatomical landmarks in the CONTOUR itself so a plain
//    black fill reads as a young man's head, never an oval:
//    crown → parietal (widest cranium) → TEMPORAL recede (in) → ZYGOMATIC
//    cheekbone (out, widest face) → near-vertical RAMUS → soft GONIAL corner →
//    jaw body → soft-square CHIN. A hair of natural asymmetry (fuller left jaw).
Path _headPath(Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  double x(double fw) => c.dx + hw * fw;
  // Phase 1.1B micro-anatomy polish. Anchors follow the bone masses; adjacent
  // control points keep tangent continuity so no segment reads as a primitive
  // arc. Height/width/global proportions LOCKED from 1.1A.
  return Path()
    ..moveTo(c.dx, y(0.0)) // crown — highest at centre, top NOT a half-circle
    // crown → FRONTAL-TEMPLE: a long, flattish frontal-bone sweep (the
    // forehead reads as its own mass; upper radius reduced ~3%)
    ..cubicTo(x(0.34), y(0.006), x(0.64), y(0.052), x(0.78), y(0.115))
    // frontal → PARIETAL (widest point of the head — width locked); the
    // transition tangents eased so no boxy upper corner remains
    ..cubicTo(x(0.868), y(0.166), x(0.945), y(0.235), x(0.95), y(0.31))
    // parietal → TEMPORAL HOLLOW (deepest just above the eye line)
    ..cubicTo(x(0.952), y(0.385), x(0.90), y(0.455), x(0.862), y(0.52))
    // temporal → ZYGOMATIC — tangents aligned so the widest-point turn is a
    // smooth extremum, not a corner
    ..cubicTo(x(0.850), y(0.568), x(0.886), y(0.612), x(0.895), y(0.655))
    // zygomatic → RAMUS: a near-straight vertical descent (mandible felt)
    ..cubicTo(x(0.889), y(0.720), x(0.82), y(0.80), x(0.755), y(0.845))
    // soft GONIAL turn (~126°) → jaw body in light flat-ish segments
    ..cubicTo(x(0.69), y(0.888), x(0.46), y(0.958), x(0.273), y(0.998))
    // CHIN — a slightly narrower, longer, FLAT platform
    ..cubicTo(x(0.175), y(1.016), x(-0.175), y(1.016), x(-0.273), y(0.998))
    // left side — ~2% organic rhythm differences, never a perfect mirror
    ..cubicTo(x(-0.455), y(0.958), x(-0.685), y(0.889), x(-0.745), y(0.848))
    ..cubicTo(x(-0.825), y(0.795), x(-0.885), y(0.715), x(-0.905), y(0.655))
    ..cubicTo(x(-0.91), y(0.615), x(-0.858), y(0.566), x(-0.872), y(0.52))
    ..cubicTo(x(-0.897), y(0.455), x(-0.952), y(0.388), x(-0.955), y(0.31))
    ..cubicTo(x(-0.95), y(0.232), x(-0.876), y(0.164), x(-0.80), y(0.120))
    ..cubicTo(x(-0.655), y(0.055), x(-0.35), y(0.005), c.dx, y(0.0))
    ..close();
}

/// The PURE SKULL silhouette for [size] — the "silhouette test" fills this
/// solid and judges the head CONTOUR alone (no neck, no features, no shading).
Path heroSilhouette(Size size) {
  final w = size.width;
  final hw = w * 0.205;
  final hh = hw * 1.32;
  final c = Offset(w * 0.5, size.height * 0.40);
  return Path.combine(
      PathOperation.union, _headPath(c, hw, hh), _hairMassPath(c, hw, hh));
}

void _drawHeadForm(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  final path = _headPath(c, hw, hh);
  final rect = Rect.fromCenter(center: c, width: hw * 2.4, height: hh * 2.6);

  canvas.save();
  canvas.clipPath(path);

  // ── 0. base + broad ambient (crown rolls back → cooler/darker; brightest at
  //    the forehead-cheek band; the jaw sits a touch lower/darker) ──
  canvas.drawRect(rect, Paint()..color = HeroLook.skinBase);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(c.dx, y(-0.05)),
        Offset(c.dx, y(1.05)),
        [
          HeroLook.skinShadow.withValues(alpha: 0.18), // crown rolls away
          HeroLook.skinBase.withValues(alpha: 0.0),
          HeroLook.skinBase.withValues(alpha: 0.0),
          HeroLook.skinShadow.withValues(alpha: 0.22), // under the jaw
        ],
        [0.0, 0.28, 0.70, 1.0],
      ),
  );

  // ── 1. KEY LIGHT FAMILY — the whole upper-left front catches the warm key ──
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(c.dx - hw * 0.46, y(0.38)),
        hw * 1.9,
        [HeroLook.skinLit, HeroLook.skinLit.withValues(alpha: 0.0)],
        [0.0, 1.0],
      ),
  );

  // ── 2. FILL SHADOW — kept RESTRAINED: a simple L→R gradient must never be
  //    the form's main read (that flattens the face into an egg). The volume
  //    is carried by the PLANE passes below + in _drawFacialStructure; this
  //    only settles the far edge of the fill side. ──
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(c.dx + hw * 0.30, c.dy),
        Offset(c.dx + hw * 1.0, c.dy),
        [
          HeroLook.skinShadow.withValues(alpha: 0.0),
          HeroLook.skinShadow.withValues(alpha: 0.34),
          HeroLook.skinCool.withValues(alpha: 0.42),
        ],
        [0.0, 0.72, 1.0],
      ),
  );
  // a matching soft edge shadow on the left, so the left side plane also turns
  _blob(canvas, Offset(c.dx - hw * 0.92, y(0.55)), hw * 0.24, hh * 0.5,
      HeroLook.skinShadow.withValues(alpha: 0.28), hw * 0.18);

  // ── 3. TEMPORAL RECEDE — the temples step inward (right deeper than left) ──
  for (final s in [-1.0, 1.0]) {
    _blob(canvas, Offset(c.dx + s * hw * 0.66, y(_fBrow)), hw * 0.26, hh * 0.20,
        HeroLook.skinShadow.withValues(alpha: s < 0 ? 0.18 : 0.30), hw * 0.16);
  }

  // ── 4. FRONTAL PLANE + BROW RIDGE. The centre of the face faces front and
  //    catches light; the brow ridge is a lit shelf with the eye-socket recess
  //    shadowed just beneath it (where the eyes will sit). ──
  _blob(canvas, Offset(c.dx + hw * 0.02, y(0.385)), hw * 0.64, hh * 0.17,
      HeroLook.skinLit.withValues(alpha: 0.34), hw * 0.30); // frontal forehead
  _blob(canvas, Offset(c.dx - hw * 0.06, y(_fBrow) - hh * 0.01), hw * 0.62,
      hh * 0.045, HeroLook.skinLit.withValues(alpha: 0.34), hw * 0.10); // brow ridge shelf
  _blob(canvas, Offset(c.dx, y(_fBrow) + hh * 0.055), hw * 0.66, hh * 0.06,
      HeroLook.skinShadow.withValues(alpha: 0.24), hw * 0.10); // supraorbital recess
  // central vertical form (glabella → nose bridge line) catching front light
  _blob(canvas, Offset(c.dx - hw * 0.02, y(0.62)), hw * 0.11, hh * 0.14,
      HeroLook.skinLit.withValues(alpha: 0.18), hw * 0.09);

  // ── 5. ZYGOMATIC (cheekbone) planes — the widest point; a lit ridge on top
  //    of the bone, a soft hollow in the plane below (buccal) ──
  for (final s in [-1.0, 1.0]) {
    _blob(canvas, Offset(c.dx + s * hw * 0.54, y(0.66)), hw * 0.30, hh * 0.13,
        HeroLook.skinLit.withValues(alpha: s < 0 ? 0.30 : 0.12), hw * 0.17);
    _blob(canvas, Offset(c.dx + s * hw * 0.46, y(0.79)), hw * 0.28, hh * 0.15,
        HeroLook.skinShadow.withValues(alpha: s < 0 ? 0.14 : 0.22), hw * 0.17);
  }

  // ── 6. MANDIBLE — the jaw side plane (ramus) turns away; the jaw line is a
  //    soft plane change; the underside is the deepest ambient occlusion ──
  for (final s in [-1.0, 1.0]) {
    _blob(canvas, Offset(c.dx + s * hw * 0.72, y(0.80)), hw * 0.20, hh * 0.14,
        HeroLook.skinShadow.withValues(alpha: s < 0 ? 0.16 : 0.26), hw * 0.13);
  }
  _blob(canvas, Offset(c.dx, y(0.90)), hw * 0.72, hh * 0.10,
      HeroLook.skinShadow.withValues(alpha: 0.24), hh * 0.07); // jaw underside AO

  // ── 7. CHIN — a small flat frontal plane (lit) with the mento-labial crease
  //    shadow above it, and warm subsurface bounce beneath the jaw ──
  _blob(canvas, Offset(c.dx - hw * 0.02, y(0.92)), hw * 0.17, hh * 0.055,
      HeroLook.skinLit.withValues(alpha: 0.30), hw * 0.09);
  _blob(canvas, Offset(c.dx, y(0.86)), hw * 0.18, hh * 0.035,
      HeroLook.skinShadow.withValues(alpha: 0.18), hw * 0.08);
  _blob(canvas, Offset(c.dx - hw * 0.28, y(0.90)), hw * 0.24, hh * 0.10,
      HeroLook.bounce.withValues(alpha: 0.16), hw * 0.16); // warm bounce (key side)

  // ── 8. CRANIUM — the top rolls back (darker toward the crown) with a cool
  //    rim of light catching the upper-left edge ──
  _blob(canvas, Offset(c.dx + hw * 0.05, y(0.06)), hw * 0.9, hh * 0.16,
      HeroLook.skinShadow.withValues(alpha: 0.13), hw * 0.24);

  // ── 9. SKIN TEMPERATURE — matte, never one colour: warm cheeks/nose, cooler
  //    temples and jaw. Very low alpha. ──
  _blob(canvas, Offset(c.dx, y(0.70)), hw * 0.20, hh * 0.10,
      const Color(0x1FC96A54), hw * 0.14); // nose-area warmth
  for (final s in [-1.0, 1.0]) {
    _blob(canvas, Offset(c.dx + s * hw * 0.50, y(0.72)), hw * 0.22, hh * 0.12,
        const Color(0x22CE7A62), hw * 0.16); // cheek warmth
    _blob(canvas, Offset(c.dx + s * hw * 0.70, y(0.46)), hw * 0.18, hh * 0.14,
        const Color(0x148294B4), hw * 0.14); // cool temples
  }

  canvas.restore();

  // ── cool ambient rim on the shadow side — separates the mass from the ground
  canvas.drawPath(
    Path()
      ..moveTo(c.dx + hw * 0.97, y(0.42))
      ..cubicTo(c.dx + hw * 0.95, y(0.66), c.dx + hw * 0.70, y(0.86),
          c.dx + hw * 0.28, y(0.98)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hw * 0.04
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x3A93A6C8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.045),
  );
}

// the neck mass: starts wide enough under the jaw (so no gap opens as the jaw
// narrows to the chin), then flares into the trapezius at the base.
Path _neckPath(Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  final topY = y(0.84);
  final bot = c.dy + hh * 2.05;
  return Path()
    ..moveTo(c.dx - hw * 0.64, topY)
    ..cubicTo(c.dx - hw * 0.64, y(1.05), c.dx - hw * 0.82, y(1.24),
        c.dx - hw * 1.42, bot)
    ..lineTo(c.dx + hw * 1.42, bot)
    ..cubicTo(c.dx + hw * 0.82, y(1.24), c.dx + hw * 0.64, y(1.05),
        c.dx + hw * 0.64, topY)
    ..close();
}

// ── the neck: grows from beneath the jaw into the trapezius, with SCM ridges.
//    Drawn BEFORE the head so the jaw overhangs and casts onto it (mass). ─────
void _drawNeck(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  final topY = y(0.86);
  final neck = _neckPath(c, hw, hh);
  canvas.drawPath(neck, Paint()..color = HeroLook.skinMid);

  canvas.save();
  canvas.clipPath(neck);
  // cylinder form: lit front-left, cool sides
  canvas.drawRect(
    Rect.fromCenter(center: Offset(c.dx, c.dy + hh * 1.3), width: hw * 3, height: hh * 2),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(c.dx - hw * 0.6, c.dy),
        Offset(c.dx + hw * 0.7, c.dy),
        [
          HeroLook.skinLit.withValues(alpha: 0.28),
          HeroLook.skinShadow.withValues(alpha: 0.0),
          HeroLook.skinShadow.withValues(alpha: 0.55),
          HeroLook.skinCool.withValues(alpha: 0.5),
        ],
        [0.0, 0.35, 0.8, 1.0],
      ),
  );
  // sternocleidomastoid ridges: from behind each jaw angle to the sternal notch
  for (final s in [-1.0, 1.0]) {
    final a = Offset(c.dx + s * hw * 0.42, topY + hh * 0.06);
    final b = Offset(c.dx - s * hw * 0.06, y(1.35));
    // the lit front edge of the muscle
    canvas.drawPath(
      Path()..moveTo(a.dx, a.dy)..quadraticBezierTo(
          c.dx + s * hw * 0.30, y(1.1), b.dx, b.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.05
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: s < 0 ? 0.28 : 0.14)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.05),
    );
    // the shadow tucking behind it
    canvas.drawPath(
      Path()..moveTo(a.dx + s * hw * 0.10, a.dy)..quadraticBezierTo(
          c.dx + s * hw * 0.44, y(1.12), b.dx + s * hw * 0.12, b.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.07
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.06),
    );
  }
  // sternal-notch pit
  _blob(canvas, Offset(c.dx, y(1.4)), hw * 0.10, hh * 0.06,
      HeroLook.skinDeep.withValues(alpha: 0.4), hw * 0.07);
  canvas.restore();

  // ── head-to-neck connection: a SOFT, deep contact shadow where the jaw
  //    overhangs — the mass sitting on the neck, no sharp cut ──
  _blob(canvas, Offset(c.dx, y(0.94)), hw * 0.66, hh * 0.13,
      HeroLook.skinDeep.withValues(alpha: 0.5), hh * 0.09);
  _blob(canvas, Offset(c.dx + hw * 0.30, y(0.96)), hw * 0.34, hh * 0.09,
      HeroLook.skinDeep.withValues(alpha: 0.4), hh * 0.07);
}

// ── PHASE 2.1B — FACIAL PLANES (clay blockout) ──────────────────────────────
// GEOMETRY FIRST: every plane is a bounded Path with a defined start and end,
// filled with its OWN light reaction (a directional gradient along the plane
// turn). Gradients only emphasise the plane geometry — they never invent it;
// no blob-blur volume. Edges carry only a hair of feather for C2-smooth
// transitions. All positions hang off the LOCKED 2.1A landmarks.

/// A bounded plane: [path] filled with a directional light reaction from
/// [from] to [to]; [feather] is edge smoothing only (never volume).
void _plane(Canvas canvas, Path path, Offset from, Offset to, Color a, Color b,
    {double feather = 0}) {
  // A fully-transparent stop must inherit the visible stop's RGB — a gradient
  // toward transparent BLACK (0x00000000) darkens its midsection into a smudge.
  if (a.a == 0) a = b.withValues(alpha: 0);
  if (b.a == 0) b = a.withValues(alpha: 0);
  final paint = Paint()..shader = ui.Gradient.linear(from, to, [a, b]);
  if (feather > 0) {
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, feather);
  }
  canvas.drawPath(path, paint);
}

Path _quad(List<Offset> pts) {
  // A smooth 4-corner region: corners rounded by curving through midpoints —
  // keeps C2-ish flow so no plane reads as a hard polygon.
  final p = Path();
  final n = pts.length;
  Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  final m0 = mid(pts[0], pts[n - 1]);
  p.moveTo(m0.dx, m0.dy);
  for (var i = 0; i < n; i++) {
    final m = mid(pts[i], pts[(i + 1) % n]);
    p.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
  }
  p.close();
  return p;
}

void _drawFacialStructure(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  Offset pt(double fx, double fy) => Offset(c.dx + hw * fx, y(fy));
  final head = _headPath(c, hw, hh);
  const none = Color(0x00000000);
  final f1 = hw * 0.034; // edge feather — transition smoothing only

  canvas.save();
  canvas.clipPath(head);

  // ── 1. FOREHEAD — three major planes ──
  // central plane: faces the key → brightest just above the brow, releasing
  // smoothly up INTO the crown (no top boundary — the cap-ghost killer)
  _plane(
      canvas,
      _quad([pt(-0.36, 0.19), pt(0.36, 0.19), pt(0.37, 0.478), pt(-0.38, 0.482)]),
      pt(0.0, 0.455), pt(0.0, 0.21),
      HeroLook.skinLit.withValues(alpha: 0.30), none, feather: f1);
  // left frontal plane: turns gently left — a quiet half-tone. Its lower edge
  // reaches the brow shelf so forehead→brow flows with no gap (2.1C).
  _plane(
      canvas,
      _quad([pt(-0.34, 0.31), pt(-0.80, 0.345), pt(-0.885, 0.505), pt(-0.37, 0.50)]),
      pt(-0.52, 0.42), pt(-0.92, 0.45),
      none, HeroLook.skinShadow.withValues(alpha: 0.13), feather: f1);
  // right frontal plane: turns into the fill → deeper half-tone (rhythm differs
  // from the left by under a percent — organic, not mirrored)
  _plane(
      canvas,
      _quad([pt(0.32, 0.31), pt(0.79, 0.345), pt(0.88, 0.503), pt(0.36, 0.498)]),
      pt(0.50, 0.42), pt(0.92, 0.45),
      none, HeroLook.skinShadow.withValues(alpha: 0.20), feather: f1);
  // supraorbital light bars — the BROW RIDGE catching the key above each
  // orbit: the natural bridge between forehead and orbital cavity (male,
  // present but never heavy)
  _plane(
      canvas,
      _quad([pt(-0.16, 0.468), pt(-0.58, 0.470), pt(-0.55, 0.489), pt(-0.17, 0.487)]),
      pt(-0.36, 0.469), pt(-0.36, 0.49),
      HeroLook.skinLit.withValues(alpha: 0.26), none, feather: f1 * 0.7);
  _plane(
      canvas,
      _quad([pt(0.16, 0.469), pt(0.575, 0.471), pt(0.545, 0.49), pt(0.17, 0.488)]),
      pt(0.36, 0.470), pt(0.36, 0.491),
      HeroLook.skinLit.withValues(alpha: 0.16), none, feather: f1 * 0.7);

  // ── 8. TEMPLE PLANES — forehead flank rolling into the temporal hollow ──
  for (final s in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(s * 0.66, 0.40), pt(s * 0.92, 0.42), pt(s * 0.88, 0.545),
            pt(s * 0.64, 0.52)]),
        pt(s * 0.66, 0.47), pt(s * 0.92, 0.48),
        none, HeroLook.skinShadow.withValues(alpha: s < 0 ? 0.13 : 0.18),
        feather: f1);
  }

  // ── 2. BROW PLANE — the shelf under the brow line turning DOWN over the
  //    orbits: it holds the sockets natural shadow ──
  for (final s in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(s * 0.14, 0.487), pt(s * 0.60, 0.487), pt(s * 0.56, 0.512),
            pt(s * 0.15, 0.512)]),
        pt(s * 0.35, 0.487), pt(s * 0.35, 0.516),
        none, HeroLook.skinShadow.withValues(alpha: s < 0 ? 0.15 : 0.19),
        feather: f1 * 0.8);
  }

  // ── 3. ORBITAL PLANES — the cavities as GEOMETRIC bowls (≈4% recess):
  //    following the 2.1A rims (flat heavy top, soft low arc), darkest toward
  //    the inner-upper corner, releasing outward-down. ──
  for (final s in [-1.0, 1.0]) {
    final ex = s * 0.37;
    final deep = s > 0 ? 0.30 : 0.24; // fill-side socket a touch deeper
    final bowl = Path()
      ..moveTo(c.dx + hw * (ex - s * 0.235), y(0.537))
      ..cubicTo(c.dx + hw * (ex - s * 0.12), y(0.472),
          c.dx + hw * (ex + s * 0.13), y(0.475),
          c.dx + hw * (ex + s * 0.235), y(0.511))
      ..cubicTo(c.dx + hw * (ex + s * 0.12), y(0.572),
          c.dx + hw * (ex - s * 0.11), y(0.575),
          c.dx + hw * (ex - s * 0.235), y(0.537))
      ..close();
    _plane(canvas, bowl,
        pt(ex - s * 0.12, 0.485), pt(ex + s * 0.20, 0.575),
        HeroLook.skinShadow.withValues(alpha: deep), none, feather: f1 * 1.3);
    // the INNER corner of each cavity sits a touch deeper than the outer —
    // real orbital volume, not a symmetric dish
    _plane(
        canvas,
        _quad([pt(ex - s * 0.235, 0.505), pt(ex - s * 0.08, 0.492),
            pt(ex - s * 0.09, 0.556), pt(ex - s * 0.22, 0.548)]),
        pt(ex - s * 0.20, 0.50), pt(ex - s * 0.05, 0.556),
        HeroLook.skinShadow.withValues(alpha: s > 0 ? 0.14 : 0.10), none,
        feather: f1 * 0.9);
  }

  // ── 4. GLABELLA PLANE — the bridge between the brows ──
  _plane(
      canvas,
      _quad([pt(-0.105, 0.462), pt(0.095, 0.462), pt(0.075, 0.535), pt(-0.085, 0.535)]),
      pt(-0.04, 0.465), pt(0.01, 0.535),
      HeroLook.skinLit.withValues(alpha: 0.18), none, feather: f1 * 0.9);

  // ── 5. NASAL ROOT PLANE — only the start of the nose central column ──
  _plane(
      canvas,
      _quad([pt(-0.075, 0.532), pt(0.065, 0.532), pt(0.055, 0.60), pt(-0.065, 0.60)]),
      pt(-0.03, 0.535), pt(0.0, 0.60),
      HeroLook.skinLit.withValues(alpha: 0.14), none, feather: f1 * 0.8);

  // ── 7. INFRAORBITAL PLANES — a slim lit step under each socket (volume,
  //    never darkness) ──
  for (final s in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(s * 0.16, 0.565), pt(s * 0.56, 0.558), pt(s * 0.52, 0.60),
            pt(s * 0.18, 0.605)]),
        pt(s * 0.35, 0.562), pt(s * 0.35, 0.606),
        HeroLook.skinLit.withValues(alpha: s < 0 ? 0.15 : 0.09), none,
        feather: f1 * 0.9);
  }

  // ── 6. CHEEK PLANES — the biggest facial planes: born under the orbit,
  //    flowing to the nose and on toward the mouth; the front face carries
  //    light, the lateral half rolls away. ──
  for (final s in [-1.0, 1.0]) {
    final lateral = s < 0 ? 0.14 : 0.20;
    // ~0.7% wider on the left — sculptor-level positional asymmetry
    final ax = s < 0 ? 1.007 : 1.0;
    _plane(
        canvas,
        _quad([pt(s * 0.12, 0.585), pt(s * 0.72 * ax, 0.575), pt(s * 0.62 * ax, 0.80),
            pt(s * 0.16, 0.825)]),
        pt(s * 0.18, 0.66), pt(s * 0.80, 0.72),
        HeroLook.skinLit.withValues(alpha: s < 0 ? 0.10 : 0.05),
        HeroLook.skinShadow.withValues(alpha: lateral), feather: f1);
  }

  // ── 9. JAW PLANES — silhouette untouched: the side (ramus) plane rolls
  //    away while the front jaw stays open to the light ──
  for (final s in [-1.0, 1.0]) {
    final ax = s < 0 ? 1.006 : 1.0; // matching left-side fullness
    _plane(
        canvas,
        _quad([pt(s * 0.58 * ax, 0.685), pt(s * 0.93 * ax, 0.67), pt(s * 0.72, 0.875),
            pt(s * 0.42, 0.905)]),
        pt(s * 0.52, 0.78), pt(s * 0.95, 0.78),
        none, HeroLook.skinShadow.withValues(alpha: s < 0 ? 0.15 : 0.21),
        feather: f1 * 1.2);
  }

  // ── 10. CHIN PLANES — top (mento-labial turn), front (lit platform),
  //    bottom (the underside rolling away) ──
  _plane(
      canvas,
      _quad([pt(-0.17, 0.862), pt(0.17, 0.862), pt(0.15, 0.895), pt(-0.15, 0.895)]),
      pt(0, 0.862), pt(0, 0.897),
      none, HeroLook.skinShadow.withValues(alpha: 0.10), feather: f1 * 0.8);
  _plane(
      canvas,
      _quad([pt(-0.16, 0.897), pt(0.16, 0.897), pt(0.13, 0.962), pt(-0.13, 0.962)]),
      pt(-0.05, 0.90), pt(0.02, 0.96),
      HeroLook.skinLit.withValues(alpha: 0.20), none, feather: f1 * 0.8);
  _plane(
      canvas,
      _quad([pt(-0.13, 0.968), pt(0.13, 0.968), pt(0.10, 0.998), pt(-0.10, 0.998)]),
      pt(0, 0.968), pt(0, 1.0),
      none, HeroLook.skinShadow.withValues(alpha: 0.16), feather: f1 * 0.8);

  canvas.restore();
}

// ── PHASE 2.2A — EYE SOCKET CONSTRUCTION ────────────────────────────────────
// The anatomical orbital cavities the eyes will seat into. GEOMETRY, not blur:
// each socket is a rim-following bowl (5–7% total recess with the 2.1B bowls),
// ringed by the orbital RIM — the upper (supraorbital) bone edge reads
// stronger than the soft lower (infraorbital) ledge; the inner-canthus corner
// recesses deepest; the outer canthus rides a touch high. L/R differ ~0.5–1%.
void _drawEyeSockets(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  Offset pt(double fx, double fy) => Offset(c.dx + hw * fx, y(fy));
  canvas.save();
  canvas.clipPath(_headPath(c, hw, hh));

  for (final s in [-1.0, 1.0]) {
    // micro-asymmetry: the left socket rides ~0.4% higher and a hair shallower
    final lift = s < 0 ? 0.004 : 0.0;
    final depthA = s > 0 ? 0.15 : 0.11;
    final ex = s * 0.36;
    final w2 = 0.235; // socket half-width (matches the 2.1A rim)
    final eyF = _fEye - lift;
    final inC = pt(ex - s * w2, eyF + 0.012);
    final outC = pt(ex + s * w2, eyF - 0.014);

    // ── the socket bowl (adds onto the 2.1B cavity → total ≈5–7% recess).
    //    Bounded by the SAME rim curves as the 2.1A landmarks. ──
    final bowl = Path()
      ..moveTo(inC.dx, inC.dy)
      ..cubicTo(c.dx + hw * (ex - s * w2 * 0.5), y(eyF - 0.062),
          c.dx + hw * (ex + s * w2 * 0.55), y(eyF - 0.058), outC.dx, outC.dy)
      ..cubicTo(c.dx + hw * (ex + s * w2 * 0.5), y(eyF + 0.048),
          c.dx + hw * (ex - s * w2 * 0.45), y(eyF + 0.044), inC.dx, inC.dy)
      ..close();
    _plane(canvas, bowl, pt(ex - s * 0.14, eyF - 0.045),
        pt(ex + s * 0.18, eyF + 0.04),
        HeroLook.skinShadow.withValues(alpha: depthA),
        HeroLook.skinShadow.withValues(alpha: 0.0));

    // ── UPPER ORBITAL RIM — the supraorbital bone edge: a crisp lit line
    //    riding just above the cavity + its underside shadow inside. ──
    final upperRim = Path()
      ..moveTo(inC.dx, inC.dy - hh * 0.008)
      ..cubicTo(c.dx + hw * (ex - s * w2 * 0.5), y(eyF - 0.072),
          c.dx + hw * (ex + s * w2 * 0.55), y(eyF - 0.068),
          outC.dx, outC.dy - hh * 0.006);
    canvas.drawPath(
      upperRim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.014
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: s < 0 ? 0.30 : 0.20),
    );
    canvas.drawPath(
      Path()
        ..moveTo(inC.dx + s * hw * 0.02, inC.dy)
        ..cubicTo(c.dx + hw * (ex - s * w2 * 0.45), y(eyF - 0.050),
            c.dx + hw * (ex + s * w2 * 0.5), y(eyF - 0.046),
            outC.dx - s * hw * 0.015, outC.dy + hh * 0.004),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.012
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: s > 0 ? 0.22 : 0.17),
    );

    // ── LOWER ORBITAL RIM — the soft infraorbital ledge: a gentle light,
    //    never a bag (support, not puffiness). ──
    canvas.drawPath(
      Path()
        ..moveTo(inC.dx + s * hw * 0.03, inC.dy + hh * 0.030)
        ..cubicTo(c.dx + hw * (ex - s * w2 * 0.4), y(eyF + 0.058),
            c.dx + hw * (ex + s * w2 * 0.45), y(eyF + 0.050),
            outC.dx - s * hw * 0.01, outC.dy + hh * 0.038),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.011
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: s < 0 ? 0.16 : 0.11),
    );

    // ── INNER CANTHUS — the deepest recess (future tear-duct seat) ──
    _plane(
        canvas,
        _quad([pt(ex - s * w2, eyF - 0.006), pt(ex - s * (w2 - 0.075), eyF - 0.018),
            pt(ex - s * (w2 - 0.06), eyF + 0.026), pt(ex - s * (w2 + 0.01), eyF + 0.018)]),
        pt(ex - s * w2, eyF), pt(ex - s * (w2 - 0.08), eyF + 0.01),
        HeroLook.skinShadow.withValues(alpha: s > 0 ? 0.16 : 0.12),
        HeroLook.skinShadow.withValues(alpha: 0.0));

    // ── OUTER CANTHUS — a small lifted plane; the corner rides high ──
    _plane(
        canvas,
        _quad([pt(ex + s * (w2 - 0.06), eyF - 0.028), pt(ex + s * (w2 + 0.02), eyF - 0.02),
            pt(ex + s * (w2 + 0.01), eyF + 0.006), pt(ex + s * (w2 - 0.05), eyF + 0.002)]),
        pt(ex + s * (w2 - 0.04), eyF - 0.02), pt(ex + s * (w2 + 0.02), eyF + 0.004),
        HeroLook.skinLit.withValues(alpha: s < 0 ? 0.14 : 0.09),
        HeroLook.skinLit.withValues(alpha: 0.0));
  }

  canvas.restore();
}

// ── PHASE 2.3A — NASAL FOUNDATION (blockout) ────────────────────────────────
// The large anatomical mass between the eyes and the upper lip, carved from
// the same skull — a PYRAMID: one front (dorsum) plane + two side planes that
// rotate away from the centre. The root flows out of the glabella with no
// step; the bridge is medium-width (≈ the inter-canthal distance at its base)
// with the faintest natural convexity; the lower third stays a reserved
// placeholder (NO tip ball, NO nostrils, NO alar wings). Bounded planes only.
void _drawNoseFoundation(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  Offset pt(double fx, double fy) => Offset(c.dx + hw * fx, y(fy));
  canvas.save();
  canvas.clipPath(_headPath(c, hw, hh));

  // ── ROOT — the forehead becoming the bridge: one continuous lit column
  //    from the glabella down past the inter-canthal line (no step)
  _plane(
      canvas,
      _quad([pt(-0.085, 0.495), pt(0.075, 0.495), pt(0.062, 0.575), pt(-0.072, 0.575)]),
      pt(-0.005, 0.50), pt(-0.005, 0.578),
      HeroLook.skinLit.withValues(alpha: 0.20),
      HeroLook.skinLit.withValues(alpha: 0.10));

  // ── FRONT (dorsum) PLANE — straight with an extremely subtle convexity,
  //    widening gradually toward the lower nose
  _plane(
      canvas,
      _quad([pt(-0.0585, 0.565), pt(0.048, 0.565), pt(0.070, 0.695), pt(-0.0805, 0.695)]),
      pt(-0.005, 0.575), pt(-0.005, 0.70),
      HeroLook.skinLit.withValues(alpha: 0.26),
      HeroLook.skinLit.withValues(alpha: 0.12));
  // the natural convexity — one narrow, slightly brighter pass mid-bridge
  _plane(
      canvas,
      _quad([pt(-0.044, 0.598), pt(0.034, 0.60), pt(0.038, 0.668), pt(-0.048, 0.665)]),
      pt(-0.005, 0.602), pt(-0.005, 0.668),
      HeroLook.skinLit.withValues(alpha: 0.09),
      HeroLook.skinLit.withValues(alpha: 0.0));

  // ── SIDE PLANES — rotate away from the centre; the fill (right) side turns
  //    into shadow harder than the key (left) side
  _plane(
      canvas,
      _quad([pt(0.04, 0.575), pt(0.125, 0.59), pt(0.172, 0.70), pt(0.062, 0.695)]),
      pt(0.045, 0.63), pt(0.215, 0.665),
      HeroLook.skinShadow.withValues(alpha: 0.0),
      HeroLook.skinShadow.withValues(alpha: 0.13));
  _plane(
      canvas,
      _quad([pt(-0.05, 0.575), pt(-0.135, 0.59), pt(-0.181, 0.70), pt(-0.072, 0.695)]),
      pt(-0.055, 0.63), pt(-0.225, 0.665),
      HeroLook.skinShadow.withValues(alpha: 0.0),
      HeroLook.skinShadow.withValues(alpha: 0.08));

  // ── side-wall link into the inner canthus — the pyramid is carved from the
  //    same skull as the sockets (no floating)
  for (final sSide in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sSide * 0.095, 0.545), pt(sSide * 0.14, 0.555),
            pt(sSide * 0.135, 0.615), pt(sSide * 0.085, 0.605)]),
        pt(sSide * 0.09, 0.55), pt(sSide * 0.145, 0.61),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sSide > 0 ? 0.08 : 0.05));
  }

  // ── LOWER NOSE — reserved space ONLY (V2): no tip, no columella, no alar
  //    cartilage, no nostrils. The mass simply releases below the bridge.

  canvas.restore();
}

// ── PHASE 2.2G — MIDFACE INTEGRATION ────────────────────────────────────────
// Connective anatomy only: the GLABELLA gains a gentle forward projection with
// soft side walls; the NASION is a subtle (never indented) turn where the
// forehead becomes the bridge; the BROW RIDGE flows out of the frontal bone
// instead of floating; the SUPERIOR-ZYGOMATIC (upper-cheek) plane rises to
// support the lower lids and fuses the orbital region into the cheek planes.
// 98% symmetric, ~2% organic difference. Bounded planes; no new features.
void _drawMidfaceIntegration(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  Offset pt(double fx, double fy) => Offset(c.dx + hw * fx, y(fy));
  canvas.save();
  canvas.clipPath(_headPath(c, hw, hh));

  // ── GLABELLA — gentle forward projection: a soft central swell whose side
  //    walls turn down toward each brow head (intelligence, not aggression)
  _plane(
      canvas,
      _quad([pt(-0.10, 0.452), pt(0.09, 0.452), pt(0.075, 0.52), pt(-0.088, 0.52)]),
      pt(-0.01, 0.455), pt(-0.005, 0.522),
      HeroLook.skinLit.withValues(alpha: 0.16),
      HeroLook.skinLit.withValues(alpha: 0.06));
  for (final sd in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sd * 0.095, 0.462), pt(sd * 0.155, 0.468),
            pt(sd * 0.145, 0.515), pt(sd * 0.085, 0.512)]),
        pt(sd * 0.09, 0.485), pt(sd * 0.165, 0.492),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.09 : 0.06));
  }

  // ── NASION — the soft turn where forehead becomes bridge: the faintest
  //    horizontal whisper across the root (never a sharp indent)
  _plane(
      canvas,
      _quad([pt(-0.075, 0.542), pt(0.065, 0.542), pt(0.06, 0.558), pt(-0.07, 0.558)]),
      pt(-0.005, 0.541), pt(-0.005, 0.559),
      HeroLook.skinShadow.withValues(alpha: 0.08),
      HeroLook.skinShadow.withValues(alpha: 0.0));

  // ── BROW RIDGE CONTINUITY — the ridge grows out of the frontal bone: a
  //    soft vertical blend at each bar's inner end (no floating shelf)
  for (final sd in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sd * 0.13, 0.448), pt(sd * 0.20, 0.452),
            pt(sd * 0.19, 0.487), pt(sd * 0.125, 0.483)]),
        pt(sd * 0.16, 0.450), pt(sd * 0.16, 0.489),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.12 : 0.08),
        HeroLook.skinLit.withValues(alpha: 0.0));
  }

  // ── SUPERIOR ZYGOMATIC (upper cheek) — the large plane rising beneath each
  //    socket: its top supports the lower lid, its body fuses the orbital
  //    region into the existing cheek planes (no volume added)
  for (final sd in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sd * 0.17, 0.585), pt(sd * 0.60, 0.572),
            pt(sd * 0.56, 0.665), pt(sd * 0.19, 0.672)]),
        pt(sd * 0.35, 0.582), pt(sd * 0.37, 0.672),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.12 : 0.07),
        HeroLook.skinLit.withValues(alpha: 0.0));
    // outer-orbital → temple/cheek junction: a faint fusing turn
    _plane(
        canvas,
        _quad([pt(sd * 0.585, 0.548), pt(sd * 0.70, 0.556),
            pt(sd * 0.66, 0.625), pt(sd * 0.555, 0.615)]),
        pt(sd * 0.57, 0.57), pt(sd * 0.72, 0.60),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.11 : 0.08));
  }

  canvas.restore();
}

// ── PHASE 2.3B — PRIMARY NOSE ANATOMY ───────────────────────────────────────
// The four load-bearing structures built into the reserved lower-nose space:
// a cartilage TIP (one continuous soft volume, never a ball) emerging from the
// bridge over the faintest supratip turn; L/R ALAR cartilages wrapping the tip
// (soft lateral support, capped inside the inter-canthal width); a quiet
// COLUMELLA between the nostrils flowing into the philtrum; NOSTRIL openings
// as soft warm crescents riding the alar curvature — partially visible, never
// black holes. 98/2 asymmetry: the right nostril runs a touch larger/deeper.
void _drawNosePrimary(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  Offset pt(double fx, double fy) => Offset(c.dx + hw * fx, y(fy));
  canvas.save();
  canvas.clipPath(_headPath(c, hw, hh));

  // ── SUPRATIP — the faintest turn where the bridge releases into the tip
  _plane(
      canvas,
      _quad([pt(-0.060, 0.6915), pt(0.049, 0.692), pt(0.046, 0.7065), pt(-0.056, 0.706)]),
      pt(-0.005, 0.691), pt(-0.005, 0.707),
      HeroLook.skinShadow.withValues(alpha: 0.07),
      HeroLook.skinShadow.withValues(alpha: 0.0));

  // ── NASAL TIP — one continuous cartilage volume: a soft lobule plane that
  //    carries the key light, with a smaller brighter core riding upper-left
  _plane(
      canvas,
      _quad([pt(-0.068, 0.706), pt(0.058, 0.706), pt(0.042, 0.742), pt(-0.050, 0.742)]),
      pt(-0.008, 0.708), pt(-0.005, 0.748),
      HeroLook.skinLit.withValues(alpha: 0.26),
      HeroLook.skinLit.withValues(alpha: 0.06));
  _plane(
      canvas,
      _quad([pt(-0.048, 0.710), pt(0.018, 0.710), pt(0.008, 0.731), pt(-0.030, 0.731)]),
      pt(-0.018, 0.711), pt(-0.012, 0.732),
      HeroLook.skinLit.withValues(alpha: 0.12),
      HeroLook.skinLit.withValues(alpha: 0.0));

  // ── ALAR CARTILAGE — wings wrapping the tip; lit crest + a lateral turn
  for (final sd in [-1.0, 1.0]) {
    final wide = sd > 0 ? 1.0 : 0.97; // 2% organic difference
    // the wing's soft crest catching light from above
    _plane(
        canvas,
        _quad([pt(sd * 0.058, 0.716), pt(sd * 0.132 * wide, 0.726),
            pt(sd * 0.148 * wide, 0.744), pt(sd * 0.070, 0.740)]),
        pt(sd * 0.07, 0.718), pt(sd * 0.15 * wide, 0.742),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.14 : 0.09),
        HeroLook.skinLit.withValues(alpha: 0.0));
    // the wing's lateral turn away (its outer wall into the cheek)
    _plane(
        canvas,
        _quad([pt(sd * 0.118 * wide, 0.722), pt(sd * 0.158 * wide, 0.732),
            pt(sd * 0.146 * wide, 0.756), pt(sd * 0.104, 0.752)]),
        pt(sd * 0.12 * wide, 0.73), pt(sd * 0.165 * wide, 0.748),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.13 : 0.09));
    // alar groove — the soft crease seating the wing against the tip
    canvas.drawPath(
      Path()
        ..moveTo(pt(sd * 0.062, 0.722).dx, pt(sd * 0.062, 0.722).dy)
        ..quadraticBezierTo(pt(sd * 0.092, 0.734).dx, pt(sd * 0.092, 0.734).dy,
            pt(sd * 0.084, 0.75).dx, pt(sd * 0.084, 0.75).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.005
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.22 : 0.16),
    );
  }

  // ── NOSTRIL OPENINGS — soft warm crescents riding the alar curvature:
  //    partially visible from the front, never black, never outlined
  for (final sd in [-1.0, 1.0]) {
    final grow = sd > 0 ? 1.05 : 1.0; // right a touch larger (asymmetry)
    final a0 = pt(sd * 0.040, 0.7485);
    final a1 = pt(sd * 0.100 * grow, sd < 0 ? 0.7452 : 0.7443);
    final nostril = Path()
      ..moveTo(a0.dx, a0.dy)
      ..quadraticBezierTo(pt(sd * 0.070, 0.738).dx, pt(sd * 0.070, 0.738).dy,
          a1.dx, a1.dy)
      ..quadraticBezierTo(pt(sd * 0.072, 0.7535).dx, pt(sd * 0.072, 0.7535).dy,
          a0.dx, a0.dy)
      ..close();
    canvas.drawPath(
        nostril,
        Paint()
          ..color = HeroLook.skinDeep.withValues(alpha: sd > 0 ? 0.36 : 0.31));
    // the opening's inner warmth — a smaller, deeper core (never pure dark)
    canvas.drawPath(
      Path()
        ..moveTo(pt(sd * 0.050, 0.7475).dx, pt(sd * 0.050, 0.7475).dy)
        ..quadraticBezierTo(pt(sd * 0.072, 0.7425).dx, pt(sd * 0.072, 0.7425).dy,
            pt(sd * 0.090 * grow, 0.7455).dx, pt(sd * 0.090 * grow, 0.7455).dy)
        ..quadraticBezierTo(pt(sd * 0.068, 0.750).dx, pt(sd * 0.068, 0.750).dy,
            pt(sd * 0.050, 0.7475).dx, pt(sd * 0.050, 0.7475).dy)
        ..close(),
      Paint()..color = const Color(0x42714A38),
    );
  }

  // ── COLUMELLA — the quiet central pillar between the nostrils, flowing
  //    down into the philtrum with no visible break
  _plane(
      canvas,
      _quad([pt(-0.026, 0.735), pt(0.020, 0.735), pt(0.016, 0.758), pt(-0.022, 0.758)]),
      pt(-0.003, 0.736), pt(-0.003, 0.762),
      HeroLook.skinLit.withValues(alpha: 0.12),
      HeroLook.skinLit.withValues(alpha: 0.02));

  // ── SECONDARY SIDE-WALL CHAIN — one long, quiet connective plane per side:
  //    bridge → upper side wall → lower lateral cartilage → alar top, so the
  //    whole lateral flow reads as a single grown surface
  for (final sd in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sd * 0.075, 0.64), pt(sd * 0.125, 0.655),
            pt(sd * 0.128, 0.725), pt(sd * 0.066, 0.712)]),
        pt(sd * 0.075, 0.66), pt(sd * 0.145, 0.70),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.09 : 0.06));
    // alar outer wall dissolving into the cheek (no floating nose)
    _plane(
        canvas,
        _quad([pt(sd * 0.148, 0.728), pt(sd * 0.21, 0.732),
            pt(sd * 0.195, 0.762), pt(sd * 0.135, 0.757)]),
        pt(sd * 0.15, 0.74), pt(sd * 0.22, 0.752),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.08 : 0.05),
        HeroLook.skinShadow.withValues(alpha: 0.0));
  }

  // ── BASE — the soft contact shadow seating the whole nose onto the upper
  //    lip plane (smooth transition, no break)
  _plane(
      canvas,
      _quad([pt(-0.115, 0.753), pt(0.105, 0.753), pt(0.085, 0.766), pt(-0.095, 0.766)]),
      pt(-0.005, 0.752), pt(-0.005, 0.769),
      HeroLook.skinShadow.withValues(alpha: 0.10),
      HeroLook.skinShadow.withValues(alpha: 0.0));

  canvas.restore();
}

// ── PHASE 2.4A — ORAL FOUNDATION ────────────────────────────────────────────
// The mouth's underlying structure — NOT lips. The whole perioral zone wraps
// the ORAL CYLINDER (the dental arch): its front catches light at the centre
// and rolls away toward the nasolabial regions. The MAXILLA gently projects
// the upper-lip zone; the MANDIBLE zone flows into the locked chin planes
// with no step. A shallow PHILTRUM channel (two soft ridges, faint groove)
// guides the future lips; the NEUTRAL resting mouth line sits at the mouth
// landmark with corners aligned near the iris centres. 98/2 asymmetry.
void _drawOralFoundation(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  Offset pt(double fx, double fy) => Offset(c.dx + hw * fx, y(fy));
  canvas.save();
  canvas.clipPath(_headPath(c, hw, hh));

  // ── ORAL CYLINDER — the dental-arch curvature: a broad central front that
  //    carries light, rolling away on both sides (the mouth wraps the teeth)
  _plane(
      canvas,
      _quad([pt(-0.20, 0.772), pt(0.185, 0.772), pt(0.17, 0.882), pt(-0.185, 0.882)]),
      pt(-0.01, 0.79), pt(-0.005, 0.885),
      HeroLook.skinLit.withValues(alpha: 0.12),
      HeroLook.skinLit.withValues(alpha: 0.03));
  for (final sd in [-1.0, 1.0]) {
    // the cylinder's lateral roll — toward the nasolabial/perioral zone
    _plane(
        canvas,
        _quad([pt(sd * 0.17, 0.775), pt(sd * 0.345, 0.782),
            pt(sd * 0.315, 0.878), pt(sd * 0.155, 0.885)]),
        pt(sd * 0.18, 0.825), pt(sd * 0.375, 0.835),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.15 : 0.10));
  }

  // ── MAXILLA SUPPORT — the upper-lip zone's gentle forward projection
  _plane(
      canvas,
      _quad([pt(-0.155, 0.772), pt(0.145, 0.772), pt(0.135, 0.828), pt(-0.145, 0.828)]),
      pt(-0.005, 0.776), pt(-0.005, 0.83),
      HeroLook.skinLit.withValues(alpha: 0.10),
      HeroLook.skinLit.withValues(alpha: 0.0));

  // ── PHILTRUM FOUNDATION — a shallow elegant channel: two soft ridges with
  //    the faintest groove between (structure only, no drama)
  for (final sd in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sd * 0.014, 0.772), pt(sd * 0.036, 0.774),
            pt(sd * 0.030, 0.826), pt(sd * 0.011, 0.824)]),
        pt(sd * 0.012, 0.776), pt(sd * 0.04, 0.825),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.11 : 0.08),
        HeroLook.skinLit.withValues(alpha: 0.0));
  }
  _plane(
      canvas,
      _quad([pt(-0.008, 0.774), pt(0.006, 0.774), pt(0.005, 0.824), pt(-0.006, 0.824)]),
      pt(-0.001, 0.776), pt(-0.001, 0.824),
      HeroLook.skinShadow.withValues(alpha: 0.07),
      HeroLook.skinShadow.withValues(alpha: 0.03));

  // ── NEUTRAL MOUTH LINE — the resting seam only (no lips, no expression):
  //    corners near the iris centres; the left corner a hair higher (2%)
  canvas.drawPath(
    Path()
      ..moveTo(pt(-0.325, 0.8335).dx, pt(-0.325, 0.8335).dy)
      ..cubicTo(pt(-0.12, 0.8385).dx, pt(-0.12, 0.8385).dy,
          pt(0.12, 0.8385).dx, pt(0.12, 0.8385).dy,
          pt(0.320, 0.8345).dx, pt(0.320, 0.8345).dy),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hh * 0.007
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x59936A55),
  );
  // corner seats — the line tucks into the perioral planes, never floats
  for (final sd in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sd * 0.30, 0.826), pt(sd * 0.355, 0.830),
            pt(sd * 0.345, 0.845), pt(sd * 0.29, 0.842)]),
        pt(sd * 0.30, 0.834), pt(sd * 0.365, 0.837),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.10 : 0.08));
  }

  // ── MANDIBLE SUPPORT — the lower oral zone flowing into the locked chin
  //    planes (mental region): a soft release, no step, no lip platform
  _plane(
      canvas,
      _quad([pt(-0.16, 0.842), pt(0.15, 0.842), pt(0.14, 0.864), pt(-0.15, 0.864)]),
      pt(-0.005, 0.843), pt(-0.005, 0.866),
      HeroLook.skinLit.withValues(alpha: 0.08),
      HeroLook.skinLit.withValues(alpha: 0.0));

  canvas.restore();
}

// ── PHASE 2.4B — PRIMARY LIP ANATOMY ────────────────────────────────────────
// The lips as ONE muscle cylinder (orbicularis oris) wrapping the locked oral
// foundation: the upper mass faces down-forward (quieter light, projects a
// touch less), the lower mass faces up (catches the key, projects a touch
// more; ~40/60 height split). The cupid's bow exists only as a gentle central
// descent; the commissures dissolve into the perioral tissue; the philtrum
// flows in with no seam; the lower lip releases through a soft labiomental
// turn into the locked chin planes. Form first — only a whisper of natural
// tissue warmth, no cosmetics.
void _drawLipsPrimary(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  Offset pt(double fx, double fy) => Offset(c.dx + hw * fx, y(fy));
  canvas.save();
  canvas.clipPath(_headPath(c, hw, hh));

  // ── UPPER LIP MASS — its plane faces down/away from the key → a quiet
  //    half-tone band; the top contour carries the subtle cupid's descent
  final upperLip = Path()
    ..moveTo(pt(-0.325, 0.8335).dx, pt(-0.325, 0.8335).dy)
    // top edge: rises from the corner, two soft crests, gentle central dip
    ..cubicTo(pt(-0.22, 0.8165).dx, pt(-0.22, 0.8165).dy,
        pt(-0.085, 0.8115).dx, pt(-0.085, 0.8115).dy,
        pt(-0.030, 0.8135).dx, pt(-0.030, 0.8135).dy)
    ..quadraticBezierTo(pt(0.0, 0.8155).dx, pt(0.0, 0.8155).dy,
        pt(0.028, 0.8135).dx, pt(0.028, 0.8135).dy)
    ..cubicTo(pt(0.082, 0.8115).dx, pt(0.082, 0.8115).dy,
        pt(0.215, 0.8165).dx, pt(0.215, 0.8165).dy,
        pt(0.320, 0.8345).dx, pt(0.320, 0.8345).dy)
    // bottom edge = the locked neutral seam
    ..cubicTo(pt(0.12, 0.8390).dx, pt(0.12, 0.8390).dy,
        pt(-0.12, 0.8390).dx, pt(-0.12, 0.8390).dy,
        pt(-0.325, 0.8335).dx, pt(-0.325, 0.8335).dy)
    ..close();
  canvas.drawPath(
      upperLip, Paint()..color = HeroLook.skinShadow.withValues(alpha: 0.24));
  // its top releases into the philtrum with no seam
  _plane(
      canvas,
      _quad([pt(-0.18, 0.806), pt(0.17, 0.806), pt(0.16, 0.8175), pt(-0.17, 0.8175)]),
      pt(-0.005, 0.818), pt(-0.005, 0.804),
      HeroLook.skinShadow.withValues(alpha: 0.08),
      HeroLook.skinShadow.withValues(alpha: 0.0));
  // the natural tissue warmth — a whisper, not lipstick
  canvas.drawPath(
      upperLip, Paint()..color = const Color(0x24B06A52));

  // ── LOWER LIP MASS — one continuous soft volume facing the key: a lit
  //    band whose two lateral lobes carry the fullness (left a hair fuller)
  final lowerLip = Path()
    ..moveTo(pt(-0.325, 0.8335).dx, pt(-0.325, 0.8335).dy)
    ..cubicTo(pt(-0.12, 0.8390).dx, pt(-0.12, 0.8390).dy,
        pt(0.12, 0.8390).dx, pt(0.12, 0.8390).dy,
        pt(0.320, 0.8345).dx, pt(0.320, 0.8345).dy)
    // bottom edge: fuller centre, releasing to the corners
    ..cubicTo(pt(0.20, 0.8618).dx, pt(0.20, 0.8618).dy,
        pt(0.075, 0.8663).dx, pt(0.075, 0.8663).dy,
        pt(-0.005, 0.8665).dx, pt(-0.005, 0.8665).dy)
    ..cubicTo(pt(-0.085, 0.8665).dx, pt(-0.085, 0.8665).dy,
        pt(-0.21, 0.8620).dx, pt(-0.21, 0.8620).dy,
        pt(-0.325, 0.8335).dx, pt(-0.325, 0.8335).dy)
    ..close();
  canvas.drawPath(
      lowerLip, Paint()..color = HeroLook.skinLit.withValues(alpha: 0.14));
  canvas.drawPath(
      lowerLip, Paint()..color = const Color(0x2BC47A5E));
  // the two soft lobes of the lower lip (form, not paint)
  _plane(
      canvas,
      _quad([pt(-0.155, 0.842), pt(-0.03, 0.844), pt(-0.035, 0.860), pt(-0.15, 0.857)]),
      pt(-0.10, 0.843), pt(-0.09, 0.861),
      HeroLook.skinLit.withValues(alpha: 0.14),
      HeroLook.skinLit.withValues(alpha: 0.0));
  _plane(
      canvas,
      _quad([pt(0.025, 0.844), pt(0.145, 0.842), pt(0.14, 0.857), pt(0.03, 0.860)]),
      pt(0.09, 0.843), pt(0.08, 0.861),
      HeroLook.skinLit.withValues(alpha: 0.11),
      HeroLook.skinLit.withValues(alpha: 0.0));

  // ── COMMISSURES — the corners dissolve into perioral tissue (no outline,
  //    no abrupt end): a soft turn at each corner over the 2.4A seats
  for (final sd in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sd * 0.295, 0.828), pt(sd * 0.345, 0.8315),
            pt(sd * 0.335, 0.8455), pt(sd * 0.285, 0.8435)]),
        pt(sd * 0.295, 0.836), pt(sd * 0.355, 0.838),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.14 : 0.10),
        HeroLook.skinShadow.withValues(alpha: 0.0));
  }

  // ── LABIOMENTAL FLOW — the lower lip releases through a soft fold into
  //    the locked mental/chin planes (one continuous chain, never deep)
  _plane(
      canvas,
      _quad([pt(-0.14, 0.8655), pt(0.13, 0.8655), pt(0.12, 0.8775), pt(-0.13, 0.8775)]),
      pt(-0.005, 0.8645), pt(-0.005, 0.879),
      HeroLook.skinShadow.withValues(alpha: 0.09),
      HeroLook.skinShadow.withValues(alpha: 0.0));

  // ═══ PHASE 2.4C — ORBICULARIS ORIS SECONDARY FORMS ═══
  // Muscle revelation only: proportions, position and thickness untouched.

  // ── CENTRAL TUBERCLE — the upper lip's centre projects a whisper, carried
  //    by structure beneath (never inflated, never flat)
  _plane(
      canvas,
      _quad([pt(-0.035, 0.822), pt(0.028, 0.822), pt(0.022, 0.836), pt(-0.028, 0.836)]),
      pt(-0.004, 0.823), pt(-0.004, 0.837),
      HeroLook.skinLit.withValues(alpha: 0.10),
      HeroLook.skinLit.withValues(alpha: 0.0));

  // ── UPPER VERMILION ROLL — the lip's lower margin rolls gently outward and
  //    catches a soft under-light just above the seam (no gloss)
  canvas.drawPath(
    Path()
      ..moveTo(pt(-0.255, 0.8322).dx, pt(-0.255, 0.8322).dy)
      ..cubicTo(pt(-0.10, 0.8368).dx, pt(-0.10, 0.8368).dy,
          pt(0.10, 0.8368).dx, pt(0.10, 0.8368).dy,
          pt(0.265, 0.8330).dx, pt(0.265, 0.8330).dy),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hh * 0.0055
      ..strokeCap = StrokeCap.round
      ..color = HeroLook.skinLit.withValues(alpha: 0.22),
  );

  // ── UPPER LATERAL SEGMENTS — the band is not uniform: the lateral wings
  //    turn a touch further from the light than the central plane
  for (final sd in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sd * 0.115, 0.818), pt(sd * 0.27, 0.8235),
            pt(sd * 0.26, 0.8345), pt(sd * 0.11, 0.8335)]),
        pt(sd * 0.12, 0.824), pt(sd * 0.285, 0.829),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.10 : 0.07));
  }

  // ── LOWER LIP ROLL — the top margin under the seam holds a quiet half-tone
  //    before the lit mass (the roll turning up toward the light)
  canvas.drawPath(
    Path()
      ..moveTo(pt(-0.26, 0.8375).dx, pt(-0.26, 0.8375).dy)
      ..cubicTo(pt(-0.09, 0.8415).dx, pt(-0.09, 0.8415).dy,
          pt(0.09, 0.8415).dx, pt(0.09, 0.8415).dy,
          pt(0.255, 0.8385).dx, pt(0.255, 0.8385).dy),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hh * 0.0050
      ..strokeCap = StrokeCap.round
      ..color = HeroLook.skinShadow.withValues(alpha: 0.16),
  );

  // ── LOWER LIP 3-MASS STRUCTURE — a soft central mass between the two lobes
  //    with whisper relaxations either side (never one inflated blob)
  _plane(
      canvas,
      _quad([pt(-0.035, 0.845), pt(0.03, 0.845), pt(0.026, 0.8615), pt(-0.03, 0.8615)]),
      pt(-0.003, 0.846), pt(-0.003, 0.862),
      HeroLook.skinLit.withValues(alpha: 0.10),
      HeroLook.skinLit.withValues(alpha: 0.0));
  for (final sd in [-1.0, 1.0]) {
    _plane(
        canvas,
        _quad([pt(sd * 0.038, 0.8445), pt(sd * 0.058, 0.8445),
            pt(sd * 0.054, 0.860), pt(sd * 0.035, 0.860)]),
        pt(sd * 0.037, 0.845), pt(sd * 0.058, 0.859),
        HeroLook.skinShadow.withValues(alpha: 0.05),
        HeroLook.skinShadow.withValues(alpha: 0.0));
  }

  // ── ORBICULARIS RING — the muscle wraps CONTINUOUSLY around the corners:
  //    a soft connective turn linking upper and lower bands at each commissure
  for (final sd in [-1.0, 1.0]) {
    canvas.drawPath(
      Path()
        ..moveTo(pt(sd * 0.285, 0.8245).dx, pt(sd * 0.285, 0.8245).dy)
        ..quadraticBezierTo(pt(sd * 0.335, 0.8345).dx, pt(sd * 0.335, 0.8345).dy,
            pt(sd * 0.28, 0.8485).dx, pt(sd * 0.28, 0.8485).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.008
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.07 : 0.05),
    );
  }

  // ═══ PHASE 2.4D — COMMISSURE + LABIOMENTAL INTEGRATION ═══
  // The corners are transition ZONES, not endpoints: broad dissolve fans plus
  // whisper-level surface behaviour of the merging muscles.

  for (final sd in [-1.0, 1.0]) {
    // ── COMMISSURE DISSOLVE FAN — the corner melts into the cheek tissue
    _plane(
        canvas,
        _quad([pt(sd * 0.30, 0.818), pt(sd * 0.46, 0.812),
            pt(sd * 0.44, 0.862), pt(sd * 0.295, 0.855)]),
        pt(sd * 0.31, 0.836), pt(sd * 0.48, 0.836),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.07 : 0.05),
        HeroLook.skinShadow.withValues(alpha: 0.0));
    // ── MUSCLE SURFACE BEHAVIOUR — three whisper pulls radiating from the
    //    corner: zygomatic (up-out), risorius (lateral), depressor (down-out)
    canvas.drawPath(
      Path()
        ..moveTo(pt(sd * 0.325, 0.830).dx, pt(sd * 0.325, 0.830).dy)
        ..quadraticBezierTo(pt(sd * 0.42, 0.80).dx, pt(sd * 0.42, 0.80).dy,
            pt(sd * 0.50, 0.775).dx, pt(sd * 0.50, 0.775).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.010
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.07 : 0.05),
    );
    canvas.drawPath(
      Path()
        ..moveTo(pt(sd * 0.335, 0.837).dx, pt(sd * 0.335, 0.837).dy)
        ..quadraticBezierTo(pt(sd * 0.45, 0.842).dx, pt(sd * 0.45, 0.842).dy,
            pt(sd * 0.53, 0.848).dx, pt(sd * 0.53, 0.848).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.009
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: 0.05),
    );
    canvas.drawPath(
      Path()
        ..moveTo(pt(sd * 0.325, 0.843).dx, pt(sd * 0.325, 0.843).dy)
        ..quadraticBezierTo(pt(sd * 0.40, 0.875).dx, pt(sd * 0.40, 0.875).dy,
            pt(sd * 0.435, 0.898).dx, pt(sd * 0.435, 0.898).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.009
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: 0.06),
    );
    // ── NASOLABIAL SUPPORT PLANE — broad and soft (a young face: NO fold)
    _plane(
        canvas,
        _quad([pt(sd * 0.155, 0.756), pt(sd * 0.30, 0.768),
            pt(sd * 0.345, 0.826), pt(sd * 0.17, 0.815)]),
        pt(sd * 0.17, 0.77), pt(sd * 0.36, 0.822),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.07 : 0.04),
        HeroLook.skinLit.withValues(alpha: 0.0));
  }

  // ── LABIOMENTAL S-TURN — a soft counter-light below the shallow fold: the
  //    mental plane's top catching the key (a turn, never a cut)
  _plane(
      canvas,
      _quad([pt(-0.115, 0.879), pt(0.105, 0.879), pt(0.095, 0.890), pt(-0.105, 0.890)]),
      pt(-0.005, 0.8795), pt(-0.005, 0.891),
      HeroLook.skinLit.withValues(alpha: 0.08),
      HeroLook.skinLit.withValues(alpha: 0.0));

  // ── PERIORAL SUPPORT — the gentlest broad lift framing the whole mouth
  _plane(
      canvas,
      _quad([pt(-0.30, 0.796), pt(0.29, 0.796), pt(0.27, 0.872), pt(-0.28, 0.872)]),
      pt(-0.005, 0.80), pt(-0.005, 0.874),
      HeroLook.skinLit.withValues(alpha: 0.04),
      HeroLook.skinLit.withValues(alpha: 0.0));

  canvas.restore();
}

// ── PHASE 2.5A — FACIAL SOFT TISSUE FOUNDATION ──────────────────────────────
// The living layer over the locked skull: the natural INFLUENCE of the malar
// and medial cheek fat, infraorbital continuity, buccal restraint, perioral
// and chin support — all whisper-level, broad, bounded. Different regions
// carry different tension (forehead medium, cheeks soft, perioral higher,
// jaw firm). Nothing exposed, no pockets, no texture: only soft volume.
void _drawSoftTissue(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  Offset pt(double fx, double fy) => Offset(c.dx + hw * fx, y(fy));
  canvas.save();
  canvas.clipPath(_headPath(c, hw, hh));

  // ── GLOBAL TISSUE UNIFIER — one broad, barely-there warmth over the whole
  //    midface: ties every region into a single living surface
  canvas.drawCircle(
    pt(-0.02, 0.62),
    hw * 0.95,
    Paint()
      ..shader = ui.Gradient.radial(
        pt(-0.06, 0.60),
        hw * 0.95,
        [
          HeroLook.skinLit.withValues(alpha: 0.05),
          HeroLook.skinLit.withValues(alpha: 0.0),
        ],
      ),
  );

  for (final sd in [-1.0, 1.0]) {
    // ── MALAR SOFT VOLUME — youthful (restrained) support over the
    //    cheekbone flowing to the midcheek: soft tension zone
    _plane(
        canvas,
        _quad([pt(sd * 0.21, 0.605), pt(sd * 0.60, 0.615),
            pt(sd * 0.52, 0.735), pt(sd * 0.20, 0.72)]),
        pt(sd * 0.30, 0.63), pt(sd * 0.42, 0.735),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.08 : 0.05),
        HeroLook.skinLit.withValues(alpha: 0.0));
    // ── MEDIAL CHEEK — the tissue beside the nose (nasolabial support from
    //    above): a gentle plane, never a fold
    _plane(
        canvas,
        _quad([pt(sd * 0.135, 0.645), pt(sd * 0.29, 0.655),
            pt(sd * 0.26, 0.775), pt(sd * 0.13, 0.765)]),
        pt(sd * 0.15, 0.66), pt(sd * 0.27, 0.77),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.06 : 0.04),
        HeroLook.skinLit.withValues(alpha: 0.0));
    // ── INFRAORBITAL CONTINUITY — lid → infraorbital → cheek in one flow
    //    (kills any residual step; no trough, no bag)
    _plane(
        canvas,
        _quad([pt(sd * 0.20, 0.578), pt(sd * 0.50, 0.572),
            pt(sd * 0.47, 0.625), pt(sd * 0.21, 0.632)]),
        pt(sd * 0.33, 0.577), pt(sd * 0.34, 0.632),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.07 : 0.05),
        HeroLook.skinLit.withValues(alpha: 0.0));
    // ── BUCCAL RESTRAINT / FIRM JAW ZONE — the lateral lower cheek turns
    //    with quiet firmness into the jaw (never a hollow)
    _plane(
        canvas,
        _quad([pt(sd * 0.50, 0.72), pt(sd * 0.68, 0.715),
            pt(sd * 0.60, 0.845), pt(sd * 0.44, 0.84)]),
        pt(sd * 0.50, 0.76), pt(sd * 0.70, 0.79),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.08 : 0.06));
    // ── CHIN TISSUE BLEND — the mental region melts into the jaw sides
    //    (no puppet chin, no isolation)
    _plane(
        canvas,
        _quad([pt(sd * 0.15, 0.895), pt(sd * 0.33, 0.885),
            pt(sd * 0.28, 0.955), pt(sd * 0.13, 0.96)]),
        pt(sd * 0.16, 0.905), pt(sd * 0.33, 0.945),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.05 : 0.03),
        HeroLook.skinLit.withValues(alpha: 0.0));
  }

  // ═══ PHASE 2.5B — SOFT TISSUE REFINEMENT & INTEGRATION ═══
  // One continuous living face: whisper-level flows dissolving every residual
  // boundary between regions. No proportions touched, no new anatomy.

  for (final sd in [-1.0, 1.0]) {
    // ── TEMPLE → ORBIT FLOW — the lateral forehead melts into the orbital
    //    region with no interruption
    _plane(
        canvas,
        _quad([pt(sd * 0.56, 0.495), pt(sd * 0.80, 0.505),
            pt(sd * 0.74, 0.585), pt(sd * 0.52, 0.575)]),
        pt(sd * 0.56, 0.52), pt(sd * 0.80, 0.565),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.04 : 0.03),
        HeroLook.skinLit.withValues(alpha: 0.0));
    // ── UNDER-EYE NEAR-INVISIBLE BLEND — the last whisper flattening the
    //    lid→cheek transition (no trough, no bag, no step)
    _plane(
        canvas,
        _quad([pt(sd * 0.22, 0.566), pt(sd * 0.48, 0.560),
            pt(sd * 0.46, 0.602), pt(sd * 0.23, 0.607)]),
        pt(sd * 0.34, 0.564), pt(sd * 0.34, 0.606),
        HeroLook.skinLit.withValues(alpha: 0.05),
        HeroLook.skinLit.withValues(alpha: 0.0));
    // ── NASAL EMBED — side wall → cheek → upper-lip in one soft triangle,
    //    so the nose sits IN the face, not on it
    _plane(
        canvas,
        _quad([pt(sd * 0.10, 0.625), pt(sd * 0.215, 0.645),
            pt(sd * 0.19, 0.785), pt(sd * 0.085, 0.775)]),
        pt(sd * 0.10, 0.66), pt(sd * 0.225, 0.77),
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.045 : 0.03),
        HeroLook.skinLit.withValues(alpha: 0.0));
    // ── PERIORAL BLEND — the mouth complex releases into the surrounding
    //    tissue on both flanks (no mask, no isolated lips)
    _plane(
        canvas,
        _quad([pt(sd * 0.245, 0.798), pt(sd * 0.365, 0.805),
            pt(sd * 0.345, 0.862), pt(sd * 0.235, 0.856)]),
        pt(sd * 0.25, 0.828), pt(sd * 0.375, 0.832),
        HeroLook.skinLit.withValues(alpha: 0.04),
        HeroLook.skinLit.withValues(alpha: 0.0));
    // ── MASSETER / JAW INTEGRATION — one long firm flow: cheek → masseter →
    //    jaw → chin (a single anatomical surface)
    _plane(
        canvas,
        _quad([pt(sd * 0.56, 0.675), pt(sd * 0.78, 0.665),
            pt(sd * 0.62, 0.862), pt(sd * 0.46, 0.868)]),
        pt(sd * 0.55, 0.73), pt(sd * 0.78, 0.80),
        HeroLook.skinShadow.withValues(alpha: 0.0),
        HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.07 : 0.05));
  }

  // ── LOWER-FACE UNIFIER — a barely-there vertical warmth tying the
  //    perioral region into the chin (one tissue, one face)
  _plane(
      canvas,
      _quad([pt(-0.26, 0.79), pt(0.25, 0.79), pt(0.22, 0.965), pt(-0.23, 0.965)]),
      pt(-0.005, 0.80), pt(-0.005, 0.968),
      HeroLook.skinLit.withValues(alpha: 0.035),
      HeroLook.skinLit.withValues(alpha: 0.0));

  canvas.restore();
}

// ── PHASE 2.6A — EAR FOUNDATION ─────────────────────────────────────────────
// The primary external-ear MASS only: one continuous anatomical shell per
// side, growing out of the temporal region. Placement brow-line → nose-base;
// the long axis leans back ~17 deg (the upper shell follows the skull's
// curvature); subtle natural projection. NO helix/antihelix/concha/tragus/
// lobe detail — that is later anatomy. One volume, one light response.
void _drawEarFoundation(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  for (final sd in [-1.0, 1.0]) {
    double x(double fx) => c.dx + sd * hw * fx;
    // the shell: attachment (on the silhouette) → up-and-back top → the
    // widest point high (backward lean) → tapering to the soft lobe base
    final shell = Path()
      ..moveTo(x(0.875), y(0.508)) // upper attachment, on the temporal edge
      ..cubicTo(x(0.955), y(0.492), x(1.03), y(0.518), x(1.043), y(0.578))
      ..cubicTo(x(1.052), y(0.632), x(1.02), y(0.688), x(0.972), y(0.724))
      ..cubicTo(x(0.945), y(0.745), x(0.902), y(0.752), x(0.878), y(0.738))
      // back up the attachment line, hugging the head's edge
      ..cubicTo(x(0.856), y(0.70), x(0.856), y(0.60), x(0.875), y(0.508))
      ..close();
    canvas.drawPath(shell, Paint()..color = HeroLook.skinMid);

    // ONE volume, one light response: the key (left) ear catches light on its
    // outer shell; the fill (right) ear turns into shadow — a single linear
    // reaction, no internal depth faking
    canvas.save();
    canvas.clipPath(shell);
    canvas.drawRect(
      Rect.fromLTRB(x(0.84), y(0.48), x(1.07), y(0.76)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x(0.87), y(0.60)),
          Offset(x(1.05), y(0.62)),
          sd < 0
              ? [
                  HeroLook.skinShadow.withValues(alpha: 0.35),
                  HeroLook.skinLit.withValues(alpha: 0.18),
                ]
              : [
                  HeroLook.skinShadow.withValues(alpha: 0.42),
                  HeroLook.skinShadow.withValues(alpha: 0.12),
                ],
        ),
    );
    // the attachment seat — the shell grows from the skull (a soft inner
    // shadow along the head edge, ambient occlusion of the join)
    canvas.drawRect(
      Rect.fromLTRB(x(0.84), y(0.48), x(0.92), y(0.76)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x(0.862), y(0.62)),
          Offset(x(0.92), y(0.62)),
          [
            HeroLook.skinDeep.withValues(alpha: 0.23),
            HeroLook.skinDeep.withValues(alpha: 0.0),
          ],
        ),
    );

    // ═══ PHASE 2.6B — PRIMARY INTERNAL ANATOMY (simplified, broad, clean) ═══

    // ── HELIX — one continuous outer rim of even thickness: a lit band
    //    riding just inside the shell's outer contour, top → outer → lobe
    final helix = Path()
      ..moveTo(x(0.895), y(0.516))
      ..cubicTo(x(0.968), y(0.5035), x(1.025), y(0.534), x(1.0285), y(0.5805))
      ..cubicTo(x(1.0325), y(0.633), x(1.002), y(0.6805), x(0.962), y(0.712));
    canvas.drawPath(
      helix,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.020
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.27 : 0.15),
    );
    // the scapha turn just inside the rim — depth from the plane change
    canvas.drawPath(
      Path()
        ..moveTo(x(0.905), y(0.535))
        ..cubicTo(x(0.968), y(0.53), x(1.002), y(0.556), x(1.006), y(0.596))
        ..cubicTo(x(1.008), y(0.634), x(0.985), y(0.672), x(0.952), y(0.698)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.013
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.30 : 0.24),
    );

    // ── ANTIHELIX — a soft, broad Y-ridge supporting the mid ear
    canvas.drawPath(
      Path()
        ..moveTo(x(0.912), y(0.558))
        ..quadraticBezierTo(x(0.945), y(0.60), x(0.942), y(0.645))
        ..quadraticBezierTo(x(0.938), y(0.675), x(0.918), y(0.694)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.015
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.22 : 0.12),
    );
    // the upper fork of the Y — barely suggested
    canvas.drawPath(
      Path()
        ..moveTo(x(0.912), y(0.558))
        ..quadraticBezierTo(x(0.898), y(0.545), x(0.888), y(0.532)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.011
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.14 : 0.08),
    );

    // ── CONCHA — ONE shallow bowl (volume indicated, never a cavity)
    _plane(
        canvas,
        Path()
          ..addOval(Rect.fromCenter(
              center: Offset(x(0.897), y(0.638)),
              width: hw * 0.052,
              height: hh * 0.062)),
        Offset(x(0.885), y(0.625)), Offset(x(0.915), y(0.655)),
        HeroLook.skinDeep.withValues(alpha: sd > 0 ? 0.26 : 0.21),
        HeroLook.skinDeep.withValues(alpha: 0.03));

    // ── TRAGUS — small, rounded, subtle (at the front edge, near the face)
    _blob(canvas, Offset(x(0.876), y(0.636)), hw * 0.013, hh * 0.016,
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.26 : 0.15), hw * 0.006);
    // ── ANTITRAGUS — only lightly suggested, smaller than the tragus
    _blob(canvas, Offset(x(0.908), y(0.702)), hw * 0.010, hh * 0.011,
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.13 : 0.08), hw * 0.006);

    // ── EARLOBE — soft, compact, youthful: a gentle rounding at the base
    _blob(canvas, Offset(x(0.918), y(0.726)), hw * 0.024, hh * 0.020,
        HeroLook.skinLit.withValues(alpha: sd < 0 ? 0.20 : 0.11), hw * 0.012);

    canvas.restore();

    // a whisper of the same seat ON the head, just inside the silhouette —
    // the temporal skin acknowledging the ear (integration, not glue)
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + sd * hw * 0.872, y(0.52))
        ..quadraticBezierTo(c.dx + sd * hw * 0.885, y(0.62),
            c.dx + sd * hw * 0.868, y(0.725)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.020
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.13 : 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.015),
    );
    // mastoid continuation — the ear root flows on toward the jaw line
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + sd * hw * 0.868, y(0.725))
        ..quadraticBezierTo(c.dx + sd * hw * 0.845, y(0.77),
            c.dx + sd * hw * 0.80, y(0.80)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.016
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: sd > 0 ? 0.09 : 0.07)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.014),
    );
  }
}

// ── PHASE 2.7A — HAIRLINE & PRIMARY HAIR MASS ───────────────────────────────
// Hair begins with silhouette: ONE continuous sculptural volume over the
// locked skull. The outer contour carries gentle broad lobes (the ENERGY of
// thick curly hair lives in the silhouette rhythm, never in drawn curls).
// The hairline is youthful and organic: subtly asymmetric (1-2%), extremely
// slight temporal recession, the forehead open. No strands, no texture.
// ── MASTER HAIR — SCULPTED SILHOUETTE ───────────────────────────────────────
// One continuous crafted contour (no path unions — total silhouette
// control). Edge rhythm lives in the anchor spacing: LONG crown segments
// carry the major lobes, medium front-top segments the secondary rhythm,
// short side segments the minor beat. The hairline cubics are the locked
// organic 2.7A line (1-2% asymmetric, temples open).
void _curlEdge(Path p, List<Offset> pts, List<double> bulge) {
  for (var i = 0; i < pts.length - 1; i++) {
    final a = pts[i], b = pts[i + 1];
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final k = bulge[i % bulge.length] * len;
    p.quadraticBezierTo((a.dx + b.dx) / 2 + dy / len * k,
        (a.dy + b.dy) / 2 - dx / len * k, b.dx, b.dy);
  }
}

Path _hairMassPath(Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  double px(double fx) => c.dx + hw * fx;
  final p = Path()..moveTo(px(-0.815), y(0.515));
  _curlEdge(p, [
    // left side — descends to the ear top, short segments, minor rhythm
    Offset(px(-0.815), y(0.515)),
    Offset(px(-0.865), y(0.45)),
    Offset(px(-0.898), y(0.375)),
    Offset(px(-0.918), y(0.29)),
    Offset(px(-0.928), y(0.20)),
    Offset(px(-0.908), y(0.105)),
    Offset(px(-0.848), y(0.018)),
    // crown — LONG segments, the major lobes (left of centre dominant)
    Offset(px(-0.70), y(-0.075)),
    Offset(px(-0.48), y(-0.140)),
    Offset(px(-0.21), y(-0.163)),
    Offset(px(0.06), y(-0.155)),
    Offset(px(0.32), y(-0.125)),
    // front-right descent — medium segments, secondary rhythm
    Offset(px(0.545), y(-0.078)),
    Offset(px(0.72), y(-0.005)),
    // right side — down to the ear top (slightly tighter than the left)
    Offset(px(0.845), y(0.085)),
    Offset(px(0.898), y(0.185)),
    Offset(px(0.912), y(0.285)),
    Offset(px(0.895), y(0.385)),
    Offset(px(0.858), y(0.465)),
    Offset(px(0.826), y(0.52)),
  ], const [
    0.25, 0.28, 0.25, 0.29, 0.27, 0.31, // left side
    0.33, 0.31, 0.34, 0.32, 0.30, // crown majors
    0.30, 0.28, // front-right
    0.27, 0.24, 0.28, 0.25, 0.26, 0.20, // right side
  ]);
  p
    ..cubicTo(px(0.802), y(0.478), px(0.768), y(0.425), px(0.692), y(0.366))
    ..cubicTo(px(0.638), y(0.335), px(0.56), y(0.32), px(0.448), y(0.3145))
    ..cubicTo(px(0.352), y(0.304), px(0.24), y(0.2975), px(0.115), y(0.2965))
    ..cubicTo(px(0.02), y(0.2955), px(-0.085), y(0.297), px(-0.20), y(0.3005))
    ..cubicTo(
        px(-0.312), y(0.304), px(-0.408), y(0.3125), px(-0.492), y(0.3255))
    ..cubicTo(px(-0.578), y(0.339), px(-0.652), y(0.362), px(-0.708), y(0.394))
    ..cubicTo(px(-0.755), y(0.428), px(-0.79), y(0.468), px(-0.815), y(0.515))
    ..close();
  return p;
}

// The back-of-head volume: what shows past the skull's edges in front view
// (behind the temples and above/behind the ears). Painted BEFORE the head so
// the skull overlaps it — integration by construction.
Path _hairBackPath(Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  double px(double fx) => c.dx + hw * fx;
  return Path()
    ..moveTo(px(0.0), y(0.064))
    ..cubicTo(px(0.52), y(0.068), px(0.925), y(0.162), px(0.982), y(0.335))
    ..cubicTo(px(0.988), y(0.468), px(0.62), y(0.612), px(0.05), y(0.618))
    ..cubicTo(px(-0.55), y(0.626), px(-0.952), y(0.488), px(-0.976), y(0.352))
    ..cubicTo(px(-0.994), y(0.198), px(-0.55), y(0.06), px(0.0), y(0.064))
    ..close();
}

void _drawHairBack(Canvas canvas, Offset c, double hw, double hh) {
  final back = _hairBackPath(c, hw, hh);
  canvas.drawPath(back, Paint()..color = HeroLook.hairDeep);
  // one quiet vertical response: the underside of the back mass sits deeper
  canvas.save();
  canvas.clipPath(back);
  canvas.drawRect(
    Rect.fromCenter(
        center: Offset(c.dx, _y(c, hh, 0.40)),
        width: hw * 2.2,
        height: hh * 0.72),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(c.dx, _y(c, hh, 0.12)),
        Offset(c.dx, _y(c, hh, 0.66)),
        [
          HeroLook.hairDeep.withValues(alpha: 0.0),
          const Color(0xFF140D08).withValues(alpha: 0.55),
        ],
      ),
  );
  canvas.restore();
}

void _drawHairFoundation(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  double px(double fx) => c.dx + hw * fx;

  // the under-mass: everything dark that shows through the ringlet holes
  final mass = _hairMassPath(c, hw, hh);
  canvas.drawPath(
    mass,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(c.dx, y(-0.17)),
        Offset(c.dx, y(0.52)),
        [const Color(0xFF2A1D12), const Color(0xFF17100A)],
      ),
  );

  // soft AO the curls cast on the forehead
  canvas.drawPath(
    Path()
      ..moveTo(px(-0.68), y(0.40))
      ..quadraticBezierTo(px(-0.30), y(0.33), px(-0.01), y(0.335))
      ..quadraticBezierTo(px(0.27), y(0.33), px(0.58), y(0.37)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = hw * 0.05
      ..color = HeroLook.skinShadow.withValues(alpha: 0.20)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.025),
  );

  // ── THE RINGLET FIELD — every curl is an OPEN RING: dark inner hole,
  //    rolled body, lit top rim; the opening faces down-flow (away from
  //    the crown whorl). Rows paint top→down so lower curls overlap.
  final whorl = Offset(px(-0.08), y(0.02));

  void ringlet(Offset ctr, double r, double openAng, double tone,
      {bool hole = true}) {
    final rect =
        Rect.fromCircle(center: ctr, radius: hole ? r * 0.52 : r * 0.40);
    final ringW = hole ? r * 0.64 : r * 0.88;
    final start = openAng + 0.48;
    const sweep = 2 * math.pi - 0.96;
    // seat shadow — the ring presses into the mass behind it
    canvas.drawPath(
      Path()..addArc(rect.shift(Offset(r * 0.07, r * 0.11)), start, sweep),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = ringW * 1.18
        ..color = const Color(0xFF110B07).withValues(alpha: 0.50)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.10),
    );
    // the rolled body
    canvas.drawPath(
      Path()..addArc(rect, start, sweep),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = ringW
        ..color =
            Color.lerp(const Color(0xFF251A10), const Color(0xFF3D2C1C), tone)!,
    );
    // lit rim — the top-left of the roll catches the key
    canvas.drawPath(
      Path()
        ..addArc(
            Rect.fromCircle(
                center: ctr.translate(-r * 0.05, -r * 0.08),
                radius: r * 0.52),
            -2.75,
            1.45),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = ringW * 0.44
        ..color = Color.lerp(
                const Color(0xFF42301F), const Color(0xFF6E5438), tone)!
            .withValues(alpha: 0.82)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.06),
    );
  }

  var idx = 0;
  for (var row = 0; row < 12; row++) {
    final fy = -0.14 + row * 0.058;
    final xOff = row.isOdd ? 0.058 : 0.0;
    for (var col = 0; col < 19; col++) {
      final fx = -1.04 + xOff + col * 0.116;
      idx++;
      final jx = math.sin(idx * 12.9898) * 0.022;
      final jy = math.sin(idx * 78.233) * 0.017;
      final pnt = Offset(px(fx + jx), y(fy + jy));
      if (!mass.contains(pnt)) continue;
      // big curls ride the crown, smaller ones the sides and hairline
      final sizeBase =
          0.172 - row * 0.0055 - (fx.abs() > 0.68 ? 0.026 : 0.0);
      final r = hw * (sizeBase + math.sin(idx * 3.7) * 0.014);
      final v = pnt - whorl;
      final flow = math.atan2(v.dy, v.dx) + math.sin(idx * 5.3) * 0.38;
      // tone: crown bright → hairline/sides deep, always jittered
      var tone = 0.98 - row * 0.058 - (fx.abs() > 0.68 ? 0.13 : 0.0);
      tone = (tone + math.sin(idx * 2.3) * 0.10).clamp(0.15, 1.0);
      ringlet(pnt, r, flow, tone, hole: idx % 3 == 0);
    }
  }
}

// ═════════════════════════ PHASE 2.2 — FACIAL FEATURES ═════════════════════
// Premium features on the LOCKED anatomy. Micro-asymmetry throughout (0.5–1%):
// the left eye sits a hair higher, the brows arc differently, the left mouth
// corner rests a touch up. Everything is pose-driven (blink/gaze/visemes).

// ── EARS — simplified but anatomical: helix, antihelix hint, tragus, lobule.
//    Seated on the ear-attachment plane (brow line → nose line). ──
void _drawEars(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  for (final s in [-1.0, 1.0]) {
    final ex = c.dx + s * hw * 0.925;
    final top = y(0.545);
    final bot = y(0.735);
    final eh2 = (bot - top) / 2;
    final ec = Offset(ex, (top + bot) / 2);
    // helix — the outer shell
    final ear = Path()
      ..moveTo(ec.dx - s * hw * 0.045, top + eh2 * 0.25)
      ..cubicTo(ec.dx + s * hw * 0.02, top - eh2 * 0.10, ec.dx + s * hw * 0.115,
          top + eh2 * 0.18, ec.dx + s * hw * 0.115, ec.dy)
      ..cubicTo(ec.dx + s * hw * 0.115, ec.dy + eh2 * 0.62, ec.dx + s * hw * 0.05,
          bot - eh2 * 0.18, ec.dx - s * hw * 0.01, bot)
      ..cubicTo(ec.dx - s * hw * 0.05, bot + eh2 * 0.06, ec.dx - s * hw * 0.06,
          bot - eh2 * 0.3, ec.dx - s * hw * 0.055, ec.dy + eh2 * 0.2)
      ..close();
    canvas.drawPath(ear, Paint()..color = HeroLook.skinMid);
    canvas.save();
    canvas.clipPath(ear);
    // form: lit toward the key, shadowed into the head
    canvas.drawRect(
      Rect.fromCenter(center: ec, width: hw * 0.4, height: eh2 * 3),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(ec.dx - s * hw * 0.06, ec.dy),
          Offset(ec.dx + s * hw * 0.12, ec.dy),
          [
            HeroLook.skinShadow.withValues(alpha: 0.55),
            HeroLook.skinBase.withValues(alpha: s < 0 ? 0.4 : 0.0),
          ],
        ),
    );
    // concha bowl shadow + antihelix ridge light + tragus notch
    _blob(canvas, Offset(ec.dx + s * hw * 0.005, ec.dy + eh2 * 0.1),
        hw * 0.038, eh2 * 0.42, HeroLook.skinDeep.withValues(alpha: 0.5),
        hw * 0.025);
    canvas.drawPath(
      Path()
        ..moveTo(ec.dx + s * hw * 0.02, top + eh2 * 0.38)
        ..quadraticBezierTo(ec.dx + s * hw * 0.075, ec.dy - eh2 * 0.1,
            ec.dx + s * hw * 0.045, ec.dy + eh2 * 0.55),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.022
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: s < 0 ? 0.45 : 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.014),
    );
    _blob(canvas, Offset(ec.dx - s * hw * 0.035, ec.dy + eh2 * 0.05),
        hw * 0.022, eh2 * 0.14, HeroLook.skinShadow.withValues(alpha: 0.5),
        hw * 0.014);
    canvas.restore();
    // lobule light — the soft bottom
    _blob(canvas, Offset(ec.dx + s * hw * 0.01, bot - eh2 * 0.16), hw * 0.04,
        eh2 * 0.16, HeroLook.skinLit.withValues(alpha: s < 0 ? 0.3 : 0.15),
        hw * 0.02);
  }
}

// ── PHASE 2.2C — EYEBROWS ───────────────────────────────────────────────────
// Production brows for a 22-26yo professional male. The mass rides the LOCKED
// brow ridge (never floating, never touching the lids): near-straight start
// (~10 deg), highest point above the OUTER IRIS (~18 deg rise), a tail that
// thins gradually and never snaps off. Volume, not paint: the body is one
// bounded shape whose upper edge catches light, middle stays densest, lower
// edge holds a fine shadow; a sparse fan of individual hair strokes turns
// from upward (head) through diagonal (body) to horizontal (tail). L/R differ
// under 1% (left arcs a hair higher, right runs a hair thicker). Pose-driven:
// browRaise lifts, browFurrow pulls the heads down-and-in.
void _drawBrows(Canvas canvas, Offset c, double hw, double hh, HeroPose p) {
  double y(double f) => _y(c, hh, f);

  for (final s in [-1.0, 1.0]) {
    final raise = p.browRaise * 0.030;
    final furrow = p.browFurrow;
    // micro-asymmetry: left peak a hair higher, right body a hair thicker
    final peakLift = s < 0 ? 0.002 : 0.0;
    final thick = s > 0 ? 1.06 : 1.0;

    // spine stations (x in hw, y in crown-chin fraction)
    final xs = [0.155, 0.30, 0.45, 0.615];
    final ys = [
      0.4800 + furrow * 0.012 - raise,
      0.4680 - raise * 1.05,
      0.4615 - raise * 1.10 - peakLift,
      0.4685 - raise * 0.90,
    ];
    final ts = [0.019, 0.0265, 0.0275 * thick, 0.010]; // half-thickness (hh)
    Offset spine(int i) => Offset(
        c.dx + s * hw * (xs[i] + (i == 0 ? furrow * -0.018 * 1 : 0)),
        y(ys[i]));

    final p0 = spine(0), p1 = spine(1), p2 = spine(2), p3 = spine(3);

    // body: upper edge out (spine - t), lower edge back (spine + t*0.85)
    Offset up(Offset o, double t) => Offset(o.dx, o.dy - hh * t);
    Offset dn(Offset o, double t) => Offset(o.dx, o.dy + hh * t * 0.85);
    final body = Path()
      ..moveTo(up(p0, ts[0]).dx, up(p0, ts[0]).dy)
      ..cubicTo(up(p1, ts[1]).dx, up(p1, ts[1]).dy, up(p2, ts[2]).dx,
          up(p2, ts[2]).dy, p3.dx, p3.dy - hh * ts[3])
      ..lineTo(p3.dx, p3.dy + hh * ts[3] * 0.9)
      ..cubicTo(dn(p2, ts[2]).dx, dn(p2, ts[2]).dy, dn(p1, ts[1]).dx,
          dn(p1, ts[1]).dy, dn(p0, ts[0]).dx, dn(p0, ts[0]).dy)
      ..close();
    canvas.drawPath(body, Paint()..color = HeroLook.brow);

    // volume light response — three edges, no blur:
    canvas.save();
    canvas.clipPath(body);
    // upper edge catches the key
    canvas.drawPath(
      Path()
        ..moveTo(up(p0, ts[0] * 0.9).dx, up(p0, ts[0] * 0.9).dy)
        ..cubicTo(up(p1, ts[1] * 0.92).dx, up(p1, ts[1] * 0.92).dy,
            up(p2, ts[2] * 0.92).dx, up(p2, ts[2] * 0.92).dy,
            p3.dx, p3.dy - hh * ts[3] * 0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.007
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF5C4529).withValues(alpha: s < 0 ? 0.60 : 0.45),
    );
    // lower edge holds a fine shadow (seats the brow onto the ridge)
    canvas.drawPath(
      Path()
        ..moveTo(dn(p0, ts[0] * 0.9).dx, dn(p0, ts[0] * 0.9).dy)
        ..cubicTo(dn(p1, ts[1] * 0.92).dx, dn(p1, ts[1] * 0.92).dy,
            dn(p2, ts[2] * 0.92).dx, dn(p2, ts[2] * 0.92).dy,
            p3.dx, p3.dy + hh * ts[3] * 0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.006
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF20150B).withValues(alpha: 0.55),
    );
    canvas.restore();

    // hair-flow fan — sparse, non-repeating: upward at the head, diagonal in
    // the body, horizontal at the tail; density thins toward the tip.
    for (var k = 0; k < 13; k++) {
      final u0 = 0.04 + k / 13.0 * 0.9;
      final u = (u0 + math.sin(k * 2.7) * 0.018).clamp(0.0, 1.0);
      // piecewise spine interpolation
      Offset lerpPt(Offset a, Offset b, double t) =>
          Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
      Offset pos;
      double baseT;
      if (u < 0.33) {
        pos = lerpPt(p0, p1, u / 0.33);
        baseT = ts[0] + (ts[1] - ts[0]) * (u / 0.33);
      } else if (u < 0.66) {
        pos = lerpPt(p1, p2, (u - 0.33) / 0.33);
        baseT = ts[1] + (ts[2] - ts[1]) * ((u - 0.33) / 0.33);
      } else {
        pos = lerpPt(p2, p3, (u - 0.66) / 0.34);
        baseT = ts[2] + (ts[3] - ts[2]) * ((u - 0.66) / 0.34);
      }
      // direction: head ~-75deg (upward), body ~-30deg, tail ~-6deg
      final angDeg = u < 0.3
          ? -75.0 + u * 90
          : (u < 0.7 ? -40.0 + (u - 0.3) * 55 : -12.0 + (u - 0.7) * 20);
      final ang = angDeg / 180 * math.pi;
      final len = hh * baseT * (1.5 + math.sin(k * 1.9) * 0.35);
      final w0 = hw * (0.0065 + (k % 3) * 0.0012);
      final from = Offset(pos.dx - s * math.cos(ang) * len * 0.2,
          pos.dy + hh * baseT * 0.55 - math.sin(-ang) * len * -0.2);
      final to = Offset(pos.dx + s * math.cos(ang) * len,
          pos.dy + hh * baseT * 0.55 + math.sin(ang) * len);
      canvas.drawLine(
        from,
        to,
        Paint()
          ..strokeWidth = w0
          ..strokeCap = StrokeCap.round
          ..color = (k.isEven ? HeroLook.brow : const Color(0xFF2A1C0E))
              .withValues(alpha: u > 0.8 ? 0.30 : 0.42),
      );
    }
  }
}

// ── PHASE 2.2B — EYES ───────────────────────────────────────────────────────
// Premium stylised-realistic eyes seated INSIDE the locked 2.2A sockets.
// The eyeball reads as a SPHERE under the lids: sclera is warm grey-white with
// corner falloff and an upper-lid cast shadow; the dark-green iris carries a
// quiet radial texture (never a plastic gradient); ONE catchlight upper-left.
// Upper lid dominant (covers ~15-20%) with a soft crease; lower lid a thin
// support. Fully pose-driven: blink, gaze, widen, smile-eyes. L/R differ <1%.
void _drawEyes(Canvas canvas, Offset c, double hw, double hh, HeroPose p) {
  final open = (1 - p.blink).clamp(0.0, 1.0);
  final widen = 1 + p.eyeWiden * 0.22;
  final smilePos = math.max(0.0, p.smile);

  canvas.save();
  canvas.clipPath(_headPath(c, hw, hh));

  for (final s in [-1.0, 1.0]) {
    // micro-asymmetry: the left eye rides 0.4% higher and a hair wider
    final lift = s < 0 ? 0.004 : 0.0;
    final asymW = s < 0 ? 1.006 : 1.0;
    final eyF = _fEye - lift;
    final ex = s * 0.36;
    final e = Offset(c.dx + hw * ex, _y(c, hh, eyF));
    final ew = hw * 0.24 * asymW; // half-width — reference-scale large eye
    var ehO = hh * 0.079 * widen * open; // opening half-height
    if (s < 0) ehO *= 1.005; // the left eye rests a whisper more open
    // upper-lid arc factors — the right lid curves a touch differently, and
    // the arc is lowered so the lid covers ~15-20% of the IRIS
    final upA = s < 0 ? 1.21 : 1.17;
    final upB = s < 0 ? 1.12 : 1.07;
    // corners follow the socket: inner (lacrimal) low, outer a touch high
    final inC = Offset(e.dx - s * ew, e.dy + hh * 0.010);
    final outC = Offset(e.dx + s * ew, e.dy - hh * 0.013);

    // tear duct — a tiny natural-pink wedge at the inner corner (always)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(inC.dx + s * ew * 0.035, inC.dy + hh * 0.002),
          width: ew * 0.11, height: hh * 0.017),
      Paint()..color = const Color(0xCCC98D80),
    );

    if (open < 0.10) {
      // blink: one calm closed line resting on the lower-lid arc
      canvas.drawPath(
        Path()
          ..moveTo(inC.dx, inC.dy + hh * 0.006)
          ..quadraticBezierTo(e.dx, e.dy + hh * 0.020, outC.dx, outC.dy + hh * 0.008),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hh * 0.012
          ..strokeCap = StrokeCap.round
          ..color = HeroLook.lash,
      );
      continue;
    }

    // the almond: upper arc dominant; the lower lid lifts softly on a smile
    final lowFall = 0.86 - smilePos * 0.22 + (s > 0 ? -0.015 : 0.0);
    final almond = Path()
      ..moveTo(inC.dx, inC.dy)
      ..cubicTo(e.dx - s * ew * 0.48, e.dy - ehO * upA,
          e.dx + s * ew * 0.52, e.dy - ehO * upB, outC.dx, outC.dy)
      ..cubicTo(e.dx + s * ew * 0.56, e.dy + ehO * lowFall,
          e.dx - s * ew * 0.40, e.dy + ehO * (lowFall + 0.10), inC.dx, inC.dy)
      ..close();

    // ── 1. SCLERA as a sphere: base + corner falloff + upper-lid cast shadow
    canvas.drawPath(almond, Paint()..color = HeroLook.sclera);
    canvas.save();
    canvas.clipPath(almond);
    canvas.drawRect(
      Rect.fromCenter(center: e, width: ew * 2.6, height: ehO * 4),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(e.dx - s * ew * 0.05, e.dy - ehO * 0.1),
          ew * 1.15,
          [
            HeroLook.sclera.withValues(alpha: 0.0),
            const Color(0x2E9A8B74), // corners roll away — the eyeball turns
          ],
          [0.55, 1.0],
        ),
    );
    // sclera tonal life — the upper sclera sits a whisper warmer/darker
    canvas.drawRect(
      Rect.fromCenter(center: e, width: ew * 2.4, height: ehO * 3.4),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(e.dx, e.dy - ehO),
          Offset(e.dx, e.dy + ehO * 0.4),
          [const Color(0x14A08868), const Color(0x00A08868)],
        ),
    );
    // a broad, faint sheen on the lower sclera — the sphere's curvature
    canvas.drawRect(
      Rect.fromCenter(center: e, width: ew * 2.4, height: ehO * 3.4),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(e.dx - s * ew * 0.28, e.dy + ehO * 0.42),
          ew * 0.62,
          [const Color(0x1AFFFFFF), const Color(0x00FFFFFF)],
        ),
    );
    // contact shadow — the fine line where the lid actually touches the sphere
    canvas.drawPath(
      Path()
        ..moveTo(inC.dx + s * ew * 0.05, inC.dy + hh * 0.006)
        ..cubicTo(e.dx - s * ew * 0.46, e.dy - ehO * upA + hh * 0.008,
            e.dx + s * ew * 0.50, e.dy - ehO * upB + hh * 0.008,
            outC.dx - s * ew * 0.02, outC.dy + hh * 0.006),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.005
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x33241505),
    );
    // the upper lid casts a soft shadow band onto the sphere
    _plane(
        canvas,
        Path()
          ..moveTo(inC.dx, inC.dy)
          ..cubicTo(e.dx - s * ew * 0.48, e.dy - ehO * upA,
              e.dx + s * ew * 0.52, e.dy - ehO * upB, outC.dx, outC.dy)
          ..lineTo(outC.dx, outC.dy + ehO * 0.55)
          ..cubicTo(e.dx + s * ew * 0.5, e.dy - ehO * 0.55,
              e.dx - s * ew * 0.45, e.dy - ehO * 0.62, inC.dx, inC.dy + ehO * 0.5)
          ..close(),
        Offset(e.dx, e.dy - ehO * 1.1), Offset(e.dx, e.dy - ehO * 0.2),
        const Color(0x4D6E5F4C), const Color(0x006E5F4C));

    // ── 2. IRIS — warm glossy brown, large (reference), following the gaze
    final ic = Offset(
        e.dx + p.gazeX * ew * 0.36 * s.sign * s.sign + p.gazeX * ew * 0.0,
        e.dy + p.gazeY * ehO * 0.45 - hh * 0.0075);
    final icx = Offset(e.dx + p.gazeX * ew * 0.36, ic.dy);
    final ir = hh * 0.093;
    // base disc — quiet, natural (low-contrast radial family)
    canvas.drawCircle(
      icx,
      ir,
      Paint()
        ..shader = ui.Gradient.radial(
          icx.translate(-ir * 0.12, -ir * 0.14),
          ir * 1.3,
          [HeroLook.iris, HeroLook.iris, HeroLook.irisDeep],
          [0.0, 0.45, 1.0],
        ),
    );
    // LAYER 2 — natural iris fibers: radial, varying thickness/length/tone,
    //    deterministic but never repeating (sin-jittered per index)
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: icx, radius: ir)));
    for (var k = 0; k < 18; k++) {
      final a = k * math.pi / 9 + s * 0.13 + math.sin(k * 3.1) * 0.09;
      final r0 = ir * (0.30 + 0.07 * math.sin(k * 1.7));
      final r1 = ir * (0.86 + 0.09 * math.sin(k * 2.3));
      final wv = ir * (0.045 + 0.040 * ((k * 7) % 5) / 5);
      final tone = k % 3;
      final col = tone == 0
          ? HeroLook.irisHi
          : (tone == 1 ? HeroLook.irisDeep : const Color(0xFF2A5531));
      canvas.drawLine(
        icx.translate(math.cos(a) * r0, math.sin(a) * r0),
        icx.translate(math.cos(a) * r1, math.sin(a) * r1),
        Paint()
          ..strokeWidth = wv
          ..strokeCap = StrokeCap.round
          ..color = col.withValues(alpha: 0.10 + 0.09 * ((k * 5) % 4) / 4),
      );
    }
    // LAYER 4 — tiny natural irregularities: a few short arcs, no geometry
    for (var k = 0; k < 5; k++) {
      final a = k * 1.256 + s * 0.4 + math.sin(k * 5.2) * 0.5;
      final rr = ir * (0.52 + 0.14 * math.sin(k * 2.9));
      canvas.drawArc(
        Rect.fromCircle(center: icx, radius: rr),
        a, 0.35 + 0.2 * math.sin(k * 1.3), false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ir * 0.05
          ..color = (k.isEven ? HeroLook.irisDeep : HeroLook.irisHi)
              .withValues(alpha: 0.12),
      );
    }
    canvas.restore();
    // LAYER 1 — limbal ring: subtle, deep green (never black), two soft passes
    canvas.drawCircle(
        icx,
        ir * 0.985,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ir * 0.09
          ..color = HeroLook.irisDeep.withValues(alpha: 0.55));
    canvas.drawCircle(
        icx,
        ir * 0.90,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ir * 0.07
          ..color = HeroLook.irisDeep.withValues(alpha: 0.22));
    // ── 3. PUPIL — perfectly black, centred
    final pr = ir * (0.40 + p.pupilDilate * 0.08);
    // LAYER 3 — a soft brighter ring hugging the pupil (two passes, no blur)
    canvas.drawCircle(
        icx,
        pr * 1.30,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ir * 0.085
          ..color = HeroLook.irisHi.withValues(alpha: 0.28));
    canvas.drawCircle(
        icx,
        pr * 1.16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ir * 0.06
          ..color = HeroLook.irisHi.withValues(alpha: 0.16));
    // PUPIL — perfect circle, deep black, crisp
    canvas.drawCircle(icx, pr, Paint()..color = HeroLook.pupil);
    // ── 4. ONE catchlight — upper-left, small, alive
    canvas.drawCircle(
      icx.translate(-ir * 0.30, -ir * 0.34),
      ir * 0.155,
      Paint()..color = const Color(0xF0FDF9F0),
    );
    // tiny secondary reflected light — opposite the key, very subtle
    canvas.drawCircle(
      icx.translate(ir * 0.34, ir * 0.30),
      ir * 0.07,
      Paint()..color = const Color(0x54FFFFFF),
    );
    // EYE MOISTURE — the thin tear-film: a fine light line riding the lower
    // lid's inner edge + a tiny glint at the iris's lower rim. Never glossy.
    canvas.drawPath(
      Path()
        ..moveTo(e.dx - s * ew * 0.52, e.dy + ehO * (lowFall - 0.06))
        ..quadraticBezierTo(e.dx + s * ew * 0.05, e.dy + ehO * (lowFall + 0.10),
            e.dx + s * ew * 0.55, e.dy + ehO * (lowFall - 0.14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.005
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x40FFFFFF),
    );
    canvas.drawCircle(
      icx.translate(-ir * 0.06, ir * 0.78),
      ir * 0.055,
      Paint()..color = const Color(0x38FFFFFF),
    );
    canvas.restore();

    // ── 5. UPPER LID — dominant: the lid line, a soft skin fold above it and
    //    the crease (covers ~15-20% of the eye)
    canvas.drawPath(
      Path()
        ..moveTo(inC.dx, inC.dy)
        ..cubicTo(e.dx - s * ew * 0.48, e.dy - ehO * upA,
            e.dx + s * ew * 0.52, e.dy - ehO * upB, outC.dx, outC.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.013
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.lash,
    );
    // the lid-margin ledge — a lit strip above the lash line that gives the
    // eyelid visible thickness (a plate wrapping the sphere, not a line)
    canvas.drawPath(
      Path()
        ..moveTo(inC.dx + s * ew * 0.06, inC.dy - hh * 0.008)
        ..cubicTo(e.dx - s * ew * 0.46, e.dy - ehO * upA - hh * 0.009,
            e.dx + s * ew * 0.50, e.dy - ehO * upB - hh * 0.009,
            outC.dx - s * ew * 0.02, outC.dy - hh * 0.007),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.0055
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: s < 0 ? 0.42 : 0.32),
    );
    // the lid plate thickens over the mid-arc, thinning to both corners
    canvas.drawPath(
      Path()
        ..moveTo(e.dx - s * ew * 0.52, e.dy - ehO * upA * 0.86 - hh * 0.008)
        ..quadraticBezierTo(e.dx + s * ew * 0.02, e.dy - ehO * upA - hh * 0.011,
            e.dx + s * ew * 0.55, e.dy - ehO * upB * 0.88 - hh * 0.008),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.010
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: s < 0 ? 0.42 : 0.32),
    );
    // outer-third lash weight — minimal, never heavy
    canvas.drawPath(
      Path()
        ..moveTo(e.dx + s * ew * 0.30, e.dy - ehO * 1.12)
        ..quadraticBezierTo(e.dx + s * ew * 0.72, e.dy - ehO * 0.72,
            outC.dx + s * ew * 0.02, outC.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.013
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.lash.withValues(alpha: 0.72),
    );
    // the lid crease — soft, above the lid line
    canvas.drawPath(
      Path()
        ..moveTo(e.dx - s * ew * 0.72, e.dy - ehO * 0.95 * open - hh * 0.014)
        ..cubicTo(e.dx - s * ew * 0.30, e.dy - ehO * 1.55 - hh * 0.006,
            e.dx + s * ew * 0.34, e.dy - ehO * 1.45 - hh * 0.006,
            e.dx + s * ew * 0.76, e.dy - ehO * 0.85 - hh * 0.010),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.009
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinShadow.withValues(alpha: 0.38),
    );

    // integration wedge — the crease dissolves up into the orbital shading
    _plane(
        canvas,
        Path()
          ..moveTo(e.dx - s * ew * 0.70, e.dy - ehO * 1.05 - hh * 0.006)
          ..cubicTo(e.dx - s * ew * 0.28, e.dy - ehO * 1.62,
              e.dx + s * ew * 0.34, e.dy - ehO * 1.52,
              e.dx + s * ew * 0.72, e.dy - ehO * 0.95 - hh * 0.004)
          ..lineTo(e.dx + s * ew * 0.70, e.dy - ehO * 1.9)
          ..lineTo(e.dx - s * ew * 0.68, e.dy - ehO * 2.0)
          ..close(),
        Offset(e.dx, e.dy - ehO * 1.5), Offset(e.dx, e.dy - ehO * 2.1),
        HeroLook.skinShadow.withValues(alpha: s > 0 ? 0.12 : 0.09),
        HeroLook.skinShadow.withValues(alpha: 0.0));

    // ── 6. LOWER LID — a whisper: faint lash hint + a thin light ledge
    canvas.drawPath(
      Path()
        ..moveTo(inC.dx + s * ew * 0.18, inC.dy + ehO * (lowFall + 0.06))
        ..quadraticBezierTo(e.dx + s * ew * 0.1, e.dy + ehO * (lowFall + 0.18),
            outC.dx - s * ew * 0.06, outC.dy + ehO * 0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.0065
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.lash.withValues(alpha: 0.22),
    );
    canvas.drawPath(
      Path()
        ..moveTo(inC.dx + s * ew * 0.22, inC.dy + ehO * (lowFall + 0.28))
        ..quadraticBezierTo(e.dx + s * ew * 0.08, e.dy + ehO * (lowFall + 0.45),
            outC.dx - s * ew * 0.08, outC.dy + ehO * 0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hh * 0.008
        ..strokeCap = StrokeCap.round
        ..color = HeroLook.skinLit.withValues(alpha: 0.30),
    );
  }

  canvas.restore();
}

// ── NOSE — stylised but anatomical: soft bridge flowing from the locked nasal
//    root, a small tip, natural nostrils. Never splits the face. ──
void _drawNose(Canvas canvas, Offset c, double hw, double hh, HeroPose p) {
  double y(double f) => _y(c, hh, f);
  final tip = Offset(c.dx + p.gazeX * hw * 0.008 - hw * 0.005, y(0.738));
  // bridge: one soft shadow down the fill side + a light down the key side —
  // continuing the Phase-2.1 nasal-root plane without a hard line
  canvas.drawPath(
    Path()
      ..moveTo(c.dx + hw * 0.055, y(0.615))
      ..quadraticBezierTo(c.dx + hw * 0.075, y(0.675), c.dx + hw * 0.07, y(0.715)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hw * 0.065
      ..strokeCap = StrokeCap.round
      ..color = HeroLook.skinShadow.withValues(alpha: 0.30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.045),
  );
  canvas.drawPath(
    Path()
      ..moveTo(c.dx - hw * 0.045, y(0.63))
      ..quadraticBezierTo(c.dx - hw * 0.055, y(0.68), c.dx - hw * 0.05, y(0.712)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hw * 0.055
      ..strokeCap = StrokeCap.round
      ..color = HeroLook.skinLit.withValues(alpha: 0.30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.04),
  );
  // the small tip — a clearly lit ball, still soft
  _blob(canvas, tip.translate(-hw * 0.018, -hh * 0.008), hw * 0.085, hh * 0.050,
      HeroLook.skinLit.withValues(alpha: 0.65), hw * 0.045);
  // alar wings — soft but present side masses
  for (final s in [-1.0, 1.0]) {
    _blob(canvas, Offset(c.dx + s * hw * 0.112, y(0.748)), hw * 0.048,
        hh * 0.027, HeroLook.skinMid.withValues(alpha: 0.8), hw * 0.026);
  }
  // nostrils — legible soft crescents, never holes
  for (final s in [-1.0, 1.0]) {
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(c.dx + s * hw * 0.070, y(0.7615)),
          width: hw * 0.055,
          height: hh * 0.018),
      Paint()
        ..color = HeroLook.skinDeep.withValues(alpha: 0.58)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.008),
    );
  }
  // under-tip shadow ties the nose to the philtrum plane
  _blob(canvas, Offset(c.dx, y(0.768)), hw * 0.11, hh * 0.020,
      HeroLook.skinShadow.withValues(alpha: 0.36), hw * 0.045);
}

// ── MOUTH — natural lips, lower fuller, soft cupid's bow, neutral-friendly.
//    Fully viseme-ready: mouthOpen/mouthWide/smile deform the same geometry. ──
void _drawMouth(Canvas canvas, Offset c, double hw, double hh, HeroPose p) {
  double y(double f) => _y(c, hh, f);
  final smilePos = math.max(0.0, p.smile);
  final my = y(0.843);
  final mw = hw * 0.355 * p.mouthWide * (1 + smilePos * 0.12);
  final open = p.mouthOpen * hh * 0.145;
  // corners: clearly lifted by a smile; the left corner rests a hair higher
  final cL = Offset(c.dx - mw,
      my - smilePos * hh * 0.055 - hh * 0.004 + math.max(0.0, -p.smile) * hh * 0.03);
  final cR = Offset(c.dx + mw,
      my - smilePos * hh * 0.048 + math.max(0.0, -p.smile) * hh * 0.03);

  // under-lip shadow — seats the mouth on the muzzle plane (always)
  _blob(canvas, Offset(c.dx, my + hh * 0.052 + open * 0.5), mw * 0.62,
      hh * 0.020, HeroLook.skinShadow.withValues(alpha: 0.30), hw * 0.05);

  if (open > hh * 0.012) {
    // ── open (viseme) state ──
    final seamY = my - open * 0.34;
    final inner = Path()
      ..moveTo(cL.dx, cL.dy)
      ..quadraticBezierTo(c.dx, seamY, cR.dx, cR.dy)
      ..quadraticBezierTo(c.dx, my + open, cL.dx, cL.dy)
      ..close();
    canvas.drawPath(inner, Paint()..color = HeroLook.mouthIn);
    // teeth — one warm-ivory band hanging from the upper lip (no per-tooth cuts)
    canvas.save();
    canvas.clipPath(inner);
    canvas.drawRect(
      Rect.fromLTRB(c.dx - mw * 0.8, seamY - hh * 0.002, c.dx + mw * 0.8,
          seamY + math.min(open * 0.42, hh * 0.045)),
      Paint()..color = HeroLook.teeth,
    );
    _blob(canvas, Offset(c.dx, seamY + hh * 0.04), mw * 0.75, hh * 0.012,
        const Color(0x2E5A3A34), hw * 0.02); // soft shadow under the teeth
    canvas.restore();
    // upper lip over the opening
    canvas.drawPath(
      Path()
        ..moveTo(cL.dx, cL.dy)
        ..cubicTo(c.dx - mw * 0.30, seamY - hh * 0.024, c.dx - mw * 0.06,
            seamY - hh * 0.028, c.dx, seamY - hh * 0.024)
        ..cubicTo(c.dx + mw * 0.06, seamY - hh * 0.028, c.dx + mw * 0.30,
            seamY - hh * 0.024, cR.dx, cR.dy)
        ..quadraticBezierTo(c.dx, seamY + hh * 0.004, cL.dx, cL.dy)
        ..close(),
      Paint()..color = HeroLook.lipUp,
    );
    // lower lip riding the jaw
    canvas.drawPath(
      Path()
        ..moveTo(cL.dx, cL.dy)
        ..quadraticBezierTo(c.dx, my + open * 0.99, cR.dx, cR.dy)
        ..cubicTo(c.dx + mw * 0.4, my + open + hh * 0.030, c.dx - mw * 0.4,
            my + open + hh * 0.030, cL.dx, cL.dy)
        ..close(),
      Paint()..color = HeroLook.lipLow,
    );
    return;
  }

  // ── closed, neutral-friendly state ──
  // upper lip: a legible soft plane with a gentle cupid's bow
  canvas.drawPath(
    Path()
      ..moveTo(cL.dx, cL.dy)
      ..cubicTo(c.dx - mw * 0.36, my - hh * 0.030 + smilePos * hh * 0.008,
          c.dx - mw * 0.11, my - hh * 0.037, c.dx - mw * 0.03, my - hh * 0.033)
      ..quadraticBezierTo(c.dx, my - hh * 0.030, c.dx + mw * 0.03, my - hh * 0.033)
      ..cubicTo(c.dx + mw * 0.11, my - hh * 0.037, c.dx + mw * 0.36,
          my - hh * 0.030 + smilePos * hh * 0.008, cR.dx, cR.dy)
      ..quadraticBezierTo(c.dx, my + hh * 0.005 + smilePos * hh * 0.005, cL.dx, cL.dy)
      ..close(),
    Paint()..color = HeroLook.lipUp,
  );
  // lower lip: clearly fuller, catching the key light
  canvas.drawPath(
    Path()
      ..moveTo(cL.dx, cL.dy)
      ..quadraticBezierTo(c.dx, my + hh * 0.006 + smilePos * hh * 0.005, cR.dx, cR.dy)
      ..cubicTo(c.dx + mw * 0.44, my + hh * 0.056, c.dx - mw * 0.44,
          my + hh * 0.056, cL.dx, cL.dy)
      ..close(),
    Paint()..color = HeroLook.lipLow,
  );
  _blob(canvas, Offset(c.dx - mw * 0.16, my + hh * 0.026), mw * 0.36,
      hh * 0.016, const Color(0x52F6D3B4), hw * 0.022); // lower-lip light
  // the lip seam — soft, never a hard cut
  canvas.drawPath(
    Path()
      ..moveTo(cL.dx + mw * 0.05, cL.dy)
      ..quadraticBezierTo(
          c.dx, my + smilePos * hh * 0.008, cR.dx - mw * 0.05, cR.dy),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hh * 0.010
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x968A5645),
  );
  // corner tucks — tiny, seat the mouth into the cheeks
  for (final corner in [cL, cR]) {
    _blob(canvas, corner.translate(0, hh * 0.002), hw * 0.018, hh * 0.010,
        HeroLook.skinDeep.withValues(alpha: 0.30), hw * 0.014);
  }
}

// ── construction overlay — validate the proportions by measurement ──────────
void _drawGuides(Canvas canvas, Offset c, double hw, double hh) {
  double y(double f) => _y(c, hh, f);
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = hw * 0.010
    ..color = HeroLook.guide.withValues(alpha: 0.50);
  final faint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = hw * 0.008
    ..color = HeroLook.guide.withValues(alpha: 0.26);
  final left = c.dx - hw * 1.2;
  final right = c.dx + hw * 1.2;

  canvas.drawLine(Offset(c.dx, y(-0.05)), Offset(c.dx, y(1.1)), faint); // axis
  for (final f in [_fHairline, _fBrow, _fNose, _fChin]) {
    canvas.drawLine(Offset(left, y(f)), Offset(right, y(f)), line); // thirds
  }
  for (final f in [_fEye, _fMouth]) {
    canvas.drawLine(Offset(left, y(f)), Offset(right, y(f)), faint);
  }
  final ey = y(_fEye);
  for (var k = 0; k <= 5; k++) {
    final x = c.dx + (-0.90 + k * 0.36) * hw;
    canvas.drawLine(Offset(x, ey - hh * 0.10), Offset(x, ey + hh * 0.10), faint);
  }
}

// ── helper: a soft feathered blob (form shading) ────────────────────────────
void _blob(Canvas canvas, Offset center, double rx, double ry, Color color,
    double blur) {
  canvas.drawOval(
    Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
    Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
  );
}
