import 'dart:typed_data';

/// Opus capture is a browser feature. Off the web there is nothing to do —
/// native builds already record AAC, which is compressed.
/// Nothing is held off the web, so nothing needs releasing.
void releaseOpusMicrophone() {}

class OpusCapture {
  /// Never on this platform, so callers keep their existing path.
  static bool get isSupported => false;

  static Future<OpusCapture?> start() async => null;

  /// Never read — `start` returns null off the web — but the two sides of a
  /// conditional import have to agree on the surface.
  String get mimeType => '';

  Future<Uint8List?> stop() async => null;

  void cancel() {}
}
