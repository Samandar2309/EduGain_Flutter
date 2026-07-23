/// No-op implementation selected on every platform except web (native
/// mobile builds never run inside a Telegram Mini App WebView).
class TelegramWebAppPlatform {
  static String? get initData => null;
  static void ready() {}
  static void expand() {}
  static void openTelegramLink(String url) {}
  static void close() {}
}
