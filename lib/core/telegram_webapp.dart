import 'package:flutter/foundation.dart';

import 'telegram_insets.dart';
import 'telegram_webapp_stub.dart'
    if (dart.library.js_interop) 'telegram_webapp_web.dart';

export 'telegram_insets.dart' show TelegramInsets;

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
  ///
  /// Stable for the life of the page once [waitForSdk] has run — every reader
  /// must agree, or startup and the router reach opposite conclusions and the
  /// learner is trapped on the register screen.
  static bool get isTelegram => initData != null;

  /// Whether Telegram's SDK global exists at all. Separates "this is a plain
  /// browser" from "this is Telegram, but it gave us no initData".
  static bool get sdkPresent => TelegramWebAppPlatform.sdkPresent;

  /// Resolve [initData] once, waiting briefly for the remote SDK script.
  /// Called from `main()` before the first widget is built.
  static Future<void> waitForSdk() => TelegramWebAppPlatform.waitForSdk();

  /// Tells Telegram the app finished loading (hides its splash/spinner).
  static void ready() => TelegramWebAppPlatform.ready();

  /// Requests the maximum available viewport height.
  static void expand() => TelegramWebAppPlatform.expand();

  /// Hand the whole screen back if Telegram is still giving it to us.
  ///
  /// Telegram remembers the mode a Mini App was last opened in, so a single
  /// `requestFullscreen()` — since reverted — kept coming back on every launch
  /// from the chat list. Not asking is not the same as saying no.
  static void exitFullscreen() => TelegramWebAppPlatform.exitFullscreen();

  /// Stop Telegram closing the app when somebody scrolls (Bot API 7.7).
  ///
  /// Its dismiss gesture is a downward drag, which is also how a list is
  /// scrolled back to the top — so on a long screen the app closed itself
  /// mid-read. Reported as "the bot just exits".
  static void disableVerticalSwipes() =>
      TelegramWebAppPlatform.disableVerticalSwipes();

  /// Where the app must not draw — the system navigation buttons, the notch.
  static ValueListenable<TelegramInsets> get insets =>
      TelegramWebAppPlatform.insets;

  /// Begin following the safe area. Called once from `main()`.
  static void watchInsets() => TelegramWebAppPlatform.watchInsets();

  /// Opens a t.me link (the bot) inside Telegram — used to send an
  /// unregistered learner back to the bot to finish signing up.
  static void openTelegramLink(String url) =>
      TelegramWebAppPlatform.openTelegramLink(url);

  /// Whether the Telegram client is new enough for [shareMessage] (Bot API
  /// 8.0). Older clients reject the call instead of opening anything.
  static bool get canShareMessage =>
      isTelegram && TelegramWebAppPlatform.isVersionAtLeast('8.0');

  /// Opens Telegram's "choose a chat" sheet over the still-running Mini App,
  /// for a message the bot registered via `POST /invite/prepare`. Returns
  /// whether the client accepted it.
  static bool shareMessage(String preparedMessageId) =>
      TelegramWebAppPlatform.shareMessage(preparedMessageId);

  /// Closes the Mini App, returning the user to the bot chat.
  static void close() => TelegramWebAppPlatform.close();
}
