import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'avatar_state.dart';
import 'photo_hero.dart';
import 'vector_hero.dart';

/// Drives the from-scratch [paintHero] character at 60 FPS from the live
/// conversation: builds a [HeroPose] every frame from `state`, `emotion` and
/// the voice `level`, so the hand-built hero blinks, glances, turns, reacts to
/// the learner's words, and lip-syncs to the AI's voice with syllable-shaped
/// visemes. Same (emotion, state, level, accent) contract as the rest of the
/// avatar stack.
class VectorHeroView extends StatefulWidget {
  const VectorHeroView({
    required this.outfit,
    required this.emotion,
    required this.state,
    required this.level,
    this.accent = const Color(0xFF6366F1),
    super.key,
  });

  final HeroOutfit outfit;
  final String emotion;
  final AvatarState state;
  final ValueListenable<double> level;
  final Color accent;

  @override
  State<VectorHeroView> createState() => _VectorHeroViewState();
}

/// Emotion → expression target (brow/eye/smile/head), eased at runtime.
@immutable
class _Emo {
  const _Emo({
    this.brow = 0.0,
    this.furrow = 0.0,
    this.widen = 0.0,
    this.smile = 0.25,
    this.pitch = 0.0,
    this.tilt = 0.0,
  });
  final double brow, furrow, widen, smile, pitch, tilt;

  static _Emo of(String e) => switch (e) {
    'happy' => const _Emo(brow: 0.35, widen: 0.15, smile: 0.9, pitch: -0.012),
    'proud' => const _Emo(brow: 0.28, smile: 0.7, pitch: -0.02),
    'encouraging' => const _Emo(brow: 0.45, widen: 0.2, smile: 0.75, tilt: 0.02),
    'surprised' => const _Emo(brow: 0.9, widen: 0.85, smile: 0.35, pitch: -0.03),
    'thinking' => const _Emo(brow: 0.05, furrow: 0.6, smile: 0.05),
    'curious' => const _Emo(brow: 0.6, widen: 0.45, smile: 0.4, tilt: -0.04),
    _ => const _Emo(),
  };

  static double _l(double a, double b, double t) => a + (b - a) * t;
  static _Emo lerp(_Emo a, _Emo b, double t) => _Emo(
    brow: _l(a.brow, b.brow, t),
    furrow: _l(a.furrow, b.furrow, t),
    widen: _l(a.widen, b.widen, t),
    smile: _l(a.smile, b.smile, t),
    pitch: _l(a.pitch, b.pitch, t),
    tilt: _l(a.tilt, b.tilt, t),
  );
}

const _positive = {'happy', 'proud', 'encouraging'};

