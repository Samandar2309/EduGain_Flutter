import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as rec;

/// A finished audio clip ready to upload.
class AudioClip {
  const AudioClip({required this.path, required this.filename});
  final String path;
  final String filename;
}

/// Microphone capture for audio Speaking. Records mono 16 kHz AAC — the format
/// Whisper expects internally, kept small (≈8 KB/s) so the upload is fast and
/// the user barely waits.
class SpeechRecorder {
  final rec.AudioRecorder _recorder = rec.AudioRecorder();

  static const _filename = 'speaking_turn.m4a';

  /// Whether mic access is granted; requests it from the OS if not yet decided.
  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$_filename';
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
    final path = await _recorder.stop();
    if (path == null) return null;
    return AudioClip(path: path, filename: _filename);
  }

  /// Abort an in-progress recording, discarding it.
  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> dispose() => _recorder.dispose();
}
