@Tags(['shot'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/gamification/application/providers.dart';
import 'package:edugain/features/gamification/domain/leaderboard.dart';
import 'package:edugain/features/gamification/presentation/leaderboard_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders the board to PNG so the podium can be looked at.
///
///     flutter test test/leaderboard_shot_test.dart --tags shot --update-goldens

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

void main() {
  setUpAll(() async {
    HttpOverrides.global = _ServeAvatars();
    GoogleFonts.config.allowRuntimeFetching = false;
    // The real icon font. Without it the trophy and the streak flame draw as
    // empty boxes and the screenshot says nothing about either.
    const iconFont =
        'D:/flutter_windows_3.35.4-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(iconFont).existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
            Future.value(File(iconFont).readAsBytesSync().buffer.asByteData()));
      await icons.load();
    }
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(
          Future.value(File(path).readAsBytesSync().buffer.asByteData()),
        );
      await loader.load();
    }
  });

  Map<String, dynamic> row(
    int rank,
    String name,
    int xp, {
    int streak = 0,
    bool you = false,
  }) => {
    'rank': rank,
    'name': name,
    'xp': xp,
    'avatar_url': '/api/v1/auth/avatar/$rank.jpg',
    'streak': streak,
    'is_you': you,
  };

  Widget app(Map<String, dynamic> board) => ProviderScope(
    overrides: [
      leaderboardProvider(false).overrideWith(
        (ref) async => Leaderboard.fromJson(board),
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
      home: const LeaderboardScreen(),
    ),
  );

  Future<void> shoot(WidgetTester tester, Widget w, String name) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(w);
    // Explicit frames: a spinner that shows for one frame never settles.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    // Image decoding is asynchronous and there is one decode per face. Without
    // draining the real event loop the shot is taken while every avatar is
    // still a coloured letter — which is exactly what a broken board looks
    // like, so the screenshot could not tell them apart.
    for (var i = 0; i < 5; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await expectLater(
      find.byType(LeaderboardScreen),
      matchesGoldenFile('shots/$name.png'),
    );
  }

  testWidgets('board with a podium', (tester) async {
    await shoot(
      tester,
      app({
        'top': [
          row(1, 'Aziz', 2450, streak: 42),
          row(2, 'Ali', 2398, streak: 38),
          row(3, 'Dilnoza', 2310, streak: 31),
          row(4, 'Nodira', 2180, streak: 12),
          row(5, 'Bekzod', 2100, streak: 9),
          row(6, 'Malika', 2040, streak: 5),
          row(7, 'Samandar', 1980, streak: 14, you: true),
          row(8, 'Sarvar', 1720, streak: 3),
        ],
        'you': row(7, 'Samandar', 1980, streak: 14, you: true),
      }),
      'lb_podium',
    );
  });

  testWidgets('board with nobody on it yet', (tester) async {
    await shoot(tester, app(const {'top': [], 'you': null}), 'lb_empty');
  });
}
