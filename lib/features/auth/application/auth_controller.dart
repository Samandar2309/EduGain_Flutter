import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/telegram_webapp.dart';
import '../data/auth_repository.dart';
import '../domain/models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.signInReport});
  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final AppUser? user;

  /// Why the last silent sign-in did not produce a session.
  ///
  /// Inside a Mini App a failed sign-in is a dead end for the learner — there
  /// is no sign-in form to fall back to — so the reason has to be visible
  /// rather than swallowed, both for them and for whoever is debugging it.
  final String? signInReport;
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

  /// Running inside a Telegram Mini App: Telegram already vouches for the
  /// learner's identity, so mint a session from its signed `initData` instead
  /// of showing a sign-in flow. Returns whether that worked. `initData` is null
  /// on every other platform, so this is a no-op for the regular mobile app.
  /// Trail of what the last sign-in attempt actually did, surfaced in
  /// [AuthState.signInReport].
  final List<String> _report = [];

  Future<bool> _signInWithTelegram() async {
    final initData = TelegramWebApp.initData;
    if (initData == null) {
      // Note the difference: no SDK at all vs. an SDK that handed us nothing.
      _report.add(
        TelegramWebApp.sdkPresent ? 'initData bo‘sh' : 'Telegram SDK yo‘q',
      );
      return false;
    }
    _report.add('initData ${initData.length} belgi');
    try {
      final result = await _repo.signInWithTelegram(initData);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      _report.add('kirish OK');
      return true;
    } on Object catch (e) {
      _report.add('kirish xato: ${_short(e)}');
      return false;
    }
  }

  static String _short(Object e) {
    final text = e.toString();
    return text.length > 140 ? '${text.substring(0, 140)}…' : text;
  }

  Future<void> _bootstrap() async {
    _report.clear();
    bool stored;
    try {
      stored = await _repo.hasSession();
    } on Object catch (e) {
      // Reading the token store itself failed; treat it as "no session" rather
      // than hanging on the splash forever.
      _report.add('xotira xato: ${_short(e)}');
      stored = false;
    }
    if (stored) {
      try {
        final user = await _repo.me();
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return;
      } on Object catch (e) {
        // The stored session is dead — expired refresh, revoked token, rotated
        // keys. Drop it and re-authenticate below rather than treating a stale
        // token as "this person is a stranger".
        _report.add('saqlangan sessiya yaroqsiz: ${_short(e)}');
        await _repo.clearSession();
      }
    } else {
      _report.add('saqlangan sessiya yo‘q');
    }
    if (await _signInWithTelegram()) return;
    state = AuthState(
      status: AuthStatus.unauthenticated,
      signInReport: _report.join(' · '),
    );
  }

  /// Re-run the whole sign-in attempt. The Mini App's register gate offers this
  /// because that screen is otherwise a dead end: it points at the bot, and the
  /// bot cannot mint a Mini App session, so a learner whose first attempt lost
  /// a race (or a network blip) has no other way forward.
  Future<void> retrySignIn() async {
    state = const AuthState.unknown();
    await _bootstrap();
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
  Future<void> updateProfile({
    String? fullName,
    String? learningLanguage,
    String? gender,
  }) async {
    final user = await _repo.updateProfile(
      fullName: fullName,
      learningLanguage: learningLanguage,
      gender: gender,
    );
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// Called by the API client when a token refresh fails.
  ///
  /// Inside a Mini App this must not simply drop to "unauthenticated": that
  /// state routes to the register-in-the-bot gate, and pressing /start cannot
  /// mint a Mini App session — so an expired token would bounce the learner
  /// between the app and the bot forever. Telegram still vouches for them, so
  /// mint a fresh session instead.
  Future<void> onSessionExpired() async {
    await _repo.clearSession();
    if (await _signInWithTelegram()) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
