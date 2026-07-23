import 'word_tts_stub.dart'
    if (dart.library.js_interop) 'word_tts_web.dart';

/// Speaks an English word aloud so the learner hears how it's pronounced.
/// Backed by the browser's built-in speech synthesis inside the Telegram Mini
/// App (web); a no-op on platforms without it. Zero backend, zero cost.
class WordTts {
  const WordTts._();

  static bool get supported => WordTtsPlatform.supported;

  static void speak(String word) {
    final w = word.trim();
    if (w.isEmpty) return;
    WordTtsPlatform.speak(w);
  }

  static void stop() => WordTtsPlatform.stop();
}
