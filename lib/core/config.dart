/// App-wide configuration. The API base URL is injected at build time via
/// `--dart-define=API_BASE_URL=...`. The default targets the Android emulator's
/// host loopback (10.0.2.2) hitting the Nginx gateway on :8080.
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  /// Google OAuth **web/server** client ID (must match the backend's
  /// GOOGLE_CLIENT_ID so the issued id_token's audience verifies server-side).
  /// Inject via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// E.164 phone, Uzbekistan-friendly (+998 then 9 digits) — mirrors the backend.
  static final RegExp phonePattern = RegExp(r'^\+998\d{9}$');
}
