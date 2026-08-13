import 'package:flutter/foundation.dart';

import 'telegram_insets.dart';

/// No-op implementation selected on every platform except web (native
/// mobile builds never run inside a Telegram Mini App WebView).
class TelegramWebAppPlatform {
  /// Always zero off the web: a native build has real MediaQuery padding and
  /// needs nothing added to it.
  static final ValueNotifier<TelegramInsets> insets =
      ValueNotifier(TelegramInsets.zero);

  static bool requestFullscreen() => false;
  static void watchInsets() {}
  static String? get initData => null;
  static bool get sdkPresent => false;
  static Future<void> waitForSdk({
    Duration timeout = const Duration(seconds: 3),
  }) async {}
  static void ready() {}
  static void expand() {}
  static void openTelegramLink(String url) {}
  static bool isVersionAtLeast(String version) => false;
  static bool shareMessage(String preparedMessageId) => false;
  static void close() {}
}
