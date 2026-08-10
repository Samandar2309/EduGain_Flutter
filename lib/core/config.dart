import 'package:flutter/foundation.dart' show kIsWeb;

/// App-wide configuration.
class AppConfig {
  const AppConfig._();

  /// Set at build time with `--dart-define=API_BASE_URL=...`; empty means
  /// "use the default for this platform".
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Where the backend lives.
  ///
  /// The web default is deliberately relative: a web build is always served by
  /// the same nginx that fronts the API, so `/api/v1` is correct on any origin
  /// — localhost, the sslip.io host, a tunnel. It used to fall back to the
  /// Android emulator's loopback on every platform, which meant one forgotten
  /// `--dart-define` shipped a Mini App whose every request went to
  /// `10.0.2.2` and failed with a network error, with nothing in the server
  /// logs to show for it. A default that cannot be reached from the platform
  /// it is defaulting for is a trap, so web no longer has one.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    return kIsWeb ? '/api/v1' : 'http://10.0.2.2:8080/api/v1';
  }

  /// Google OAuth **web/server** client ID (must match the backend's
  /// GOOGLE_CLIENT_ID so the issued id_token's audience verifies server-side).
  /// Inject via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// E.164 phone, Uzbekistan-friendly (+998 then 9 digits) — mirrors the backend.
  static final RegExp phonePattern = RegExp(r'^\+998\d{9}$');
}
