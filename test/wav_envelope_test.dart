import 'dart:typed_data';

import 'package:edugain/features/speaking/data/wav_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build a minimal 16-bit mono PCM WAV from raw samples.
Uint8List _wav(List<int> samples, {int sampleRate = 30}) {
  final pcm = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    pcm.setInt16(i * 2, samples[i], Endian.little);
  }
  final data = pcm.buffer.asUint8List();
  final b = BytesBuilder();
  void tag(String s) => b.add(s.codeUnits);
  void u32(int v) =>
      b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) =>
      b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  tag('RIFF');
  u32(36 + data.length);
  tag('WAVE');
  tag('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(sampleRate);
  u32(sampleRate * 2); // byte rate
  u16(2); // block align
  u16(16); // bits
  tag('data');
  u32(data.length);
  b.add(data);
  return b.toBytes();
}

void main() {
  group('amplitudeEnvelope', () {
    test('tracks loudness: silent windows closed, loud windows open', () {
      // sampleRate == fps → one sample per window.
      final wav = _wav([0, 0, 0, 30000, 30000, 30000], sampleRate: 30);
      final env = amplitudeEnvelope(wav, fps: 30);
      expect(env.length, 6);
      expect(env[0], 0.0); // silence gated to closed
      expect(env[1], 0.0);
      expect(env.last, greaterThan(0.8)); // peak → wide open
    });

    test('returns empty for non-WAV bytes (caller falls back)', () {
      expect(amplitudeEnvelope(Uint8List.fromList([1, 2, 3, 4])), isEmpty);
      expect(amplitudeEnvelope(Uint8List(0)), isEmpty);
    });

    test('never throws on a truncated header', () {
      final wav = _wav([100, 200], sampleRate: 30);
      final truncated = wav.sublist(0, 30);
      expect(amplitudeEnvelope(truncated), isEmpty);
    });
  });
}
