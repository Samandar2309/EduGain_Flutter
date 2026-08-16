import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart' as rec;

import 'voice_activity.dart';

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
void _ignoreLevel(double _) {}

class SpeechRecorder {
  final rec.AudioRecorder _recorder = rec.AudioRecorder();

  static const _nativeFilename = 'speaking_turn.m4a';
  static const _webFilename = 'speaking_turn.wav';

  StreamSubscription<Uint8List>? _webSub;
  StreamSubscription<rec.Amplitude>? _ampSub;
  BytesBuilder? _webBuffer;

  /// Whether the arriving audio belongs to a turn or is being discarded.
  bool _capturing = false;

  /// Where the current turn's loudness goes. Re-pointed each turn; the stream
  /// underneath it does not change.
  void Function(double level)? _webLevel;

  /// Whether mic access is granted; requests it from the OS/browser if not
  /// yet decided.
  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start({void Function(double level) onLevel = _ignoreLevel})
      async {
    if (kIsWeb) {
      // A turn is a buffer, not a stream.
      //
      // The dialog belongs to `getUserMedia`, which `startStream` calls — so
      // starting the stream per turn asked permission per turn. It is started
      // once instead, and kept running until the conversation closes.
      _webLevel = onLevel;
      _webBuffer = BytesBuilder(copy: false);
      _capturing = true;
      if (_webSub != null) return;

      final stream = await _recorder.startStream(
        const rec.RecordConfig(
          encoder: rec.AudioEncoder.pcm16bits,
          sampleRate: _webSampleRate,
          numChannels: 1,
          // The three that decide whether somebody has to shout. The peer call
          // has had them since it was written; this path never did.
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      _webSub = stream.listen(
        (chunk) {
          // Between turns the stream keeps arriving and is thrown away. Cheaper
          // and far less fragile than tearing the microphone down and asking for
          // it again, which is the thing that was going wrong.
          if (!_capturing) return;
          _webBuffer?.add(chunk);
          _webLevel?.call(rms(chunk));
        },
        // A capture that ends is not the end of the conversation.
        //
        // The stream is opened once and held for the whole session, so that the
        // permission dialog is asked for once rather than every turn. But a
        // long-held track does not always survive: a Telegram WebView under
        // memory pressure, a spell in the background, an audio context the
        // browser decided to suspend — any of them can end it, and none of them
        // is an error anybody sees.
        //
        // Left as it was, `_webSub` stayed non-null forever and the guard above
        // refused to reopen it. Nothing reached the buffer, every turn uploaded
        // nothing, and the app went deaf a few minutes into a conversation with
        // no sign of why. Dropping the handle is what lets the next turn open a
        // fresh one — and because permission has already been granted by then,
        // reopening shows no dialog at all.
        onDone: _releaseWebCapture,
        onError: (Object _) => _releaseWebCapture(),
        cancelOnError: true,
      );
      return;
    }
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amp) {
      // dBFS, roughly -60 (silence) to 0 (clipping).
      final db = amp.current.clamp(-60.0, 0.0);
      onLevel((db + 60) / 60);
    });
    final path = await nativeTempFilePath(_nativeFilename);
    await _recorder.start(
      const rec.RecordConfig(
        encoder: rec.AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 64000,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: path,
    );
  }

  /// Forget the capture handle so the next turn opens a new one.
  ///
  /// Only the handle: the buffer and the capturing flag belong to the turn in
  /// progress and are cleared by `stop`/`cancel`.
  void _releaseWebCapture() {
    _webSub?.cancel();
    _webSub = null;
  }

  Future<bool> isRecording() => _recorder.isRecording();

  /// Stop and return the recorded clip, or null if nothing was captured.
  Future<AudioClip?> stop() async {
    if (kIsWeb) {
      // The turn ends. The microphone does not.
      _capturing = false;
      final pcm = _webBuffer?.takeBytes();
      _webBuffer = null;
      if (pcm == null || pcm.isEmpty) {
        // A turn that captured nothing means the track stopped delivering
        // without ending the Dart stream — the quieter half of the same
        // failure, and the one `onDone` above cannot catch. Drop the handle so
        // the next turn reopens rather than recording silence forever.
        _releaseWebCapture();
        return null;
      }
      return AudioClip(
        // Trimmed first: the silence at each end is bytes nobody says and
        // seconds nobody hears, and the upload is the largest part of a turn.
        bytes: wavFromPcm16(
          trimSilence(pcm, sampleRate: _webSampleRate),
          sampleRate: _webSampleRate,
          numChannels: 1,
        ),
        filename: _webFilename,
      );
    }
    await _ampSub?.cancel();
    _ampSub = null;
    final path = await _recorder.stop();
    if (path == null) return null;
    final bytes = await nativeReadBytes(path);
    return AudioClip(bytes: bytes, filename: _nativeFilename);
  }

  /// Abort an in-progress recording, discarding it.
  Future<void> cancel() async {
    if (kIsWeb) {
      // Abandoning a turn is not leaving the conversation, so the stream stays.
      _capturing = false;
      _webBuffer = null;
      return;
    }
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _ampSub?.cancel();
    _ampSub = null;
  }

  /// Close the microphone. For leaving the conversation — and only there,
  /// because releasing it between turns is the whole bug.
  Future<void> endSession() async {
    _capturing = false;
    _webLevel = null;
    _webBuffer = null;
    await _webSub?.cancel();
    _webSub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> dispose() async {
    await endSession();
    await _recorder.dispose();
  }
}
