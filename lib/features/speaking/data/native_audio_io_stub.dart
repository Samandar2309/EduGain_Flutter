import 'dart:typed_data';

// Selected on web, where there is no filesystem — [SpeechRecorder]'s web
// branch never calls these, so they exist only to satisfy the conditional
// import (and keep `dart:io` out of the web compilation unit entirely).
Future<String> nativeTempFilePath(String filename) =>
    throw UnsupportedError('Native file I/O is not available on web');

Future<Uint8List> nativeReadBytes(String path) =>
    throw UnsupportedError('Native file I/O is not available on web');
