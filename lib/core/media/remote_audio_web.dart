import 'dart:js_interop';

@JS('document')
external _JSDocument? get _document;

extension type _JSDocument._(JSObject _) implements JSObject {
  external _JSNodeList querySelectorAll(String selectors);
}

extension type _JSNodeList._(JSObject _) implements JSObject {
  external int get length;
  external JSObject? item(int index);
}

extension type _JSMediaElement._(JSObject _) implements JSObject {
  external JSPromise<JSAny?>? play();
  external bool get paused;
  external set muted(bool value);
}

/// Start any remote audio the browser refused to autoplay.
///
/// `flutter_webrtc` hands the remote stream to an `<audio autoplay>` element it
/// appends to a hidden div, and never calls `play()` or handles a rejected
/// autoplay promise. On Chrome that is fine. WebKit will not start an unmuted
/// element whose source arrived outside a user gesture — and ours arrives from
/// a WebSocket callback, because that is when the track shows up.
///
/// The result on iOS is the worst kind of failure: `connectionState` reports
/// `connected`, the call timer runs, and the learner hears nothing.
///
/// Called after the connection is established, from inside the tap chain that
/// opened the microphone — so the page still has an activation to spend.
/// Deliberately best-effort: an element that is already playing ignores a
/// second `play()`, and a rejection here is not worth failing a call over.
void unlockRemoteAudio() {
  try {
    final elements = _document?.querySelectorAll('audio');
    if (elements == null) return;
    for (var i = 0; i < elements.length; i++) {
      final node = elements.item(i);
      if (node == null) continue;
      final media = node as _JSMediaElement;
      // Never unmute anything: the local monitor element is muted on purpose,
      // and unmuting it would echo the learner back at themselves.
      if (!media.paused) continue;
      media.play()?.toDart.catchError((Object _) {
        // Still blocked. Nothing further to try without another gesture.
        return null;
      });
    }
  } catch (_) {
    // No document, no elements, an engine that disagrees about the shape of
    // any of this — none of it is worth breaking a working call for.
  }
}
