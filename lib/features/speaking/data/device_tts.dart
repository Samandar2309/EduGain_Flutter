/// The tutor's voice, spoken by the device instead of fetched from a provider.
///
/// Free, instant (no network hop) and unmetered — against a cloud voice that is
/// both the largest line on the bill and the least reliable part of a turn. The
/// trade is quality and consistency: the voice varies per handset, some have no
/// English voice at all, and the avatar's lip-sync has no audio samples to
/// follow. `supported` is what every caller checks first.
library;
export 'device_tts_stub.dart' if (dart.library.js_interop) 'device_tts_web.dart';
