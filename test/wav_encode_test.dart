import 'dart:math' as math;
import 'dart:typed_data';

import 'package:edugain/features/speaking/data/wav_encode.dart';
import 'package:edugain/features/speaking/data/wav_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('trimming the silence off a turn', _trimSuite);

  Uint8List sinePcm({int sampleRate = 16000, double seconds = 0.5}) {
    final n = (sampleRate * seconds).round();
    final data = ByteData(n * 2);
    for (var i = 0; i < n; i++) {
      final v = (math.sin(2 * math.pi * 440 * i / sampleRate) * 20000).round();
      data.setInt16(i * 2, v, Endian.little);
    }
    return data.buffer.asUint8List();
  }

  test('produces a spec-correct 44-byte header', () {
    final pcm = sinePcm();
    final wav = wavFromPcm16(pcm, sampleRate: 16000, numChannels: 1);
    final d = ByteData.sublistView(wav);

    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(d.getUint32(4, Endian.little), 36 + pcm.length);
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(d.getUint16(20, Endian.little), 1); // PCM
    expect(d.getUint16(22, Endian.little), 1); // mono
    expect(d.getUint32(24, Endian.little), 16000);
    expect(d.getUint32(28, Endian.little), 32000); // byte rate
    expect(d.getUint16(32, Endian.little), 2); // block align
    expect(d.getUint16(34, Endian.little), 16); // bits per sample
    expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    expect(d.getUint32(40, Endian.little), pcm.length);
    expect(wav.length, 44 + pcm.length);
  });

  test('round-trips through the app\'s own WAV parser (amplitudeEnvelope)', () {
    // The lip-sync envelope parser reads real WAV — if it can parse what we
    // wrote and sees loudness, the header is genuinely valid, not just
    // byte-for-byte per our own expectations.
    final wav = wavFromPcm16(sinePcm(seconds: 1.0));
    final env = amplitudeEnvelope(wav, fps: 30);
    expect(env, isNotEmpty);
    expect(env.reduce(math.max), greaterThan(0.5)); // a loud sine, not silence
  });

  test('empty PCM still yields a valid, playable-length container', () {
    final wav = wavFromPcm16(Uint8List(0));
    expect(wav.length, 44);
    expect(ByteData.sublistView(wav).getUint32(40, Endian.little), 0);
  });
}

// ── trimming the silence off a turn ─────────────────────────────────────────

Uint8List _pcm(List<double> amplitudes) {
  final s = Int16List.fromList(
    amplitudes.map((a) => (a * 32767).round()).toList(),
  );
  return Uint8List.view(s.buffer);
}

void _trimSuite() {
  test('silence at both ends is dropped', () {
    // 16000 samples of nothing, a burst, then nothing again.
    final pcm = _pcm([
      ...List.filled(16000, 0.0),
      ...List.filled(8000, 0.4),
      ...List.filled(16000, 0.0),
    ]);
    final out = trimSilence(pcm);
    expect(out.length, lessThan(pcm.length));
    // The burst plus a 250 ms margin each side, and nothing like the original.
    expect(out.length ~/ 2, closeTo(8000 + 2 * 4000, 200));
  });

  test('a margin is left so the quiet start of a word survives', () {
    // The failure this guards: trimming to the first loud sample clips
    // consonants, and a clipped word is an audible fault where a little extra
    // silence is not.
    final pcm = _pcm([...List.filled(16000, 0.0), ...List.filled(1000, 0.4)]);
    final out = trimSilence(pcm);
    expect(out.length ~/ 2, greaterThan(1000));
  });

  test('speech with no silence around it is left alone', () {
    final pcm = _pcm(List.filled(8000, 0.3));
    expect(trimSilence(pcm).length, pcm.length);
  });

  test('a clip that reads as entirely silent is never emptied', () {
    // If the reading is wrong, sending too much is recoverable and sending
    // nothing is not.
    final pcm = _pcm(List.filled(8000, 0.0));
    expect(trimSilence(pcm).length, pcm.length);
  });

  test('breathing and room noise still count as sound', () {
    // A threshold set high enough to cut these would cut the quiet end of
    // words too.
    final pcm = _pcm([
      ...List.filled(4000, 0.0),
      ...List.filled(4000, 0.02),
      ...List.filled(4000, 0.0),
    ]);
    expect(trimSilence(pcm).length, greaterThan(4000 * 2));
  });

  test('the result is always a whole number of samples', () {
    // A 16-bit sample cut in half is noise.
    final pcm = _pcm([
      ...List.filled(999, 0.0),
      ...List.filled(1001, 0.4),
      ...List.filled(997, 0.0),
    ]);
    expect(trimSilence(pcm).length.isEven, isTrue);
  });

  test('a tiny clip is returned untouched', () {
    expect(trimSilence(Uint8List(2)).length, 2);
    expect(trimSilence(Uint8List(0)).length, 0);
  });
}
