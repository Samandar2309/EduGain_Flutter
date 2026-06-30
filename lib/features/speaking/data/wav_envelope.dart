import 'dart:math' as math;
import 'dart:typed_data';

/// Computes a normalised loudness envelope (0..1, `fps` values per second) from
/// a PCM-16 WAV — the Groq TTS audio format. The speaking avatar reads this to
/// open its mouth in sync with the actual voice (louder = wider), instead of a
/// free-running flap.
///
/// Returns an empty list if the bytes aren't a PCM-16 WAV we can parse; the
/// caller then falls back to a synthetic mouth motion so playback still looks
/// alive. Never throws.
List<double> amplitudeEnvelope(Uint8List bytes, {int fps = 30}) {
  try {
    return _envelope(bytes, fps);
  } catch (_) {
    return const [];
  }
}

List<double> _envelope(Uint8List bytes, int fps) {
  if (bytes.length < 44) return const [];
  final data = ByteData.sublistView(bytes);
  // RIFF / WAVE header.
  if (_tag(bytes, 0) != 'RIFF' || _tag(bytes, 8) != 'WAVE') return const [];

  int sampleRate = 0;
  int channels = 1;
  int bits = 16;
  int format = 1;
  int dataStart = -1;
  int dataLen = 0;

  // Walk the chunk list looking for `fmt ` then `data`.
  var p = 12;
  while (p + 8 <= bytes.length) {
    final id = _tag(bytes, p);
    final size = data.getUint32(p + 4, Endian.little);
    final body = p + 8;
    if (id == 'fmt ' && body + 16 <= bytes.length) {
      format = data.getUint16(body, Endian.little);
      channels = math.max(1, data.getUint16(body + 2, Endian.little));
      sampleRate = data.getUint32(body + 4, Endian.little);
      bits = data.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      dataStart = body;
      dataLen = math.min(size, bytes.length - body);
      break;
    }
    // Chunks are word-aligned (pad to even length).
    p = body + size + (size.isOdd ? 1 : 0);
  }

  if (format != 1 || bits != 16 || sampleRate <= 0 || dataStart < 0) {
    return const [];
  }

  final bytesPerSample = 2 * channels; // 16-bit frames
  final totalFrames = dataLen ~/ bytesPerSample;
  if (totalFrames <= 0) return const [];

  final framesPerWindow = math.max(1, sampleRate ~/ fps);
  final windows = (totalFrames / framesPerWindow).ceil();
  final rms = List<double>.filled(windows, 0);

  var maxRms = 1e-9;
  for (var w = 0; w < windows; w++) {
    final start = w * framesPerWindow;
    final end = math.min(start + framesPerWindow, totalFrames);
    var sumSq = 0.0;
    var n = 0;
    for (var f = start; f < end; f++) {
      // Channel 0 only — mono mouth signal is plenty.
      final s = data.getInt16(dataStart + f * bytesPerSample, Endian.little);
      final v = s / 32768.0;
      sumSq += v * v;
      n++;
    }
    final r = n == 0 ? 0.0 : math.sqrt(sumSq / n);
    rms[w] = r;
    if (r > maxRms) maxRms = r;
  }

  // Peak-normalise so a quiet voice still opens the mouth fully, with a small
  // noise gate and a perceptual curve so silences read as closed.
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

String _tag(Uint8List b, int o) =>
    String.fromCharCodes(b.sublist(o, o + 4));
