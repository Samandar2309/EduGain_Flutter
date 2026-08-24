import 'package:edugain/features/speaking/data/sample_rate_probe.dart';
import 'package:flutter_test/flutter_test.dart';

/// Believing the browser about the sample rate, and what it costs on iPhone.
///
/// The app asks `getUserMedia` for 16 kHz and then assumed it got it — in the
/// WAV header it writes, in the duration it reports for each loudness reading,
/// and in the silence it trims. Android Chrome honours the request, which is
/// why the assumption survived. Safari and the iOS WKWebView that Telegram Mini
/// Apps run in are the documented case that does not: they hand back the device
/// rate, typically 48 kHz.
///
/// Three times the samples, labelled 16 kHz, is a recording the transcriber
/// hears at a third of speed — and a silence detector that thinks a third of a
/// second is a whole one, so the learner is cut off mid-sentence every time.
/// Neither symptom looks anything like a sample rate.
void main() {
  /// Feeding the probe at a given rate for a given time, the way a capture
  /// delivers: many small chunks, not one big one.
  SampleRateProbe fedAt(int rate, {Duration span = const Duration(seconds: 2)}) {
    var now = Duration.zero;
    final probe = SampleRateProbe(requested: 16000, elapsed: () => now);
    const chunk = Duration(milliseconds: 100);
    for (var t = Duration.zero; t < span; t += chunk) {
      now = t + chunk;
      probe.heard((rate * chunk.inMilliseconds / 1000).round());
    }
    return probe;
  }

  group('what the device is really doing', () {
    test('Android honours the request, and nothing changes', () {
      expect(fedAt(16000).rate, 16000);
    });

    test('an iPhone at 48 kHz is measured, not assumed', () {
      final probe = fedAt(48000);
      expect(
        probe.rate,
        48000,
        reason: 'the header would say 16 kHz over 48 kHz of audio — a third '
            'speed recording that no transcriber can read',
      );
      expect(probe.isMeasured, isTrue);
    });

    test('44.1 kHz, the other rate real hardware picks', () {
      expect(fedAt(44100).rate, 44100);
    });
  });

  test('the clock starts with the AUDIO, not with the app', () {
    // The regression that shipped and was caught in production telemetry:
    // `sample_rate: 8000, rate_measured: true` on a device delivering 16 kHz.
    //
    // A capture is negotiated before it delivers — getUserMedia, an
    // AudioContext, a worklet — and the old code measured frames-since-audio
    // against time-since-construction. Five seconds of setup then five seconds
    // of 16 kHz audio reads as 8 kHz: a header describing the recording at half
    // speed, and a silence detector cutting every learner off halfway through
    // their pause.
    //
    // The first version of this test fed audio from t=0, so it never saw it.
    var now = Duration.zero;
    final probe = SampleRateProbe(requested: 16000, elapsed: () => now);

    // Five seconds where the capture exists but delivers nothing.
    now = const Duration(seconds: 5);

    // Then two seconds of real 16 kHz audio.
    for (var i = 1; i <= 20; i++) {
      now = const Duration(seconds: 5) + Duration(milliseconds: i * 100);
      probe.heard(1600);
    }

    expect(
      probe.rate,
      16000,
      reason: 'the silence before the first chunk was counted as audio',
    );
  });

  test('a rebuilt capture measures from ITS first chunk', () {
    // The same trap one layer along: `reset()` must not leave the window open
    // at the old start, or every rebuilt stream reads low.
    var now = Duration.zero;
    final probe = SampleRateProbe(requested: 16000, elapsed: () => now);
    for (var i = 1; i <= 20; i++) {
      now = Duration(milliseconds: i * 100);
      probe.heard(4800);
    }
    expect(probe.rate, 48000);

    probe.reset();
    now = const Duration(seconds: 30); // a long gap while it is rebuilt
    for (var i = 1; i <= 20; i++) {
      now = const Duration(seconds: 30) + Duration(milliseconds: i * 100);
      probe.heard(1600);
    }
    expect(probe.rate, 16000, reason: 'the gap before the rebuild was counted');
  });

  group('it does not guess', () {
    test('before enough audio it reports what was asked for', () {
      var now = Duration.zero;
      final probe = SampleRateProbe(requested: 16000, elapsed: () => now);
      now = const Duration(milliseconds: 100);
      probe.heard(4800);
      expect(probe.rate, 16000, reason: 'it committed on a tenth of a second');
      expect(probe.isMeasured, isFalse);
    });

    test('silence teaches it nothing', () {
      var now = Duration.zero;
      final probe = SampleRateProbe(requested: 16000, elapsed: () => now);
      now = const Duration(seconds: 5);
      probe.heard(0);
      expect(probe.rate, 16000);
    });

    test('a rate near nothing plausible is refused', () {
      // Delivery stalled: far too few frames for the time. Reporting 3 kHz
      // would be worse than reporting the assumption.
      expect(snapToStandardRate(3000), isNull);
      expect(snapToStandardRate(0), isNull);
      expect(snapToStandardRate(-5), isNull);
    });

    test('16 k and 24 k are never mistaken for each other', () {
      expect(snapToStandardRate(16400), 16000);
      expect(snapToStandardRate(23500), 24000);
      expect(snapToStandardRate(47000), 48000);
    });
  });

  test('a rebuilt capture measures itself again', () {
    // A stream that died and came back can return at a different rate; keeping
    // the old answer would describe audio that no longer exists.
    var now = Duration.zero;
    final probe = SampleRateProbe(requested: 16000, elapsed: () => now);
    for (var i = 1; i <= 20; i++) {
      now = Duration(milliseconds: i * 100);
      probe.heard(4800);
    }
    expect(probe.rate, 48000);

    probe.reset();
    expect(probe.isMeasured, isFalse);
    expect(probe.rate, 16000, reason: 'it kept an answer about a dead stream');
  });
}
