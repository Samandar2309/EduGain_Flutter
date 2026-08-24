/// How smooth the screen actually is, on the device the learner is holding.
///
/// "It stutters on the phone" is the one complaint that cannot be answered from
/// a desk. Latency can be timed from the server; jank cannot — it happens
/// between frames, on hardware nobody here owns, and every guess about it costs
/// a deploy.
///
/// Flutter already measures it: the engine reports how long each frame spent
/// being built and rasterized. Nothing reads that. This does, cheaply — two
/// integers per frame and no allocation — so a turn can carry the answer home
/// beside its timings.
///
/// What it is NOT: a profiler. It answers one question — was this session
/// smooth, and if not, which half was slow? Build time is the app's own layout
/// and painting; raster time is the GPU turning that into pixels. They have
/// completely different fixes, and knowing which one is the whole value here.
library;

import 'package:flutter/scheduler.dart';

/// A frame that took longer than this missed its slot at 60 Hz.
///
/// 16.7 ms is the budget for one frame; a little over is invisible, so the line
/// is drawn where a person starts to see it rather than where the maths does.
const Duration jankThreshold = Duration(milliseconds: 24);

/// One session's smoothness, in the four numbers worth carrying.
class FrameStats {
  const FrameStats({
    required this.frames,
    required this.janky,
    required this.worstBuildMs,
    required this.worstRasterMs,
  });

  final int frames;
  final int janky;
  final int worstBuildMs;
  final int worstRasterMs;

  /// Share of frames that visibly missed, 0-100. The single number to read
  /// first: under about 5% nobody notices, over 20% it is what "qotib qoladi"
  /// means.
  int get jankPercent => frames == 0 ? 0 : (janky * 100 / frames).round();

  @override
  String toString() =>
      '$janky/$frames janky ($jankPercent%), '
      'worst build ${worstBuildMs}ms raster ${worstRasterMs}ms';
}

/// Watches frame timings for as long as it is running.
class FrameWatch {
  int _frames = 0;
  int _janky = 0;
  int _worstBuild = 0;
  int _worstRaster = 0;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    SchedulerBinding.instance.addTimingsCallback(_onFrames);
  }

  void stop() {
    if (!_running) return;
    _running = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrames);
  }

  void _onFrames(List<FrameTiming> timings) {
    for (final t in timings) {
      _frames++;
      final build = t.buildDuration;
      final raster = t.rasterDuration;
      if (build + raster > jankThreshold) _janky++;
      final buildMs = build.inMilliseconds;
      final rasterMs = raster.inMilliseconds;
      if (buildMs > _worstBuild) _worstBuild = buildMs;
      if (rasterMs > _worstRaster) _worstRaster = rasterMs;
    }
  }

  FrameStats get stats => FrameStats(
    frames: _frames,
    janky: _janky,
    worstBuildMs: _worstBuild,
    worstRasterMs: _worstRaster,
  );

  /// Start each turn's measurement fresh, so a bad moment cannot be averaged
  /// away by a long calm session around it.
  void reset() {
    _frames = 0;
    _janky = 0;
    _worstBuild = 0;
    _worstRaster = 0;
  }
}
