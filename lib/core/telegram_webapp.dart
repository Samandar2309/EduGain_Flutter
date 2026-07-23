import 'telegram_webapp_stub.dart'
    if (dart.library.js_interop) 'telegram_webapp_web.dart';

/// Bridge to Telegram's Mini App JS SDK (`telegram-web-app.js`, loaded in
/// `web/index.html`). On every platform except web this is entirely inert —
/// [initData] is always null, so [[edugain-telegram-bot-mvp]]'s phone/Google
/// login flow is completely unaffected; only a page opened inside Telegram's
/// WebView ever sees a non-null [initData].
class TelegramWebApp {
  const TelegramWebApp._();

  /// The signed `initData` string Telegram hands the page. Verified
  /// server-side (`POST /api/v1/auth/telegram/webapp`) before being trusted —
  /// never parsed or acted on client-side.
  static String? get initData => TelegramWebAppPlatform.initData;

  /// Whether the page is running inside a Telegram Mini App (non-null initData
  /// is present only there). Drives the registration gate: inside Telegram,
  /// registration happens in the bot, so the in-app phone/Google flow is hidden.
  static bool get isTelegram => initData != null;

  /// Tells Telegram the app finished loading (hides its splash/spinner).
  static void ready() => TelegramWebAppPlatform.ready();

  /// Requests the maximum available viewport height.
  static void expand() => TelegramWebAppPlatform.expand();

  /// Opens a t.me link (the bot) inside Telegram — used to send an
  /// unregistered learner back to the bot to finish signing up.
  static void openTelegramLink(String url) =>
      TelegramWebAppPlatform.openTelegramLink(url);

  /// Closes the Mini App, returning the user to the bot chat.
  static void close() => TelegramWebAppPlatform.close();
}
