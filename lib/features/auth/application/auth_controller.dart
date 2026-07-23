import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/telegram_webapp.dart';
import '../data/auth_repository.dart';
import '../domain/models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user});
  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final AppUser? user;
}

/// Owns the session lifecycle. On start it checks for a stored token and
/// validates it via `/auth/me`; the router reacts to the resulting status.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, ApiClient api)
    : super(const AuthState.unknown()) {
    // Break the session here when a refresh fails (set after construction to
    // avoid a provider dependency cycle).
    api.onAuthFailure = onSessionExpired;
    _bootstrap();
  }

  final AuthRepository _repo;

  Future<void> _bootstrap() async {
    if (!await _repo.hasSession()) {
      // Running inside a Telegram Mini App: Telegram already vouches for the
      // learner's identity, so log in silently instead of showing the
      // phone/Google welcome flow. `initData` is null on every other
      // platform, so this is a no-op for the regular mobile app.
      final initData = TelegramWebApp.initData;
      if (initData != null) {
        try {
          final result = await _repo.signInWithTelegram(initData);
          state = AuthState(status: AuthStatus.authenticated, user: result.user);
          return;
        } on Object {
          // Fall through to the normal unauthenticated flow (e.g. the
          // signature failed to verify, or the request itself failed).
        }
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Object {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void onAuthenticated(AppUser user) =>
      state = AuthState(status: AuthStatus.authenticated, user: user);

  /// Re-fetch the profile (e.g. after placement updates the CEFR level).
  Future<void> refreshUser() async {
    if (state.status != AuthStatus.authenticated) return;
    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Object {
      // Keep the current user on a transient failure.
    }
  }

  /// Update editable profile fields and reflect the result locally.
  Future<void> updateProfile({String? fullName}) async {
    final user = await _repo.updateProfile(fullName: fullName);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// Called by the API client when a token refresh fails.
  void onSessionExpired() =>
      state = const AuthState(status: AuthStatus.unauthenticated);

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