class _VectorHeroViewState extends State<VectorHeroView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  final math.Random _rng = math.Random();

  Duration _last = Duration.zero;
  double _t = 0;

  // head turn / gaze
  double _yaw = 0, _yawTarget = 0, _pitch = 0, _pitchTarget = 0;
  double _gazeX = 0, _gazeXT = 0, _gazeY = 0, _gazeYT = 0;
  double _gazeIn = 1.2;

  // blink
  double _blink = 0, _blinkPhase = 0, _blinkIn = 2.2;
  bool _dblBlink = false;
  static const _blinkDur = 0.34;

  // mouth / viseme
  double _mouth = 0, _prevLevel = 0, _visW = 1.0, _visWT = 1.0;

  // nod
  double _nodAmp = 0, _nodT = 1;
  static const _nodDur = 0.5;

  double _lean = 0;
  double _pupil = 0; // quiet dilation while attending (Board F-18)
  _Emo _emo = const _Emo();
  AvatarState _lastState = AvatarState.idle;
  // The official key-visual art; while it loads (or if it ever fails) the
  // procedural hero paints as the fallback.
  PhotoHeroImages? _photo;

  double get _nod =>
      _nodT >= _nodDur ? 0 : _nodAmp * math.sin((_nodT / _nodDur) * math.pi);

  @override
  void initState() {
    super.initState();
    _lastState = widget.state;
    _emo = _Emo.of(widget.emotion);
    _ticker = createTicker(_tick)..start();
    _photo = PhotoHeroImages.cached; // preloaded at app start — instant
    if (_photo == null) {
      PhotoHeroImages.load(rootBundle).then((p) {
        if (mounted) setState(() => _photo = p);
      }).catchError((Object _) {});
    }
  }

  @override
  void didUpdateWidget(VectorHeroView old) {
    super.didUpdateWidget(old);
    if (old.emotion != widget.emotion && _positive.contains(widget.emotion)) {
      _startNod(0.9); // praise lands as an approving nod
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _startNod(double amp) {
    if (_nodT < _nodDur && _nodAmp >= amp) return;
    _nodAmp = amp;
    _nodT = 0;
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _t += dt;
    final s = widget.state;

    if (s != _lastState) {
      _lastState = s;
      _gazeIn = 0;
      if (s == AvatarState.listening) _startNod(0.6);
    }

    // Head + gaze target per state.
    _gazeIn -= dt;
    if (_gazeIn <= 0) {
      switch (s) {
        case AvatarState.listening:
          _gazeIn = 2.0 + _rng.nextDouble() * 2.4;
          _yawTarget = (_rng.nextDouble() * 2 - 1) * 0.03;
          _pitchTarget = 0.02;
          _gazeXT = (_rng.nextDouble() * 2 - 1) * 0.25;
          _gazeYT = 0.1 + (_rng.nextDouble() * 2 - 1) * 0.1;
        case AvatarState.thinking:
          _gazeIn = 0.9 + _rng.nextDouble() * 1.3;
          final dir = _rng.nextBool() ? 1.0 : -1.0;
          _yawTarget = dir * (0.08 + _rng.nextDouble() * 0.06);
          _pitchTarget = -0.04;
          _gazeXT = dir * 0.7;
          _gazeYT = -0.6;
        case AvatarState.idle || AvatarState.talking:
          _gazeIn = 1.4 + _rng.nextDouble() * 2.4;
          _yawTarget = (_rng.nextDouble() * 2 - 1) * 0.06;
          _pitchTarget = (_rng.nextDouble() * 2 - 1) * 0.025;
          _gazeXT = (_rng.nextDouble() * 2 - 1) * 0.4;
          _gazeYT = (_rng.nextDouble() * 2 - 1) * 0.3;
      }
    }
    final hEase = 1 - math.exp(-dt * 2.4);
    _yaw += (_yawTarget - _yaw) * hEase;
    _pitch += (_pitchTarget - _pitch) * hEase;
    final gEase = 1 - math.exp(-dt * 9);
    _gazeX += (_gazeXT - _gazeX) * gEase;
    _gazeY += (_gazeYT - _gazeY) * gEase;

    // Blink (occasionally doubled).
    if (_blinkPhase > 0) {
      _blinkPhase -= dt;
      // real blinks are asymmetric: snap shut, rest a beat, release slowly
      final p = (1 - _blinkPhase / _blinkDur).clamp(0.0, 1.0);
      if (p < 0.28) {
        final q = p / 0.28;
        _blink = q * q; // ~100ms accelerating close
      } else if (p < 0.40) {
        _blink = 1.0; // ~40ms fully closed
      } else {
        final q = (p - 0.40) / 0.60;
        _blink = math.pow(1 - q, 2.2).toDouble(); // ~200ms gentle release
      }
    } else {
      _blink = 0;
      _blinkIn -= dt;
      if (_blinkIn <= 0) {
        _blinkPhase = _blinkDur;
        if (_dblBlink) {
          _dblBlink = false;
          _blinkIn = 0.18 + _rng.nextDouble() * 0.12;
        } else {
          _dblBlink = _rng.nextDouble() < 0.2;
          _blinkIn = switch (s) {
            AvatarState.listening => 3.0 + _rng.nextDouble() * 3.0,
            AvatarState.thinking => 1.4 + _rng.nextDouble() * 2.0,
            _ => 2.2 + _rng.nextDouble() * 3.2,
          };
        }
      }
    }

    // Mouth envelope + viseme.
    final target = widget.level.value.clamp(0.0, 1.0);
    _mouth += (target - _mouth) * (1 - math.exp(-dt * (target > _mouth ? 40 : 13)));
    final rising = (target - _prevLevel) / math.max(dt, 1e-3);
    if (s == AvatarState.talking && target > 0.2 && rising > 1.2) {
      _visWT = 0.66 + _rng.nextDouble() * 0.55;
      if (target > 0.3 && rising > 1.6 && _nodT >= _nodDur) {
        _startNod(0.28 + _rng.nextDouble() * 0.18);
      }
    }
    if (s != AvatarState.talking) _visWT = 1.0;
    _visW += (_visWT - _visW) * (1 - math.exp(-dt * 17));
    _prevLevel = target;
    if (_nodT < _nodDur) _nodT += dt;

    _lean += ((s == AvatarState.listening ? 1.0 : 0.0) - _lean) *
        (1 - math.exp(-dt * 4));
    // Pupils respond slowly and subtly — felt rather than seen: a touch wider
    // while listening and on encouragement, never theatrical.
    final pupilTarget = s == AvatarState.listening
        ? 0.8
        : _positive.contains(widget.emotion)
            ? 0.6
            : 0.15;
    _pupil += (pupilTarget - _pupil) * (1 - math.exp(-dt * 1.6));
    _emo = _Emo.lerp(_emo, _Emo.of(widget.emotion), 1 - math.exp(-dt * 7));

    _frame.value++;
  }

  bool get _talking => widget.state == AvatarState.talking;

  HeroPose get _pose => HeroPose(
    yaw: _yaw + (_talking ? math.sin(_t * 2.3) * 0.012 : 0),
    // The head dips a touch on loud syllables — riding its own emphasis.
    pitch: _pitch + _emo.pitch + _nod * 0.02 + _mouth * 0.014,
    roll: _emo.tilt + _nod * 0.01 + (_talking ? math.sin(_t * 1.7) * 0.008 : 0),
    bob: math.sin(_t * 1.6),
    sway: math.sin(_t * 0.5),
    blink: _blink,
    gazeX: _gazeX,
    gazeY: _gazeY,
    // Brows lift a little on stressed (loud) syllables — spoken emphasis reads
    // as a living face, not a flapping mouth.
    browRaise: _emo.brow + (_talking ? _mouth * 0.18 : 0),
    browFurrow: _emo.furrow,
    eyeWiden: _emo.widen,
    smile: _emo.smile,
    mouthOpen: _mouth,
    mouthWide: _visW,
    lean: _lean,
    pupilDilate: _pupil,
  );

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: photo != null
            ? _PhotoHeroPainter(
                repaint: _frame,
                poseOf: () => _pose,
                images: photo,
                tOf: () => _t,
              )
            : _BackdropPainter(), // never flash the old hero while decoding
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => paintPhotoBackdrop(canvas, size);

  @override
  bool shouldRepaint(_BackdropPainter old) => false;
}

class _PhotoHeroPainter extends CustomPainter {
  _PhotoHeroPainter({
    required Listenable repaint,
    required this.poseOf,
    required this.images,
    required this.tOf,
  }) : super(repaint: repaint);

  final HeroPose Function() poseOf;
  final PhotoHeroImages images;
  final double Function() tOf;

  @override
  void paint(Canvas canvas, Size size) {
    paintPhotoHero(canvas, size, pose: poseOf(), images: images, t: tOf());
  }

  @override
  bool shouldRepaint(_PhotoHeroPainter old) => false; // repaint drives it
}

// Kept as the one-line rollback path to the procedural hero (swap it back
// into the loading branch) even though PhotoHero is the shipped look.
// ignore: unused_element
class _HeroPainter extends CustomPainter {
  _HeroPainter({
    required Listenable repaint,
    required this.poseOf,
    required this.look,
    required this.tOf,
  }) : super(repaint: repaint);

  final HeroPose Function() poseOf;
  final HeroLook look;
  final double Function() tOf;

  @override
  void paint(Canvas canvas, Size size) {
    paintHero(canvas, size, pose: poseOf(), look: look, t: tOf());
  }

  @override
  bool shouldRepaint(_HeroPainter old) => false; // repaint drives it
}
