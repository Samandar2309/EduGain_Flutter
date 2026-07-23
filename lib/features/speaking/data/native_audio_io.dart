import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

// Selected on every platform except web (see `native_audio_io_stub.dart`).
Future<String> nativeTempFilePath(String filename) async {
  final dir = await getTemporaryDirectory();
  return '${dir.path}/$filename';
}

Future<Uint8List> nativeReadBytes(String path) => File(path).readAsBytes();
