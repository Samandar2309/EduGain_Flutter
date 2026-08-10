import 'package:edugain/core/api/api_client.dart';
import 'package:edugain/core/api/token_storage.dart';
import 'package:edugain/features/auth/application/auth_controller.dart';
import 'package:edugain/features/auth/data/auth_repository.dart';
import 'package:edugain/features/auth/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// What happens when the tokens on the device are no longer good.
///
/// This is the bug that trapped a real learner inside the Mini App: a stale
/// session made `/auth/me` fail, the controller reported "unauthenticated",
/// and inside Telegram that state routes to "register in the bot" — which
/// cannot mint a Mini App session, so tapping it just sent them back to /start
/// forever. A dead token has to be *dropped and replaced*, never treated as
/// evidence that the person is a stranger.
class _FakeRepo extends AuthRepository {
  _FakeRepo({required this.hasStoredSession, required this.meSucceeds})
      : super(ApiClient(tokens: TokenStorage()), TokenStorage());

  final bool hasStoredSession;
  final bool meSucceeds;

  bool cleared = false;
  int meCalls = 0;

  @override
  Future<bool> hasSession() async => hasStoredSession;

  @override
  Future<void> clearSession() async => cleared = true;

  @override
  Future<AppUser> me() async {
    meCalls++;
    if (!meSucceeds) throw Exception('401');
    return const AppUser(
      id: 'u1',
      role: 'student',
      fullName: 'Samandar',
      phone: '+998900000000',
    );
  }
}

/// Settles the controller's `_bootstrap`, which the constructor kicks off.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a dead stored session is dropped, not kept around', () async {
    final repo = _FakeRepo(hasStoredSession: true, meSucceeds: false);
    final controller = AuthController(repo, ApiClient(tokens: TokenStorage()));
    await _settle();

    expect(repo.meCalls, 1, reason: 'the stored token is still worth one try');
    expect(repo.cleared, isTrue,
        reason: 'a token that failed validation must not survive into the next '
            'attempt — it would poison the retry that unblocks the learner');
    expect(controller.state.status, AuthStatus.unauthenticated,
        reason: 'off-web there is no Telegram identity to fall back to');
  });

  test('a healthy stored session is left alone', () async {
    final repo = _FakeRepo(hasStoredSession: true, meSucceeds: true);
    final controller = AuthController(repo, ApiClient(tokens: TokenStorage()));
    await _settle();

    expect(repo.cleared, isFalse, reason: 'nothing was wrong with it');
    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.user?.fullName, 'Samandar');
  });

  test('no stored session skips /auth/me entirely', () async {
    final repo = _FakeRepo(hasStoredSession: false, meSucceeds: true);
    final controller = AuthController(repo, ApiClient(tokens: TokenStorage()));
    await _settle();

    expect(repo.meCalls, 0);
    expect(controller.state.status, AuthStatus.unauthenticated);
  });

  test('a mid-session refresh failure also drops the dead token', () async {
    // The API client calls this when it cannot refresh. Leaving the stale
    // token in storage was what made the loop survive an app restart.
    final repo = _FakeRepo(hasStoredSession: true, meSucceeds: true);
    final controller = AuthController(repo, ApiClient(tokens: TokenStorage()));
    await _settle();
    repo.cleared = false;

    await controller.onSessionExpired();

    expect(repo.cleared, isTrue);
    expect(controller.state.status, AuthStatus.unauthenticated);
  });
}
