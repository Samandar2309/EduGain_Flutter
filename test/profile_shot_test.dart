@Tags(['shot'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edugain/core/api/api_client.dart';
import 'package:edugain/core/api/token_storage.dart';
import 'package:edugain/core/providers.dart';
import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/auth/application/auth_controller.dart';
import 'package:edugain/features/auth/data/auth_repository.dart';
import 'package:edugain/features/auth/domain/models.dart';
import 'package:edugain/features/gamification/application/providers.dart';
import 'package:edugain/features/gamification/domain/models.dart';
import 'package:edugain/features/profile/presentation/profile_screen.dart';
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

/// The whole profile screen, not just the card on it.
///
/// The card was rebuilt against a screenshot of itself and came out fine; the
/// screen around it still said "Daraja" twice, meaning two different things,
/// and printed a phone number where a person's identity goes. Neither is
/// visible from inside the card.
///
///     flutter test test/profile_shot_test.dart --tags shot --run-skipped --update-goldens
/// A 64x64 solid PNG per learner, so the shot proves photos actually draw.
const _pngs = <String>[
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAe0lEQVR4nO3PUQkAIBTAQNNa6VU0hiH8OITBAtzWmf11iwsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oIHxiJeBCyyTUcPLeesYAAAAAElFTkSuQmCC',
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAe0lEQVR4nO3PwQkAIBDAMEd1uVvSl0P4CEKhA6Rrz/m6xQUNaEEDWtCAFjSgBQ1oQQNa0IAWNKAFDWhBA1rQgBY0oAUNaEEDWtCAFjSgBQ1oQQNa0IAWNKAFDWhBA1rQgBY0oAUNaEEDWtCAFjSgBQ1oQQNa0MB4xMvABbev8dI5evK6AAAAAElFTkSuQmCC',
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAe0lEQVR4nO3PUQkAIBTAQENZ1lyvkCH8OITBAtzWnvN1iwsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oIHxiJeBC6LCAYe/aqFsAAAAAElFTkSuQmCC',
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAe0lEQVR4nO3PUQkAIBTAQDO/cCYzgCH8OITBAtzWmf11iwsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oIHxiJeBC8iFwfD7pQXxAAAAAElFTkSuQmCC',
];

class _ServeAvatars extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? _) => _Client();
}

class _Client extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    var h = 0;
    for (final c in url.path.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return _Request(base64Decode(_pngs[h % _pngs.length]));
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => getUrl(url);
}

class _Request extends Fake implements HttpClientRequest {
  _Request(this.bytes);
  final List<int> bytes;

  @override
  HttpHeaders get headers => _Headers();

  @override
  Future<HttpClientResponse> close() async => _Response(bytes);
}

class _Headers extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _Response extends Fake implements HttpClientResponse {
  _Response(this.bytes);
  final List<int> bytes;

  @override
  int get statusCode => 200;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

class _StubAuth extends AuthController {
  _StubAuth(this._user)
      : super(
          AuthRepository(ApiClient(tokens: TokenStorage()), TokenStorage()),
          ApiClient(tokens: TokenStorage()),
        );

  final AppUser _user;

  /// Re-asserted between pumps: the real controller bootstraps, finds no
  /// session, and would drop the screen back to its loader.
  void pin() =>
      state = AuthState(status: AuthStatus.authenticated, user: _user);
}

AbilityTrend _t(double current, double? delta, int samples) =>
    AbilityTrend(current: current, delta: delta, samples: samples);

void main() {
  setUpAll(() async {
    HttpOverrides.global = _ServeAvatars();
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

  final user = AppUser.fromJson(const {
    'id': 'u1',
    'full_name': 'Samandar',
    'phone': '+998947077178',
    'cefr_level': 'B2',
    'avatar_url': '/api/v1/auth/avatar/me.jpg',
  });

  final profile = LearnerProfile(
    focusTags: const ['word_choice', 'other', 'verb_tense', 'word_order'],
    voicedMinutes: 8.6,
    spokenWords: 534,
    wordsPerMinute: 62,
    wpmTarget: 140,
    hasMemory: true,
    abilities: {
      'grammar': _t(55, -1, 10),
      'vocabulary': _t(50, -6, 10),
      'overall': _t(46, -2, 10),
    },
  );

  Widget app(_StubAuth auth, String lang, {String tier = 'pro'}) => ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => auth),
          mySubscriptionProvider.overrideWith(
            (ref) async => Subscription.fromJson({'tier': tier}),
          ),
          gamificationProfileProvider.overrideWith(
            (ref) async => GamificationProfile.fromJson(const {
              'xp': 350,
              'level': 2,
              'streak': 1,
              'daily_goal': {'target': 50, 'progress': 30},
            }),
          ),
          learnerProfileProvider.overrideWith((ref) async => profile),
          // Five, as the server now sends. More than that turned the foot of
          // the profile into a ledger nobody reads.
          xpHistoryProvider.overrideWith(
            (ref) async => [
              for (final e in const [
                ('course', 10, '2026-08-07T09:10:00Z'),
                ('speaking', 25, '2026-08-07T08:40:00Z'),
                ('streak', 5, '2026-08-06T19:02:00Z'),
                ('grammar', 10, '2026-08-06T18:55:00Z'),
                ('vocab', 10, '2026-08-06T18:30:00Z'),
              ])
                XpEvent(source: e.$1, amount: e.$2, createdAt: e.$3),
            ],
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
          locale: Locale(lang),
          home: const ProfileScreen(),
        ),
      );

  Future<void> shoot(
    WidgetTester tester,
    String lang,
    String name, {
    String tier = 'pro',
    bool footToo = true,
  }) async {
    final auth = _StubAuth(user);
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(auth, lang, tier: tier));
    for (var i = 0; i < 6; i++) {
      auth.pin();
      await tester.pump(const Duration(milliseconds: 80));
    }
    // Image decoding is asynchronous: without draining the real event loop the
    // shot is taken while the photo is still a blank circle.
    for (var i = 0; i < 4; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      auth.pin();
      await tester.pump(const Duration(milliseconds: 60));
    }
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('shots/$name.png'),
    );
    if (!footToo) return;
    // ...and the rest of it, where the settings and the XP list live.
    //
    // A single pump after a drag catches the fling mid-flight and photographs
    // empty space below the content. These let it land.
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    for (var i = 0; i < 8; i++) {
      auth.pin();
      await tester.pump(const Duration(milliseconds: 60));
    }
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('shots/${name}_foot.png'),
    );
  }

  testWidgets('profile top and foot', (tester) async {
    await shoot(tester, 'uz', 'profile_uz');
  });

  // The badge used to be the same translucent pill for everybody, so a free
  // account looked exactly like a paid one. These are the comparison.
  testWidgets('a paid tier reads as paid', (tester) async {
    await shoot(tester, 'uz', 'profile_tier_main', tier: 'main', footToo: false);
  });

  testWidgets('free stays quiet', (tester) async {
    await shoot(tester, 'uz', 'profile_tier_free', tier: 'free', footToo: false);
  });
}
