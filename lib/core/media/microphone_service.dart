import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'mic_permission_stub.dart'
    if (dart.library.js_interop) 'mic_permission_web.dart';

/// What the platform says about the microphone, without asking for it.
enum MicPermission {
  /// Already allowed. Opening the microphone will show no dialog.
  granted,

  /// Never decided. Opening the microphone WILL show a dialog, so it has to
  /// happen inside a user gesture.
  prompt,

  /// Refused in a way the app cannot undo — "don't ask again", a blocked site
  /// permission, or an OS restriction. Asking again shows nothing.
  denied,

  /// The platform will not say. Safari does not answer for `microphone`, and
  /// some WebViews have no Permissions API at all. Treated as [prompt]: ask,
  /// from a gesture, and find out.
  unsupported,
}

/// Why the microphone could not be opened.
///
/// One value per thing the learner can actually do something about. The point
/// of separating them is the message: "allow it" and "close the other app
/// using your microphone" are different instructions, and telling somebody the
/// wrong one wastes their time.
enum MicFailure {
  /// The prompt was shown and dismissed or refused.
  denied,

  /// Refused permanently — the prompt will not appear again. Only a trip to
  /// browser/Telegram/OS settings fixes this.
  blocked,

  /// No microphone on the device.
  notFound,

  /// A microphone exists but something else holds it.
  busy,

  /// Not a secure context, so the browser hides `mediaDevices` entirely.
  insecureContext,

  /// No device could satisfy the requested constraints.
  constraints,

  unknown,
}

class MicException implements Exception {
  const MicException(this.failure);

  final MicFailure failure;

  @override
  String toString() => 'MicException(${failure.name})';
}

/// The one place the microphone is opened, held and given back.
///
/// It exists because of *when*, not *how*. The peer call used to open the
/// microphone inside `_ensurePeerConnection`, which runs from a WebSocket
/// frame — after matchmaking, which can take minutes. By then the browser's
/// user activation is long gone, and platforms that require the request to sit
/// inside a gesture (iOS WebViews above all) simply refuse without showing a
/// dialog. The button looked dead because the platform never asked.
///
/// So acquisition moved to the tap that starts the search, and the stream is
/// parked here until the call that needs it is over. Nothing else changed
/// about the call.
///
/// Deliberately NOT an app-wide always-on stream: a live microphone lights the
/// recording indicator, and one that never goes out reads as spyware. It is
/// held from the tap until [release], which the call's own teardown calls.
class MicrophoneService {
  MicrophoneService();

