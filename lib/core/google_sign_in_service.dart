import 'package:google_sign_in/google_sign_in.dart';

import 'api/api_exception.dart';
import 'config.dart';

/// Thin wrapper over google_sign_in v7. Returns a Google **ID token** which the
/// backend verifies server-side (`POST /auth/google`, REQ-03-008).
class GoogleSignInService {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleServerClientId.isEmpty
          ? null
          : AppConfig.googleServerClientId,
    );
    _initialized = true;
  }

  /// Trigger the native Google sign-in. Returns the ID token, or null if the
  /// user cancelled.
  Future<String?> signIn() async {
    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw const ApiException(
        code: 'GOOGLE_UNSUPPORTED',
        message: 'Bu qurilmada Google orqali kirish qo\'llab-quvvatlanmaydi',
      );
    }
    await _ensureInitialized();
    try {
      final account = await signIn.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw ApiException(code: 'GOOGLE_ERROR', message: e.description ?? 'Google xatosi');
    }
  }
}
