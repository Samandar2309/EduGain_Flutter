import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'telegram_insets.dart';

extension type _JSTelegram._(JSObject _) implements JSObject {
  @JS('WebApp')
  external _JSWebApp? get webApp;
}

extension type _JSWebApp._(JSObject _) implements JSObject {
  external String? get initData;
  external void ready();
  external void expand();
  external void openTelegramLink(String url);
  external bool isVersionAtLeast(String version);
  external void shareMessage(String preparedMessageId);
  external void close();

  // ── fullscreen (Bot API 8.0) ──────────────────────────────────────────
  external void requestFullscreen();

  /// Which client is running this. Fullscreen is a phone feature: the desktop
  /// and web clients raise `WebAppMethodUnsupported` for it.
  external String? get platform;

  /// The device's own unsafe strips — notch, status bar, home indicator.
  external _JSInsets? get safeAreaInset;

  /// Where Telegram's own floating controls sit in fullscreen.
  external _JSInsets? get contentSafeAreaInset;

  external void onEvent(String type, JSFunction handler);
}

extension type _JSInsets._(JSObject _) implements JSObject {
  external num? get top;
  external num? get bottom;
  external num? get left;
  external num? get right;
}

@JS('Telegram')
external _JSTelegram? get _telegram;

/// The real bridge to `window.Telegram.WebApp`, present only when the page
/// is opened as a Telegram Mini App (the SDK script in `web/index.html`
/// defines it as a no-op-free global everywhere else, so plain browser
/// visits just see `undefined`).
class TelegramWebAppPlatform {
  /// Captured once by [waitForSdk] so every later reader agrees.
  ///
  /// Reading `window.Telegram` live is a trap: the SDK is a remote script, so
  /// two reads a few milliseconds apart can disagree. When they do, startup
  /// concludes "not a Mini App, no silent login" while the router concludes
  /// "this IS a Mini App, so demand registration" — and the learner lands on a
  /// register screen that no amount of registering can dismiss.
  static String? _initData;
  static bool _resolved = false;

  static String? _readInitData() {
    try {
      final data = _telegram?.webApp?.initData;
      return (data != null && data.isNotEmpty) ? data : null;
    } catch (_) {
      return null;
    }
  }

  /// Whether the SDK global exists at all — distinguishes "not running inside
  /// Telegram" from "inside Telegram but it handed us no initData".
  static bool get sdkPresent {
    try {
      return _telegram?.webApp != null;
    } catch (_) {
      return false;
    }
  }

  /// Give the SDK script a moment to arrive, then freeze the answer.
  ///
  /// It is a normal `<script src>` in `<head>`, so it is usually there before
  /// Dart runs — but it is fetched from telegram.org, and on a slow or flaky
  /// connection it is not. Polling briefly costs nothing in the common case and
  /// prevents the split-brain described above in the uncommon one.
  static Future<void> waitForSdk({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    const step = Duration(milliseconds: 50);
    var waited = Duration.zero;
    while (waited < timeout) {
      final data = _readInitData();
      if (data != null) {
        _initData = data;
        _resolved = true;
        return;
      }
      await Future<void>.delayed(step);
      waited += step;
    }
    // Timed out: this is an ordinary browser, or Telegram never delivered
    // initData. Either way the answer is "no Mini App session", for good.
    _initData = null;
    _resolved = true;
  }

  static String? get initData => _resolved ? _initData : _readInitData();

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

  /// Where the app must not draw, updated as Telegram reports changes.
  ///
  /// Zero until fullscreen is actually entered, and zero forever outside
  /// Telegram — so the widget applying it needs no conditions of its own.
  static final ValueNotifier<TelegramInsets> insets =
      ValueNotifier(TelegramInsets.zero);

  /// Take over the whole screen (Bot API 8.0).
  ///
  /// Only on a phone. The desktop and web clients answer
  /// `WebAppMethodUnsupported`, and asking anyway would spend a startup on an
  /// exception for nothing — `expand()` has already claimed the full viewport
  /// height there, which is as fullscreen as those clients get.
  ///
  /// Returns whether the request was made, not whether it succeeded: Telegram
  /// answers asynchronously via `fullscreenChanged`, which is what moves the
  /// insets below.
  static bool requestFullscreen() {
    try {
      final app = _telegram?.webApp;
      if (app == null) return false;
      if (!app.isVersionAtLeast('8.0')) return false;
      final platform = app.platform ?? '';
      if (platform != 'android' && platform != 'ios') return false;
      app.requestFullscreen();
      return true;
    } catch (_) {
      // An older client, or a shape the SDK does not have. Staying expanded is
      // a perfectly good outcome; a startup crash is not.
      return false;
    }
  }

  /// Start following Telegram's inset reports.
  ///
  /// Read once up front and then on every change: entering fullscreen, turning
  /// the phone, and Telegram moving its own controls all fire these, and the
  /// values differ by device — a notch is not a guess we get to make.
  static void watchInsets() {
    try {
      final app = _telegram?.webApp;
      if (app == null) return;
      void publish() => insets.value = _read(app);
      publish();
      for (final event in const [
        'fullscreenChanged',
        'safeAreaChanged',
        'contentSafeAreaChanged',
        'viewportChanged',
      ]) {
        app.onEvent(event, ((JSAny? _) => publish()).toJS);
      }
    } catch (_) {
      // No SDK, or a client too old to report any of this. Zero insets are
      // correct for exactly those cases.
    }
  }

  static TelegramInsets _read(_JSWebApp app) {
    TelegramInsets from(_JSInsets? raw) => raw == null
        ? TelegramInsets.zero
        : TelegramInsets(
            top: (raw.top ?? 0).toDouble(),
            bottom: (raw.bottom ?? 0).toDouble(),
            left: (raw.left ?? 0).toDouble(),
            right: (raw.right ?? 0).toDouble(),
          );
    try {
      return from(app.safeAreaInset) + from(app.contentSafeAreaInset);
    } catch (_) {
      return TelegramInsets.zero;
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

  static bool isVersionAtLeast(String version) {
    try {
      return _telegram?.webApp?.isVersionAtLeast(version) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Telegram's own "choose a chat" sheet ON TOP of the Mini App, which
  /// keeps running underneath. Returns whether the client accepted the call —
  /// a client older than the caller's version gate throws
  /// `WebAppMethodUnsupported` rather than opening anything, and that must be
  /// reported, not swallowed: a share button that silently does nothing is the
  /// exact bug this replaces.
  static bool shareMessage(String preparedMessageId) {
    try {
      final app = _telegram?.webApp;
      if (app == null) return false;
      app.shareMessage(preparedMessageId);
      return true;
    } catch (_) {
      return false;
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