  /// The audio settings the call has always used. Unchanged — they are here
  /// only because this is now the single place `getUserMedia` is called from.
  static const Map<String, dynamic> _constraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    'video': false,
  };

  MediaStream? _stream;

  /// In-flight acquisition, so a double tap asks the platform once.
  Future<MediaStream>? _pending;

  /// What the platform will do if we ask right now. Never prompts.
  Future<MicPermission> checkPermission() async {
    final state = await MicPermissionPlatform.query();
    return switch (state) {
      'granted' => MicPermission.granted,
      'prompt' => MicPermission.prompt,
      'denied' => MicPermission.denied,
      _ => MicPermission.unsupported,
    };
  }

  /// The prepared stream, or null when there is not a usable one.
  ///
  /// **Never acquires.** This is what the call reads once a partner is found,
  /// and that read happens inside a WebSocket callback where opening the
  /// microphone is exactly the thing that does not work.
  ///
  /// A stream whose tracks have all ended is dropped rather than returned: a
  /// dead track negotiates fine and carries no audio, which is the worst
  /// possible failure — a call that connects to silence.
  MediaStream? get liveStream {
    final stream = _stream;
    if (stream == null) return null;
    if (!_isUsable(stream)) {
      _stream = null;
      unawaited(_disposeStream(stream));
      return null;
    }
    return stream;
  }

  bool get hasLiveStream => liveStream != null;

  /// A microphone, ready to publish. **Must be called from a user gesture.**
  ///
  /// Reuses the parked stream when it is still live, so entering a second call
  /// in the same session opens nothing and asks nothing.
  ///
  /// Throws [MicException] and never returns a stream without a live audio
  /// track — a caller that gets a value back can publish with it.
  Future<MediaStream> getOrCreateStream() {
    final existing = liveStream;
    if (existing != null) return Future.value(existing);
    final inFlight = _pending;
    if (inFlight != null) return inFlight;

    final future = _acquire();
    _pending = future;
    // The bookkeeping branch swallows the failure; the caller still gets it
    // through the future returned below. Without the swallow a refused
    // microphone would also surface as an unhandled async error.
    unawaited(
      future.then<void>((_) {}, onError: (_) {}).whenComplete(() {
        if (identical(_pending, future)) _pending = null;
      }),
    );
    return future;
  }

  /// The whole preparation step: **`getUserMedia` and nothing before it.**
  ///
  /// There used to be a permission query here, to short-circuit a learner whose
  /// microphone is blocked before bothering the platform. It has been removed,
  /// deliberately, and the reason is the only reason that matters on this path:
  /// `navigator.permissions.query` is a promise, and awaiting it hands control
  /// back to the event loop **between the learner's tap and the request the tap
  /// exists to justify**. Chrome tolerates that; WebKit's activation model is
  /// stricter, and Telegram's iOS WebView is WebKit. A pre-flight check that
  /// costs the dialog is not a check worth having.
  ///
  /// Nothing is lost by dropping it. A blocked microphone fails fast and
  /// silently anyway, and [_classify] queries permission **after** the failure —
  /// where an await is free — so "you dismissed the prompt" and "this origin is
  /// blocked" are still told apart, and still get different instructions.
  ///
  /// So the entire happy path is: a live stream we already hold, or one
  /// `getUserMedia` call. No awaits in between.
  Future<MediaStream> prepare() => getOrCreateStream();

  /// Give the microphone back. Idempotent.
  Future<void> release() async {
    final stream = _stream;
    _stream = null;
    if (stream != null) await _disposeStream(stream);
  }

  Future<MediaStream> _acquire() async {
    final MediaStream stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia(_constraints);
    } catch (error) {
      throw MicException(await _classify(error));
    }
    if (!_isUsable(stream)) {
      await _disposeStream(stream);
      throw const MicException(MicFailure.notFound);
    }
    // A track can end under us — the device is unplugged, the OS hands it to a
    // phone call, the learner revokes permission mid-session. Dropping the
    // cache here means the next caller re-acquires instead of publishing a
    // corpse.
    for (final track in stream.getAudioTracks()) {
      track.onEnded = () {
        if (identical(_stream, stream) && !_isUsable(stream)) _stream = null;
      };
    }
    _stream = stream;
    return stream;
  }

  /// Live if at least one audio track has not ended.
  ///
  /// `MediaStream.active` is the cross-platform reading of exactly that, and
  /// the only one available: `MediaStreamTrack.readyState` is not exposed by
  /// `webrtc_interface`. `active` is nullable on platforms that do not report
  /// it, where the presence of a track is the best answer there is.
  static bool _isUsable(MediaStream stream) =>
      stream.getAudioTracks().isNotEmpty && (stream.active ?? true);

  static Future<void> _disposeStream(MediaStream stream) async {
    for (final track in stream.getTracks()) {
      track.onEnded = null;
      try {
        await track.stop();
      } catch (_) {
        // Already gone. Nothing to release and nothing to report.
      }
    }
    try {
      await stream.dispose();
    } catch (_) {}
  }

  /// Which failure this was.
  ///
  /// Matched on the message text because that is what the platforms give us:
  /// `dart_webrtc` rethrows every web failure as a plain String
  /// (`'Unable to getUserMedia: NotAllowedError: ...'`), so the DOMException
  /// name survives only inside that sentence. Native throws a
  /// `PlatformException` whose text carries the same names.
  ///
  /// Permission is re-queried before reporting a refusal, so "you dismissed
  /// the prompt" and "this origin is blocked" are told apart — they need
  /// different instructions and are indistinguishable from the error alone.
  ///
  /// **This is now the only place permission is queried**, and the placement is
  /// the point: here the request has already failed, so an await costs nothing.
  /// On the way IN it would have cost the permission dialog — see [prepare].
  Future<MicFailure> _classify(Object error) async {
    final text = error.toString().toLowerCase();

    bool has(String needle) => text.contains(needle);

    if (has('notallowederror') ||
        has('permissiondenied') ||
        has('permission denied') ||
        has('not allowed by the user')) {
      return await checkPermission() == MicPermission.denied
          ? MicFailure.blocked
          : MicFailure.denied;
    }
    if (has('notfounderror') ||
        has('devicesnotfound') ||
        has('requested device not found')) {
      return MicFailure.notFound;
    }
    if (has('notreadableerror') ||
        has('trackstarterror') ||
        has('could not start audio source')) {
      return MicFailure.busy;
    }
    if (has('overconstrained') || has('constraintnotsatisfied')) {
      return MicFailure.constraints;
    }
    // On an insecure origin the browser does not define `mediaDevices` at all,
    // so the failure arrives as a null/undefined access rather than as a
    // SecurityError.
    if (has('securityerror') ||
        (has('mediadevices') && (has('null') || has('undefined')))) {
      return MicFailure.insecureContext;
    }
    return MicFailure.unknown;
  }
}
