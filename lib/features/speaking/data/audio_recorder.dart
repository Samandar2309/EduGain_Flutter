import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart' as rec;

import 'native_audio_io_stub.dart' if (dart.library.io) 'native_audio_io.dart';
import 'wav_encode.dart';

/// A finished audio clip ready to upload, in memory — works identically on
/// native (read from the recorder's temp file) and web (accumulated from the
/// recorder's live byte stream, since there is no filesystem in a browser).
class AudioClip {
  const AudioClip({required this.bytes, required this.filename});
  final Uint8List bytes;
  final String filename;
}

const int _webSampleRate = 16000;

/// Microphone capture for audio Speaking.
///  * Native: records mono 16 kHz AAC to a temp file (the format Whisper
///    expects internally, ~8 KB/s), then reads it into bytes for upload.
///  * Web: `record`'s web backend only streams raw PCM16 (`startStream`
///    throws "Stream not supported." for every other encoder — verified in
///    record_web 1.3.0 source), and its AudioWorklet resamples to the
///    requested rate on every browser engine. So the web path streams
///    PCM16 @ 16 kHz mono and wraps it in a WAV header at stop — a
///    deterministic `.wav` on Chromium AND WebKit WebViews, with none of
///    MediaRecorder's per-browser codec roulette.
class SpeechRecorder {
  final rec.AudioRecorder _recorder = rec.AudioRecorder();

  static const _nativeFilename = 'speaking_turn.m4a';
  static const _webFilename = 'speaking_turn.wav';

  StreamSubscription<Uint8List>? _webSub;
  BytesBuilder? _webBuffer;

  /// Whether mic access is granted; requests it from the OS/browser if not
  /// yet decided.
  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    if (kIsWeb) {
      _webBuffer = BytesBuilder(copy: false);
      final stream = await _recorder.startStream(
        const rec.RecordConfig(
          encoder: rec.AudioEncoder.pcm16bits,
          sampleRate: _webSampleRate,
          numChannels: 1,
        ),
      );
      _webSub = stream.listen(_webBuffer!.add);
      return;
    }
    final path = await nativeTempFilePath(_nativeFilename);
    await _recorder.start(
      const rec.RecordConfig(
        encoder: rec.AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 64000,
      ),
      path: path,
    );
  }

  Future<bool> isRecording() => _recorder.isRecording();

  /// Stop and return the recorded clip, or null if nothing was captured.
  Future<AudioClip?> stop() async {
    if (kIsWeb) {
      await _recorder.stop();
      await _webSub?.cancel();
      _webSub = null;
      final pcm = _webBuffer?.takeBytes();
      _webBuffer = null;
      if (pcm == null || pcm.isEmpty) return null;
      return AudioClip(
        bytes: wavFromPcm16(pcm, sampleRate: _webSampleRate, numChannels: 1),
        filename: _webFilename,
      );
    }
    final path = await _recorder.stop();
    if (path == null) return null;
    final bytes = await nativeReadBytes(path);
    return AudioClip(bytes: bytes, filename: _nativeFilename);
  }

  /// Abort an in-progress recording, discarding it.
  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _webSub?.cancel();
    _webSub = null;
    _webBuffer = null;
  }

  Future<void> dispose() => _recorder.dispose();
}
