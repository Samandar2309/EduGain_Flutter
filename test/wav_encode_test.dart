import 'dart:math' as math;
import 'dart:typed_data';

import 'package:edugain/features/speaking/data/wav_encode.dart';
import 'package:edugain/features/speaking/data/wav_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
