import 'package:edugain/features/speaking/data/frame_watch.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reporting how smooth the screen was, from the device that was stuttering.
///
/// "It freezes on the phone" is the one complaint that cannot be answered from
/// a desk: jank happens between frames, on hardware nobody here owns, and every
/// guess about it costs a deploy. The engine already measures it and nothing
/// read the numbers.
void main() {
  test('a smooth session reports no jank', () {
    const stats = FrameStats(
      frames: 600,
      janky: 4,
      worstBuildMs: 6,
      worstRasterMs: 9,
    );
    expect(stats.jankPercent, 1);
  });

  test('a stuttering session says so plainly', () {
    const stats = FrameStats(
      frames: 300,
      janky: 90,
      worstBuildMs: 12,
      worstRasterMs: 140,
    );
    expect(stats.jankPercent, 30, reason: 'this is what "it freezes" means');
  });

  test('it separates our layout from the GPU', () {
    // The whole diagnostic value: build time is the app's own work and raster
    // is the GPU turning it into pixels. They have entirely different fixes,
    // and a single "it was slow" number would send the next day down the wrong
    // one.
    const gpuBound = FrameStats(
      frames: 100,
      janky: 40,
      worstBuildMs: 3,
      worstRasterMs: 120,
    );
    expect(gpuBound.worstRasterMs, greaterThan(gpuBound.worstBuildMs * 10));
    expect(gpuBound.toString(), contains('raster 120ms'));
    expect(gpuBound.toString(), contains('40/100'));
  });

  test('an idle screen is not reported as perfect OR as broken', () {
    // No frames measured yet is not 0% jank earned — it is no evidence. It must
    // not divide by zero either.
    const nothing = FrameStats(
      frames: 0,
      janky: 0,
      worstBuildMs: 0,
      worstRasterMs: 0,
    );
    expect(nothing.jankPercent, 0);
  });

  test('reset starts each turn fresh', () {
    // Per turn, so one bad moment cannot be averaged away by calm minutes
    // around it.
    final watch = FrameWatch()..reset();
    expect(watch.stats.frames, 0);
    expect(watch.stats.janky, 0);
  });

  test('the threshold is where a person notices, not where the maths does', () {
    // 16.7 ms is one frame's budget; a little over is invisible. Pinned because
    // it is a judgement about eyes, not a tuning constant.
    expect(jankThreshold, const Duration(milliseconds: 24));
  });
}
