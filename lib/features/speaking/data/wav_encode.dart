import 'dart:typed_data';

/// Wraps raw 16-bit little-endian PCM samples in a standard 44-byte WAV
/// header. Used by the web recorder: `record`'s only web streaming format is
/// raw PCM16 (its AudioWorklet resamples to the requested rate on every
/// browser engine), and Whisper wants a real container — this turns that
/// stream into a deterministic `.wav` with zero codec roulette.
Uint8List wavFromPcm16(
  Uint8List pcm, {
  int sampleRate = 16000,
  int numChannels = 1,
}) {
  const bitsPerSample = 16;
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);

  final header = ByteData(44);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // PCM fmt chunk size
  header.setUint16(20, 1, Endian.little); // audio format: PCM
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);

  final out = Uint8List(44 + pcm.length);
  out.setRange(0, 44, header.buffer.asUint8List());
  out.setRange(44, out.length, pcm);
  return out;
}

/// Drop the silence at each end of a clip before it is uploaded.
///
/// The upload is the largest single part of a spoken turn — 32 KB for every
/// second of PCM16 at 16 kHz. A learner taps to start, thinks, speaks, finishes
/// the thought and then reaches for the button, so two to four seconds of a
/// seventeen-second clip is usually nobody talking. That is 60-130 KB sent for
/// nothing.
///
/// Deliberately timid, in three ways:
///
/// * The threshold is low (about -45 dBFS), so breathing and room noise still
///   count as sound rather than being cut away.
/// * A [keep] margin of speech is left on each side, because the quietest part
///   of a word is its start and its end — trimming to the exact first loud
///   sample clips consonants, and a clipped word is an audible fault where a
///   little extra silence is not.
/// * A clip that looks entirely silent is returned untouched. If the reading is
///   wrong, sending too much is recoverable and sending nothing is not.
Uint8List trimSilence(
  Uint8List pcm, {
  int sampleRate = 16000,
  double threshold = 0.006,
  Duration keep = const Duration(milliseconds: 250),
}) {
  if (pcm.length < 4) return pcm;
  final samples = Int16List.view(pcm.buffer, pcm.offsetInBytes, pcm.length ~/ 2);

  int? first;
  int? last;
  for (var i = 0; i < samples.length; i++) {
    if ((samples[i] / 32768).abs() >= threshold) {
      first ??= i;
      last = i;
    }
  }
  if (first == null || last == null) return pcm;

  final margin = (sampleRate * keep.inMilliseconds) ~/ 1000;
  final start = (first - margin).clamp(0, samples.length);
  final end = (last + margin + 1).clamp(0, samples.length);
  if (end - start >= samples.length) return pcm;

  // Byte offsets, and even ones: a 16-bit sample cut in half is noise.
  return Uint8List.sublistView(pcm, start * 2, end * 2);
}
