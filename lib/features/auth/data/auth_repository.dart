import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/token_storage.dart';
import '../domain/models.dart';

/// Auth use-cases over the backend §4.1 endpoints.
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  /// Request an OTP; returns the cooldown (`retry_after`) seconds.
  Future<int> requestOtp(String phone) async {
    final data = await _api.post('/auth/otp/request', body: {'phone': phone});
    return (data['retry_after'] as num?)?.toInt() ?? 0;
  }

  /// Verify the OTP, persist the tokens, and return the session.
  Future<AuthResult> verifyOtp(String phone, String code) async {
    final data = await _api.post(
      '/auth/otp/verify',
      body: {'phone': phone, 'code': code},
    );
    final result = AuthResult.fromJson(data);
    await _tokens.save(
      access: result.tokens.accessToken,
      refresh: result.tokens.refreshToken,
    );
    return result;
  }

  /// Exchange a Google ID token for a session (backend verifies it).
  Future<AuthResult> signInWithGoogle(String idToken) async {
    final data = await _api.post('/auth/google', body: {'id_token': idToken});
    final result = AuthResult.fromJson(data);
    await _tokens.save(
      access: result.tokens.accessToken,
      refresh: result.tokens.refreshToken,
    );
    return result;
  }

  /// Silent login for the Telegram Mini App: exchange Telegram's signed
  /// `initData` for a session (the backend verifies the HMAC before trusting
  /// it — never validated client-side).
  Future<AuthResult> signInWithTelegram(String initData) async {
    final data = await _api.post(
      '/auth/telegram/webapp',
      body: {'init_data': initData},
    );
    final result = AuthResult.fromJson(data);
    await _tokens.save(
      access: result.tokens.accessToken,
      refresh: result.tokens.refreshToken,
    );
    return result;
  }

  Future<AppUser> me() async {
    final data = await _api.get('/auth/me');
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// PATCH /users/me — only the fields provided are sent.
  Future<AppUser> updateProfile({
    String? fullName,
    String? timezone,
    String? nativeLang,
    String? email,
    String? learningLanguage,
    String? gender,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (timezone != null) body['timezone'] = timezone;
    if (nativeLang != null) body['native_lang'] = nativeLang;
    if (email != null) body['email'] = email;
    if (learningLanguage != null) body['learning_language'] = learningLanguage;
    if (gender != null) body['gender'] = gender;
    final data = await _api.patch('/users/me', body: body);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on Object {
      // Best-effort server revoke; we clear locally regardless.
    }
    await _tokens.clear();
  }

  Future<bool> hasSession() async => (await _tokens.readAccess()) != null;

  /// Drop the stored tokens without telling the server — for a session that is
  /// already dead, where `logout()`'s revoke call would just fail anyway.
  Future<void> clearSession() => _tokens.clear();

  /// Replace the profile picture.
  ///
  /// Returns the new URL so the caller can show it immediately rather than
  /// waiting for the next `/auth/me`.
  Future<String> uploadAvatar(Uint8List bytes, String filename) async {
    final data = await _api.putMultipart(
      '/auth/avatar/me',
      bytes: bytes,
      filename: filename,
    );
    return data['avatar_url'] as String? ?? '';
  }

  /// Go back to the Telegram picture.
  Future<String> resetAvatar() async {
    final data = await _api.delete('/auth/avatar/me');
    return data['avatar_url'] as String? ?? '';
  }
}
