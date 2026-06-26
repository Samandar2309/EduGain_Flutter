import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import 'api/api_client.dart';
import 'api/token_storage.dart';
import 'google_sign_in_service.dart';

/// Composition root — wires the hexagon's adapters as Riverpod providers.

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInService(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokens: ref.read(tokenStorageProvider)),
);

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
