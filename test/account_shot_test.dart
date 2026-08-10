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
import 'package:edugain/features/profile/presentation/account_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The account screen: what we know, and the one field they can correct.
///
///     flutter test test/account_shot_test.dart --tags shot --run-skipped --update-goldens
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

  Future<void> shoot(
      WidgetTester tester, Map<String, dynamic> json, String name) async {
    final auth = _StubAuth(AppUser.fromJson(json));
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith((ref) => auth)],
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
          home: const AccountScreen(),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      auth.pin();
      await tester.pump(const Duration(milliseconds: 80));
    }
    await expectLater(
      find.byType(AccountScreen),
      matchesGoldenFile('shots/$name.png'),
    );
  }

  testWidgets('a full account', (tester) async {
    await shoot(tester, const {
      'id': 'u1',
      'full_name': 'Samandar',
      'phone': '+998947077178',
      'telegram_username': 'jumabayev_samandar',
      'gender': 'male',
    }, 'account_uz');
  });

  testWidgets('nothing answered yet', (tester) async {
    // No @handle and no gender — both ordinary, and the screen has to say so
    // rather than showing two blanks.
    await shoot(tester, const {
      'id': 'u1',
      'full_name': 'Nodira',
      'phone': '+998901234567',
    }, 'account_uz_empty');
  });
}
