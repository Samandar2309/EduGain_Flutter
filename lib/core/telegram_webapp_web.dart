import 'dart:async';
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

  /// Stop Telegram treating a downward drag inside the page as "close me"
  /// (Bot API 7.7).
  external void disableVerticalSwipes();

  /// Whether Telegram is currently giving the app the whole screen.
  external bool? get isFullscreen;

  /// Hand the screen back (Bot API 8.0).
  external void exitFullscreen();

  /// The device's own unsafe strips, when the client is new enough to say
  /// (Bot API 8.0). Older ones report nothing and the CSS probe covers them.
  external _JSInsets? get safeAreaInset;

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

/// The CSS-measured safe area (see the probe in `web/index.html`).
///
/// Works on every Telegram client, unlike the Bot API's own insets which only
/// arrived in 8.0 — and the phones that most need a bottom inset are the ones
/// least likely to be running it.
@JS('edugainSafeArea')
external _JSInsets? _cssSafeArea();

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

  /// Where the app must not draw, updated as the device reports changes.
  static final ValueNotifier<TelegramInsets> insets =
      ValueNotifier(TelegramInsets.zero);

  /// Give the screen back. This app is never fullscreen.
  ///
  /// `requestFullscreen()` was tried once and reverted — but removing the call
  /// was not enough, because Telegram REMEMBERS the mode a Mini App was last
  /// opened in. Opened from a bot message it kept arriving fullscreen: no
  /// Telegram header, its close button floating over the greeting, and the
  /// bottom bar down among the phone's own navigation keys. Opening it from
  /// the menu button was fine, which is what made this look like two different
  /// apps.
  ///
  /// Called unconditionally, and that is the fix. It used to return early
  /// unless `isFullscreen` was already `true` — but at startup the SDK has not
  /// necessarily answered that question yet, so the guard read "not fullscreen"
  /// for a session that was about to become one, and the call it was guarding
  /// never happened. Asking to leave a mode we are not in costs nothing;
  /// staying in it because a flag had not arrived costs the whole layout.
  static void exitFullscreen() {
    try {
      final app = _telegram?.webApp;
      if (app == null || !app.isVersionAtLeast('8.0')) return;
      app.exitFullscreen();
    } catch (_) {
      // Older SDK without the method — it cannot be in fullscreen either.
    }
  }

  /// Keep saying no for the first moments of a session.
  ///
  /// Telegram can grant the remembered mode slightly AFTER the app boots, and
  /// `fullscreenChanged` is not fired by every client when it does. A handful
  /// of repeats over the first second and a half covers that without a poll
  /// that runs for the life of the session: if the app is still windowed after
  /// that, nothing is going to change it.
  static void keepWindowed() {
    exitFullscreen();
    for (final ms in const [150, 400, 900, 1500]) {
      Timer(Duration(milliseconds: ms), exitFullscreen);
    }
  }

  /// Stop a scroll being read as "close the app".
  ///
  /// Telegram dismisses a Mini App on a downward drag, which is the same
  /// gesture as scrolling a list back to the top. On a long screen that makes
  /// the app close itself while somebody is reading it — reported as "the bot
  /// just exits". Bot API 7.7; older clients keep the old behaviour, which is
  /// the best that can be done for them.
  static void disableVerticalSwipes() {
    try {
      final app = _telegram?.webApp;
      if (app == null || !app.isVersionAtLeast('7.7')) return;
      app.disableVerticalSwipes();
    } catch (_) {
      // An older SDK without the method. Nothing to undo.
    }
  }

  /// Start following the safe area.
  ///
  /// Two sources, and the larger of the two wins per edge. CSS `env()` is the
  /// one that works everywhere; Telegram's own insets are more accurate when
  /// the client is new enough to send them. Re-read on the events that can
  /// move them — rotating the phone, the keyboard, Telegram resizing itself.
  static void watchInsets() {
    void publish() => insets.value = _read();
    publish();
    try {
      final app = _telegram?.webApp;
      for (final event in const [
        'viewportChanged',
        'safeAreaChanged',
        'contentSafeAreaChanged',
      ]) {
        app?.onEvent(event, ((JSAny? _) => publish()).toJS);
      }
      // If Telegram puts the app into fullscreen at any point — its own
      // remembered preference, or the learner's swipe — hand it straight back.
      // Startup alone is not enough: the mode can be granted after it.
      app?.onEvent('fullscreenChanged', ((JSAny? _) {
        exitFullscreen();
        publish();
      }).toJS);
    } catch (_) {
      // No SDK. The CSS reading below still works in a plain browser.
    }
  }

  static TelegramInsets _read() {
    TelegramInsets from(_JSInsets? raw) => raw == null
        ? TelegramInsets.zero
        : TelegramInsets(
            top: (raw.top ?? 0).toDouble(),
            bottom: (raw.bottom ?? 0).toDouble(),
            left: (raw.left ?? 0).toDouble(),
            right: (raw.right ?? 0).toDouble(),
          );

    var result = TelegramInsets.zero;
    try {
      result = from(_cssSafeArea());
    } catch (_) {
      // An index.html older than this build, still cached on the device.
    }
    try {
      result = result.largest(from(_telegram?.webApp?.safeAreaInset));
    } catch (_) {
      // Client older than Bot API 8.0 — the CSS reading stands alone.
    }
    return result;
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
