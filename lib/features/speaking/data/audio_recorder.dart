import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart' as rec;

import 'capture_health.dart';
import 'sample_rate_probe.dart';

import 'opus_capture_stub.dart'
    if (dart.library.js_interop) 'opus_capture_web.dart';

import 'voice_activity.dart';

import 'native_audio_io_stub.dart' if (dart.library.io) 'native_audio_io.dart';
import 'turn_timing.dart';
import 'wav_encode.dart';

/// A finished audio clip ready to upload, in memory — works identically on
/// native (read from the recorder's temp file) and web (accumulated from the
/// recorder's live byte stream, since there is no filesystem in a browser).
class AudioClip {
  const AudioClip({required this.bytes, required this.filename});
  final Uint8List bytes;
  final String filename;
}

/// What the browser is ASKED for. What it actually delivers is measured — see
/// [SampleRateProbe], and the iOS failure that made it necessary.
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

  /// Below this, an encoded clip is a container and not a recording.
  ///
  /// Opus at 24 kbps is about 3 KB per second, so this is roughly four tenths
  /// of a second — shorter than the shortest real answer, and far longer than
  /// a bare header. Under it the PCM buffer is used instead, and if that is
  /// empty too the capture is rebuilt.
  static const _minEncodedBytes = 1200;

  /// The browser's Opus recorder for this turn, when it can do it.
  ///
  /// Opus is ~3 KB/s against WAV's 32, and the upload is the largest part of a
  /// spoken turn. The device itself is opened once per conversation, not per
  /// turn — see `opus_capture_web.dart` for why that distinction cost a
  /// deploy.
  OpusCapture? _opus;

  StreamSubscription<Uint8List>? _webSub;
  StreamSubscription<rec.Amplitude>? _ampSub;
  BytesBuilder? _webBuffer;

  /// Whether the arriving audio belongs to a turn or is being discarded.
  bool _capturing = false;

  /// Where the current turn's loudness goes. Re-pointed each turn; the stream
  /// underneath it does not change.
  ///
  /// The second argument is how much audio that reading covers. It used to be
  /// left out and re-derived from a wall clock on the other side, which is not
  /// the same thing: chunks arrive in bursts under load, so the detector was
  /// told a burst of five readings spanned no time at all and then that the
  /// next one spanned half a second. The frame count is exact and free.
  void Function(double level, Duration span)? _webLevel;

  /// The rate the capture is REALLY running at. Asked for 16 kHz; Safari and
  /// the iOS WKWebView hand back the device rate instead, and every place that
  /// assumed otherwise was wrong by the same factor. See [SampleRateProbe].
  final SampleRateProbe _probe = SampleRateProbe(requested: _webSampleRate);

  /// Measured, or the requested rate until enough audio has arrived to know.
  int get _rate => _probe.rate;

  /// The same number, for telemetry. Native records at a fixed rate it chooses
  /// itself, so this only ever varies on the web.
  int get sampleRate => kIsWeb ? _probe.rate : _webSampleRate;

  /// Whether the rate above was measured or is still the assumption. Reported
  /// with the turn: a device that never settles should be visible.
  bool get rateMeasured => _probe.isMeasured;

  /// Whether the microphone is still delivering audio — see [CaptureHealth],
  /// which is where the reasoning lives.
  final CaptureHealth _health = CaptureHealth();

  /// How long the capture has been delivering nothing; zero when none is open.
  Duration get sinceLastAudio => _health.sinceLastAudio;

  /// Open, but silent for longer than a working capture ever is. The one
  /// question about the microphone that no flag can answer falsely.
  bool get isStalled => _health.isStalled;

  /// Delivering buffers that contain no sound at all — a muted track. Treated
  /// exactly like a stall by the healer, because to the learner it is one.
  bool get isDeaf => _health.isDeaf;

  /// Below this a buffer carries no sound. Not zero: a real microphone has a
  /// noise floor and dither, so demanding exact silence would never fire. This
  /// is far under any room and orders of magnitude under any voice.
  static const double _silenceFloor = 0.0005;

  /// How much audio one loudness reading covers on the web path.
  ///
  /// A chunk can carry a quarter of a second, and one RMS over all of it
  /// averages a word into the quiet around it — the detector then sees a flat
  /// murmur where there was a syllable and a pause. Sliced this fine, a word
  /// stays a word.
  static const _levelWindow = Duration(milliseconds: 50);

  /// Why the last turn was uploaded as WAV instead of Opus, or "" when it was
  /// not.
  ///
  /// The fallback is silent by design — a turn must never fail because a codec
  /// did — and that is exactly what made it impossible to explain a 400 KB
  /// upload from a phone. One word here turns "it is slow on mobile" into a
  /// question with an answer.
  String lastFallbackReason = '';

  /// Whether mic access is granted; requests it from the OS/browser if not
  /// yet decided.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Break one PCM chunk into fixed windows and report each one's loudness.
  ///
  /// Fixed *by duration*, so the detector's clock advances with the audio and
  /// not with whenever the browser got round to delivering it. A remainder
  /// shorter than a window is still reported, carrying its own true length.
  void _reportLevels(Uint8List chunk) {
    final sink = _webLevel;
    if (sink == null) return;
    final frames = chunk.length ~/ 2;
    if (frames == 0) return;
    final perWindow =
        (_rate * _levelWindow.inMilliseconds / 1000).round();
    if (perWindow <= 0) {
      sink(rms(chunk), Duration.zero);
      return;
    }
    for (var start = 0; start < frames; start += perWindow) {
      final end = math.min(start + perWindow, frames);
      final window = Uint8List.sublistView(chunk, start * 2, end * 2);
      sink(
        rms(window),
        Duration(microseconds: ((end - start) / _rate * 1e6).round()),
      );
    }
  }

  Future<void> start({
    void Function(double level) onLevel = _ignoreLevel,
    void Function(double level, Duration span)? onSpan,
  }) async {
    if (kIsWeb) {
      // A turn is a buffer, not a stream.
      //
      // The dialog belongs to `getUserMedia`, which `startStream` calls — so
      // starting the stream per turn asked permission per turn. It is started
      // once instead, and kept running until the conversation closes.
      _webLevel = onSpan ?? (level, _) => onLevel(level);
      _webBuffer = BytesBuilder(copy: false);
      _capturing = true;

      // The PCM stream is settled FIRST, and the order is load-bearing:
      // rebuilding it tears the encoder down too, so an encoder started before
      // this point would be thrown away the moment it was needed.
      //
      // Reuse the stream only if it is demonstrably alive. The old code reused
      // it on the strength of the handle being non-null, which is also true of
      // a capture that has been silently dead for minutes — and then every turn
      // recorded nothing while the app looked like it was listening. Typing
      // still worked, so it read as a microphone permission problem.
      if (_webSub != null && isStalled) await _releaseWebCapture();
      final reusing = _webSub != null;

      // Alongside, not instead: the PCM stream drives the level meter and the
      // silence detector that ends a turn, and it is the fallback.
      //
      // A previous turn's encoder may still be running — `_releaseWebCapture`
      // rebuilds the PCM stream and cannot reach this one. Overwriting it left
      // a MediaRecorder attached to the shared device with nobody to stop it.
      _opus?.cancel();
      if (!OpusCapture.isSupported) {
        _opus = null;
        // Says WHICH way it failed: no MediaRecorder at all, or a
        // MediaRecorder that knows none of the containers we can use.
        lastFallbackReason = lastCodecFailure.isEmpty
            ? 'unsupported'
            : lastCodecFailure;
      } else {
        _opus = await OpusCapture.start();
        lastFallbackReason = _opus == null ? 'start_failed' : '';
      }

      if (reusing) return;

      _health.opened();
      // A rebuilt stream can come back at a different rate than the one that
      // died, so the measurement starts again with it.
      _probe.reset();
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
          // Stamped first, and outside the turn: this measures the microphone,
          // not the conversation. See [CaptureHealth].
          // Whether the buffer carries SOUND, not merely whether it arrived. A
          // muted track keeps delivering zeros for ever, and counting those as
          // health is what let a dead microphone look perfectly well.
          _health.heard(silent: rms(chunk) <= _silenceFloor);
          // Likewise outside the turn — the rate is a property of the device,
          // and waiting for a turn to learn it would mean the first turn of
          // every session is written with the wrong header.
          _probe.heard(chunk.length ~/ 2);
          // Between turns the stream keeps arriving and is thrown away. Cheaper
          // and far less fragile than tearing the microphone down and asking for
          // it again, which is the thing that was going wrong.
          if (!_capturing) return;
          _webBuffer?.add(chunk);
          _reportLevels(chunk);
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
        onDone: () => unawaited(_releaseWebCapture()),
        onError: (Object _) => unawaited(_releaseWebCapture()),
        cancelOnError: true,
      );
      return;
    }
    _health.opened();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amp) {
      _health.heard();
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

  /// Tear the web capture down so the next turn builds a genuinely new one.
  ///
  /// Dropping the Dart subscription is not enough, and that was the bug: the
  /// `record` recorder underneath was left running, so the next `startStream`
  /// handed back the same dead capture instead of opening a fresh one. The
  /// symptom was a conversation that went deaf after a couple of turns and
  /// never recovered — typing still worked, which is what made it look like a
  /// microphone permission problem rather than a stream that had stopped
  /// delivering.
  ///
  /// Suspected trigger, now that the tutor speaks through the browser: an
  /// utterance from the speech engine can suspend the audio context the
  /// recorder's worklet runs on. Whatever the cause, the recovery has to
  /// actually rebuild.
  Future<void> _releaseWebCapture() async {
    await _webSub?.cancel();
    _webSub = null;
    _health.closed();
    // The Opus encoder is a SECOND capture of the same device, and it does not
    // survive the rebuild either. Left running it kept collecting chunks nobody
    // would ever read, on a track that in the stalled case carries no sound.
    _opus?.cancel();
    _opus = null;
    try {
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {
      // Already gone; the point is only that the next start is a fresh one.
    }
  }

  Future<bool> isRecording() => _recorder.isRecording();

  /// Stop and return the recorded clip, or null if nothing was captured.
  ///
  /// [onStage] reports the two waits inside this method — `recorder_stopped`
  /// when the platform has handed over the last of the audio, and `bytes_ready`
  /// when it is one uploadable buffer. They are separate because their causes
  /// are: the first is the recorder's own flush, the second is encoding or a
  /// file read. Purely a measurement hook; omitting it changes nothing.
  Future<AudioClip?> stop({void Function(String stage)? onStage}) async {
    if (kIsWeb) {
      // The turn ends. The microphone does not.
      _capturing = false;
      final opus = _opus;
      _opus = null;
      final encoded = opus == null ? null : await opus.stop(onStage: onStage);

      final pcm = _webBuffer?.takeBytes();
      _webBuffer = null;

      // The extension is the only codec hint the transcriber gets.
      //
      // `isNotEmpty` was too weak a test. A MediaRecorder on a track that has
      // gone silent still emits its container header — a few hundred bytes of
      // perfectly valid WebM holding no audio — so the turn passed this check,
      // skipped the PCM fallback, and uploaded silence. The learner had spoken;
      // the transcript came back empty; nothing anywhere said why.
      if (encoded != null && encoded.length < _minEncodedBytes) {
        lastFallbackReason = 'too_small_${encoded.length}';
      } else if (encoded == null && lastFallbackReason.isEmpty) {
        lastFallbackReason = 'no_bytes';
      }
      if (encoded != null && encoded.length >= _minEncodedBytes) {
        return AudioClip(
          bytes: encoded,
          filename:
              // The extension is the only codec hint the transcriber gets,
              // and the recorder now has eight containers to choose from.
              'turn.${extensionFor(opus!.mimeType)}',
        );
      }
      if (pcm == null || pcm.isEmpty) {
        // A turn that captured nothing means the track stopped delivering
        // without ending the Dart stream — the quieter half of the same
        // failure, and the one `onDone` above cannot catch. Rebuild so the next
        // turn records rather than returning nothing for ever.
        await _releaseWebCapture();
        return null;
      }
      final wav = AudioClip(
        // Trimmed first: the silence at each end is bytes nobody says and
        // seconds nobody hears, and the upload is the largest part of a turn.
        bytes: wavFromPcm16(
          trimSilence(pcm, sampleRate: _rate),
          sampleRate: _rate,
          numChannels: 1,
        ),
        filename: _webFilename,
      );
      // The fallback path reaches here having skipped the encoder's stages, so
      // it reports its own. Without this a WAV turn would look as though its
      // audio appeared instantly, which is the opposite of the truth.
      onStage?.call(TurnTimeline.mRecorderStopped);
      onStage?.call(TurnTimeline.mBytesReady);
      return wav;
    }
    await _ampSub?.cancel();
    _ampSub = null;
    // Native really does close between turns — unlike the web stream, which is
    // held open on purpose. Saying so keeps a closed capture from ageing into a
    // "stalled" one that the healer would then rebuild for no reason.
    _health.closed();
    final path = await _recorder.stop();
    onStage?.call(TurnTimeline.mRecorderStopped);
    if (path == null) return null;
    // Native writes the clip to disk and reads it back. That round trip has no
    // counterpart on the web, and it is invisible in any server-side number.
    final bytes = await nativeReadBytes(path);
    onStage?.call(TurnTimeline.mBytesReady);
    return AudioClip(bytes: bytes, filename: _nativeFilename);
  }

  /// The utterance so far, WITHOUT ending the turn — or null when this
  /// platform/turn cannot provide one.
  ///
  /// Taken when the learner goes quiet, so the clip can be transcribed during
  /// the grace period the detector is about to spend waiting. Recording carries
  /// on regardless: if they were only thinking, the snapshot is discarded and
  /// the eventual clip still holds every word.
  ///
  /// Opus only. The WAV fallback could technically be snapshotted from the PCM
  /// buffer, but it is 32 KB per second against Opus's 3 — speculating with it
  /// would upload half a megabyte that is usually thrown away, which costs the
  /// learner more than the wait it saves.
  Future<AudioClip?> snapshot() async {
    if (!kIsWeb || !_capturing) return null;

    // The encoder first: its output is a tenth the size, which on a phone
    // uplink is most of what the speculation is trying to buy back.
    final encoded = await _opus?.snapshot();
    if (encoded != null && encoded.length >= _minEncodedBytes) {
      return AudioClip(
        bytes: encoded,
        filename: 'turn.${extensionFor(_opus!.mimeType)}',
      );
    }

    // Then the PCM the level meter is already collecting — and this is the
    // path that matters, because the encoder is exactly what a Telegram
    // Android WebView does not have.
    //
    // Without this branch the speculation was dead on the platform it was
    // written for: no MediaRecorder meant no snapshot, no snapshot meant no
    // early transcription, and the two seconds it exists to fill were spent
    // waiting after all. It was invisible because every failure here is meant
    // to look like "no speculation this turn".
    //
    // `takeBytes` must NOT be used: the turn still owns that buffer, and
    // emptying it here would upload a recording missing everything said so
    // far. The bytes are copied instead.
    final pcm = _webBuffer?.toBytes();
    if (pcm == null || pcm.isEmpty) return null;
    // Trimmed exactly as the finished turn trims it, so the clip the turn
    // uploads is byte-for-byte what was transcribed ahead — the cache is keyed
    // on those bytes, and a different trim would be a guaranteed miss.
    final trimmed = trimSilence(pcm, sampleRate: _rate);
    if (trimmed.isEmpty) return null;
    return AudioClip(
      bytes: wavFromPcm16(
        trimmed,
        sampleRate: _rate,
        numChannels: 1,
      ),
      filename: _webFilename,
    );
  }

  /// Abort an in-progress recording, discarding it.
  Future<void> cancel() async {
    if (kIsWeb) {
      // Abandoning a turn is not leaving the conversation, so the stream stays.
      _opus?.cancel();
      _opus = null;
      _capturing = false;
      _webBuffer = null;
      return;
    }
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _ampSub?.cancel();
    _ampSub = null;
    _health.closed();
  }

  /// Close the microphone. For leaving the conversation — and only there,
  /// because releasing it between turns is the whole bug.
  /// Rebuild the capture before the next turn, without ending the session.
  ///
  /// Called after the tutor has spoken on the device engine: an utterance can
  /// leave the recorder's audio context suspended, and waiting to discover that
  /// through an empty recording costs the learner a whole turn — they speak,
  /// nothing is captured, and the app simply does not answer.
  Future<void> refreshCapture() async {
    if (!kIsWeb) return;
    await _releaseWebCapture();
  }

  Future<void> endSession() async {
    _capturing = false;
    _webLevel = null;
    _webBuffer = null;
    _health.closed();
    await _webSub?.cancel();
    _webSub = null;
    // The Opus device goes back HERE, not only in `dispose`.
    //
    // The chat screen ends the conversation with `endSession`, and never calls
    // `dispose` at all — so the shared stream outlived the screen. Two costs,
    // and the second is the expensive one: a microphone indicator that never
    // goes out, which learners read as being listened to; and a stream left to
    // be reclaimed in the background, so the NEXT conversation started from a
    // dead track and recorded nothing through it.
    _opus?.cancel();
    _opus = null;
    releaseOpusMicrophone();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> dispose() async {
    await endSession();
    await _recorder.dispose();
  }
}
