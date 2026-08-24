/// Naming a recorded container so the transcriber can read it.
///
/// Pure string logic, in its own file on purpose: it belongs to the browser
/// recorder but needs no browser, and keeping it importable from the VM is
/// what lets it be tested at all. The web capture file it came from imports
/// `dart:js_interop`, which cannot be loaded outside a browser.
library;

/// The file extension for a recorded container.
///
/// The extension is the ONLY codec hint the transcriber gets, so a wrong one
/// is a failed turn — and it has to be one Whisper accepts, which is a shorter
/// list than the one browsers record into. AAC goes up as `.m4a`, its
/// container name there, because `.aac` is not on it.
///
/// The failure this prevents is silent and blames the learner: a clip Whisper
/// cannot read comes back as an empty transcript, which the app reports as
/// "I did not hear you".
String extensionFor(String mimeType) {
  final m = mimeType.toLowerCase();
  if (m.startsWith('audio/ogg')) return 'ogg';
  if (m.startsWith('audio/mp4')) return 'mp4';
  if (m.startsWith('audio/aac')) return 'm4a';
  if (m.startsWith('audio/mpeg')) return 'mp3';
  return 'webm';
}
