import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import 'api/api_client.dart';
import 'locale_controller.dart';
import 'api/token_storage.dart';
import 'google_sign_in_service.dart';
import 'media/microphone_service.dart';

/// Composition root — wires the hexagon's adapters as Riverpod providers.

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInService(),
);

/// The microphone, owned in one place.
///
/// Not auto-disposed: the whole point is that it outlives the screen that
/// opened it. The tap that starts a search acquires the stream, the call
/// screen — created a navigation later — publishes it, and the call's own
/// teardown gives it back. A provider that died with either screen would put
/// `getUserMedia` back where it was.
final microphoneServiceProvider = Provider<MicrophoneService>(
  (ref) => MicrophoneService(),
);

/// The language the server should answer in, as a code it supports.
///
/// `localeProvider` is null until prefs load, and the platform locale may be
/// one we do not ship — fall back to English rather than sending nonsense.
/// Both the `Accept-Language` header and the signaling sockets read this, so
/// a role-play card cannot arrive in a different language than the feedback.
final languageCodeProvider = Provider<String>((ref) {
  final code = ref.watch(localeProvider).locale?.languageCode;
  return AppLanguage.fromCode(code) != null ? code! : 'en';
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(tokens: ref.read(tokenStorageProvider));
  // Read lazily on each request rather than captured once: the learner can
  // switch language mid-session and the very next call must follow.
  client.languageCode = () => ref.read(languageCodeProvider);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.read(apiClientProvider),
    ref.read(tokenStorageProvider),
  ),
);

// The controller wires its `onSessionExpired` into the API client (no cycle).
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
      (ref) => AuthController(
        ref.read(authRepositoryProvider),
        ref.read(apiClientProvider),
      ),
    );
