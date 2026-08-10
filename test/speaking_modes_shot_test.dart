@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/api/api_client.dart';
import 'package:edugain/core/api/token_storage.dart';
import 'package:edugain/core/providers.dart';
import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/auth/application/auth_controller.dart';
import 'package:edugain/features/auth/data/auth_repository.dart';
import 'package:edugain/features/auth/domain/models.dart';
import 'package:edugain/features/speaking/application/providers.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/features/speaking/presentation/speaking_modes_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Speaking screen after the live-with-people cards were taken off it.
///
/// Deleting a whole section is exactly the kind of change that leaves a gap, a
/// stranded heading or a lonely card, and none of that is visible to `flutter
/// analyze`.
///
///     flutter test test/speaking_modes_shot_test.dart --tags shot --run-skipped --update-goldens
class _StubAuth extends AuthController {
  _StubAuth(this._user)
      : super(
          AuthRepository(ApiClient(tokens: TokenStorage()), TokenStorage()),
          ApiClient(tokens: TokenStorage()),
        );

  final AppUser _user;

  void pin() =>
      state = AuthState(status: AuthStatus.authenticated, user: _user);
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(
            Future.value(File(path).readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
    const iconFont =
        'D:/flutter_windows_3.35.4-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(iconFont).existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
            Future.value(File(iconFont).readAsBytesSync().buffer.asByteData()));
      await icons.load();
    }
  });

  // A learner who has been placed — otherwise the screen shows the level
  // invitation instead of the modes, and the shot proves nothing.
  final user = AppUser.fromJson(const {
    'id': 'u1',
    'full_name': 'Samandar',
    'cefr_level': 'B2',
  });

  testWidgets('speaking modes, live cards gone', (tester) async {
    final auth = _StubAuth(user);
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => auth),
          // Left to itself this reaches for the real API, which reaches for
          // secure storage, which does not exist in a test — and the whole
          // render dies on a MissingPluginException.
          speakingHistoryProvider.overrideWith(
            (ref) async => <SpeakingSession>[],
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: AppColors.canvas,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand),
          ),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uz'),
          home: const SpeakingModesScreen(),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      auth.pin();
      await tester.pump(const Duration(milliseconds: 80));
    }
    await expectLater(
      find.byType(SpeakingModesScreen),
      matchesGoldenFile('shots/speaking_modes.png'),
    );
  });
}
