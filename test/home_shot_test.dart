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
import 'package:edugain/features/gamification/application/providers.dart';
import 'package:edugain/features/gamification/domain/leaderboard.dart';
import 'package:edugain/features/gamification/domain/models.dart';
import 'package:edugain/features/home/presentation/home_screen.dart';
import 'package:edugain/features/home/presentation/main_shell.dart';
import 'package:edugain/features/speaking/application/providers.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/features/subscriptions/application/providers.dart';
import 'package:edugain/features/subscriptions/domain/models.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders the home screen to a PNG so it can actually be looked at.
///
/// "Analyze is clean and the tests pass" says nothing about whether a screen
/// is laid out the way it was designed — spacing, truncation and overflow are
/// all invisible to both. Regenerate the images with:
///
///     flutter test test/home_shot_test.dart --tags shot --update-goldens
///
/// They land in test/shots/.
class _StubAuth extends AuthController {
  _StubAuth(this._user)
    : super(
        AuthRepository(ApiClient(tokens: TokenStorage()), TokenStorage()),
        ApiClient(tokens: TokenStorage()),
      );

  final AppUser _user;

  /// Re-asserted from the test between pumps.
  ///
  /// Setting it in the constructor is not enough: the real controller kicks
  /// off `_bootstrap()`, which finds no session in a test and lands the state
  /// back on unauthenticated — leaving the screen on its loading spinner.
  void pin() =>
      state = AuthState(status: AuthStatus.authenticated, user: _user);
}

void main() {
  setUpAll(() async {
    // Otherwise the theme tries to pull Inter over the network mid-test and
    // the render dies before drawing anything.
    GoogleFonts.config.allowRuntimeFetching = false;
    // With no font registered, every glyph draws as a filled box and the
    // screenshot shows layout but not the thing being judged. A real face
    // stands in under the family name the theme asks for.
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(Future.value(File(path).readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
    // The icon font, for the same reason and it was missing: every icon on
    // this screen drew as a filled square, so a shot taken to judge the home
    // page showed boxes where the flame, the target and the microphone are.
    const iconFont =
        'D:/flutter_windows_3.35.4-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(iconFont).existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(File(iconFont).readAsBytesSync().buffer.asByteData()),
        );
      await icons.load();
    }
  });

  Widget app(List<Override> overrides) => ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      // Not AppTheme.light(): it pulls Inter through google_fonts, which
      // refuses to work offline and takes the render down with it. The screen
      // sets its own colours and sizes anyway — what the theme supplies here
      // is the face, and a stand-in is enough to judge the layout.
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
      home: const Scaffold(body: HomeTab()),
    ),
  );

  List<Override> base(_StubAuth auth, {String tier = 'main'}) => [
    authControllerProvider.overrideWith((ref) => auth),
    // Without this the card asks the real endpoint, which reaches for secure
    // storage and dies — the screenshot would then be of a broken screen.
    speakingQuotaProvider.overrideWith(
      // The seconds live under a `speaking` key; flat ones parse as zero and
      // the card would quietly render "0 minutes left" in the screenshot.
      (ref) async => SpeakingQuota.fromJson(const {
        'sessions_remaining': 2,
        'speaking': {'seconds_limit': 480, 'seconds_used': 120},
      }),
    ),
    mySubscriptionProvider.overrideWith(
      (ref) async => Subscription.fromJson({'tier': tier}),
    ),
    gamificationProfileProvider.overrideWith(
      (ref) async => GamificationProfile.fromJson(const {
        'xp': 1250,
        'level': 4,
        'streak': 14,
        'daily_goal': {'target': 50, 'progress': 40},
      }),
    ),
  ];

  Override boardWith(Map<String, dynamic> json) =>
      leaderboardProvider(false).overrideWith(
        (ref) async => Leaderboard.fromJson(json),
      );

  Future<void> shoot(WidgetTester tester, Widget w, String name,
      void Function() pinAuth, {Finder? target}) async {
    // The screen under test is not always HomeTab — the lessons tab uses the
    // same harness.
    final subject = target ?? find.byType(HomeTab);
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(w);
    // Asset decoding is real async work; without this the hero art never
    // appears and the card looks empty for reasons that have nothing to do
    // with the design.
    await tester.runAsync(() async {
      final ctx = tester.element(subject);
      // Must match the card's own provider exactly. It passes `cacheWidth`,
      // which wraps the asset in a ResizeImage — a different cache key — so
      // precaching the bare AssetImage warms an entry nothing ever reads and
      // the art stays invisible for a reason that is not the design's.
      await precacheImage(
        ResizeImage(
          const AssetImage('assets/hero/hero_base.png'),
          width: 260,
        ),
        ctx,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    // Explicit frames rather than pumpAndSettle: a spinner shown for one frame
    // while a provider resolves never stops animating, so settling never
    // happens and the screenshot is never taken.
    for (var i = 0; i < 8; i++) {
      pinAuth();
      await tester.pump(const Duration(milliseconds: 120));
    }
    await expectLater(
      subject,
      matchesGoldenFile('shots/$name.png'),
    );
  }

  testWidgets('home with a level and a board', (tester) async {
    final user = AppUser.fromJson(const {
      'id': 'u1',
      'full_name': 'Samandar',
      'cefr_level': 'B2',
      'streak_count': 14,
    });
    final auth = _StubAuth(user);
    await shoot(
      tester,
      app([
        ...base(auth),
        boardWith(const {
          'top': [
            {'rank': 1, 'name': 'Aziz', 'xp': 2450, 'avatar_url': '', 'is_you': false},
            {'rank': 2, 'name': 'Ali', 'xp': 2390, 'avatar_url': '', 'is_you': false},
            {'rank': 3, 'name': 'Dilnoza', 'xp': 1980, 'avatar_url': '', 'is_you': false},
          ],
          'you': {'rank': 17, 'name': 'Samandar', 'xp': 240, 'avatar_url': '', 'is_you': true},
        }),
      ]),
      'home_placed',
      auth.pin,
    );
  });

  testWidgets('lessons tab', (tester) async {
    // Added after a `CrossAxisAlignment.stretch` inside a ListView collapsed
    // the second row of cards off the screen. Analyze was clean, every test
    // passed, and half the tab was missing — only a picture showed it.
    final user = AppUser.fromJson(const {
      'id': 'u3',
      'full_name': 'Samandar',
      'cefr_level': 'B2',
    });
    final auth = _StubAuth(user);
    await shoot(
      tester,
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => auth),
          // The Speaking tile reads the AI lock, which reads the quota, which
          // reaches for secure storage and dies in a widget test. This shot has
          // been failing since the lock shipped — `flutter test` skips shots
          // unless they are asked for by tag, so nothing said so.
          speakingQuotaProvider.overrideWith(
            (ref) async => SpeakingQuota.fromJson(const {
              'sessions_remaining': 2,
              'speaking': {'seconds_limit': 600, 'seconds_used': 0},
              'ai_unlocked': false,
            }),
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
          home: const Scaffold(body: LessonsTab()),
        ),
      ),
      'lessons',
      auth.pin,
      target: find.byType(LessonsTab),
    );
  });

  testWidgets('home before the level test', (tester) async {
    final user = AppUser.fromJson(const {'id': 'u2', 'full_name': 'Samandar'});
    final auth = _StubAuth(user);
    await shoot(
      tester,
      app([
        ...base(auth, tier: 'free'),
        boardWith(const {'top': [], 'you': null}),
      ]),
      'home_zero',
      auth.pin,
    );
  });
}
