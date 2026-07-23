import 'dart:js_interop';

extension type _JSTelegram._(JSObject _) implements JSObject {
  @JS('WebApp')
  external _JSWebApp? get webApp;
}

extension type _JSWebApp._(JSObject _) implements JSObject {
  external String? get initData;
  external void ready();
  external void expand();
  external void openTelegramLink(String url);
  external void close();
}

@JS('Telegram')
external _JSTelegram? get _telegram;

/// The real bridge to `window.Telegram.WebApp`, present only when the page
/// is opened as a Telegram Mini App (the SDK script in `web/index.html`
/// defines it as a no-op-free global everywhere else, so plain browser
/// visits just see `undefined`).
class TelegramWebAppPlatform {
  static String? get initData {
    try {
      final data = _telegram?.webApp?.initData;
      return (data != null && data.isNotEmpty) ? data : null;
    } catch (_) {
      return null;
    }
  }

  static void ready() {
    try {
      _telegram?.webApp?.ready();
    } catch (_) {
      // Not running inside Telegram — nothing to signal.
    }
  }

  static void expand() {
    try {
      _telegram?.webApp?.expand();
    } catch (_) {
      // Not running inside Telegram — nothing to expand.
    }
  }

  /// Opens a t.me link (e.g. the bot) inside Telegram and closes the Mini App.
  static void openTelegramLink(String url) {
    try {
      _telegram?.webApp?.openTelegramLink(url);
    } catch (_) {
      // Not running inside Telegram — nothing to open.
    }
  }

  static void close() {
    try {
      _telegram?.webApp?.close();
    } catch (_) {
      // Not running inside Telegram — nothing to close.
    }
  }
}
