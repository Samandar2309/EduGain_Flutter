import 'dart:math' as math;
import 'dart:typed_data';

import 'package:edugain/features/speaking/data/wav_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cost of the lip-sync envelope, which learners felt as freezing.
///
/// Reported from real testing: the app froze during the tutor's reply. The
/// envelope was reading every single sample of the clip — ~360 000 bounds-
/// checked reads for a 15-second answer — on the main thread, right before
/// playback started. There is no isolate to move it to: Dart on web has none,
/// so `compute()` would have run it on the same thread anyway. The only fix
/// available was to make the work small.
///
/// These tests pin the two things that matter: that it stays small, and that
/// making it small did not change what the mouth does.
Uint8List _wav({
  required int seconds,
  int sampleRate = 24000,
  double freq = 140,
}) {
  final frames = seconds * sampleRate;
  final pcm = Uint8List(frames * 2);
  final view = ByteData.sublistView(pcm);
  for (var i = 0; i < frames; i++) {
    // Speech-ish: a tone whose loudness swells and fades, so the envelope has
    // real structure to get right rather than a flat line.
    final t = i / sampleRate;
    final swell = 0.5 + 0.5 * math.sin(2 * math.pi * 0.7 * t);
    final v = math.sin(2 * math.pi * freq * t) * swell;
    view.setInt16(i * 2, (v * 32000).round(), Endian.little);
  }
  int u32(int v) => v;
  final header = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add(_le32(u32(36 + pcm.length)))
    ..add('WAVE'.codeUnits)
    ..add('fmt '.codeUnits)
    ..add(_le32(16))
    ..add(_le16(1))
    ..add(_le16(1))
    ..add(_le32(sampleRate))
    ..add(_le32(sampleRate * 2))
    ..add(_le16(2))
    ..add(_le16(16))
    ..add('data'.codeUnits)
    ..add(_le32(pcm.length));
  return Uint8List.fromList([...header.toBytes(), ...pcm]);
}

List<int> _le32(int v) =>
    [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];
List<int> _le16(int v) => [v & 0xFF, (v >> 8) & 0xFF];

/// What the envelope used to do: every sample, no stride.
List<double> _referenceEnvelope(Uint8List bytes, int fps) {
  final data = ByteData.sublistView(bytes);
  const dataStart = 44;
  final totalFrames = (bytes.length - dataStart) ~/ 2;
  final framesPerWindow = 24000 ~/ fps;
  final windows = (totalFrames / framesPerWindow).ceil();
  final rms = List<double>.filled(windows, 0);
  var maxRms = 1e-9;
  for (var w = 0; w < windows; w++) {
    final start = w * framesPerWindow;
    final end = math.min(start + framesPerWindow, totalFrames);
    var sumSq = 0.0;
    var n = 0;
    for (var f = start; f < end; f++) {
      final v = data.getInt16(dataStart + f * 2, Endian.little) / 32768.0;
      sumSq += v * v;
      n++;
    }
    final r = n == 0 ? 0.0 : math.sqrt(sumSq / n);
    rms[w] = r;
    if (r > maxRms) maxRms = r;
  }
  const gate = 0.06;
  return [
    for (final r in rms)
      () {
        final x = r / maxRms;
        if (x < gate) return 0.0;
        return math.pow((x - gate) / (1 - gate), 0.6).toDouble().clamp(0.0, 1.0);
      }(),
  ];
}

void main() {
  group('the fix', () {
    test('reads a bounded number of samples per window, not all of them', () {
      // 24 kHz at 30 fps is an 800-sample window; reading all 800 is what
      // cost the frame. A tidy-up back to stride 1 would restore the freeze
      // with no other visible symptom, so it is asserted directly.
      expect(envelopeStride(800), greaterThan(1));
      expect(envelopeStride(800), 12);
      // 48 kHz windows are twice the size and so stride twice as far — the
      // work stays flat as sample rates rise.
      expect(envelopeStride(1600), 25);
    });

    test('never strides past the end of a small window', () {
      // Below the sample budget there is nothing to skip, and a stride of 0
      // would spin forever.
      expect(envelopeStride(64), 1);
      expect(envelopeStride(10), 1);
      expect(envelopeStride(1), 1);
      expect(envelopeStride(0), 1);
    });
  });

  group('what the mouth does is unchanged', () {
    test('tracks the reference envelope closely', () {
      final wav = _wav(seconds: 4);
      final fast = amplitudeEnvelope(wav, fps: 30);
      final full = _referenceEnvelope(wav, 30);

      expect(fast.length, full.length, reason: 'same number of frames');
      var worst = 0.0;
      for (var i = 0; i < fast.length; i++) {
        worst = math.max(worst, (fast[i] - full[i]).abs());
      }
      // The output drives how far a mouth opens and is peak-normalised, so a
      // few percent is imperceptible. Anything larger would be visible as the
      // lip-sync drifting from the voice.
      expect(worst, lessThan(0.05), reason: 'worst-case deviation $worst');
    });

    test('still opens and closes across a swell', () {
      final env = amplitudeEnvelope(_wav(seconds: 3), fps: 30);
      expect(env, isNotEmpty);
      expect(env.reduce(math.max), greaterThan(0.8), reason: 'mouth opens wide');
      expect(env.reduce(math.min), lessThan(0.2), reason: 'and closes again');
    });

    test('a long reply still produces one value per frame', () {
      // 30 seconds is a realistic upper bound for a tutor turn.
      final env = amplitudeEnvelope(_wav(seconds: 30), fps: 30);
      expect(env.length, closeTo(30 * 30, 2));
    });

    test('still refuses anything that is not a PCM-16 WAV', () {
      expect(amplitudeEnvelope(Uint8List.fromList(List.filled(200, 7))), isEmpty);
    });
  });
}
