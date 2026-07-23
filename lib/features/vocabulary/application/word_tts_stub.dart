/// Non-web fallback: no browser speech engine, so pronunciation is a no-op.
/// (The primary surface is the Telegram Mini App / web; native TTS could be
/// added later via a plugin if the installed app needs it.)
class WordTtsPlatform {
  static bool get supported => false;
  static void speak(String word) {}
  static void stop() {}
}
