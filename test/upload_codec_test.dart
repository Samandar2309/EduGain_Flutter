import 'package:edugain/features/speaking/data/upload_codec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Naming the container so the transcriber can read it.
///
/// The extension is the ONLY codec hint Whisper gets. It is also a shorter
/// list than the one browsers record into — which is why AAC is sent as
/// `.m4a`, the container's name there, rather than `.aac`, which is not on it.
///
/// This matters because the fallback is silent: a clip Whisper cannot read
/// comes back as an empty transcript, which the app reports as "I did not hear
/// you" — blaming the learner for a naming mistake.
void main() {
  test('opus containers keep their own names', () {
    expect(extensionFor('audio/webm;codecs=opus'), 'webm');
    expect(extensionFor('audio/ogg;codecs=opus'), 'ogg');
  });

  test('aac is named the way Whisper accepts it', () {
    expect(extensionFor('audio/aac'), 'm4a');
  });

  test('mp4 and mpeg are themselves', () {
    expect(extensionFor('audio/mp4;codecs=mp4a.40.2'), 'mp4');
    expect(extensionFor('audio/mpeg'), 'mp3');
  });

  test('an unknown container falls back to the common one', () {
    expect(extensionFor('audio/something-new'), 'webm');
  });

  test('case does not decide it', () {
    expect(extensionFor('AUDIO/OGG;CODECS=OPUS'), 'ogg');
  });
}
