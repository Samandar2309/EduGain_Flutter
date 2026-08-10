@Tags(['shot'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:edugain/core/api/token_storage.dart';
import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/group/application/group_call_controller.dart';
import 'package:edugain/features/group/data/group_models.dart';
import 'package:edugain/features/group/presentation/group_call_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders the live group room to a PNG so it can actually be looked at.
///
/// "Analyze is clean and the tests pass" says nothing about whether a screen is
/// laid out the way it was designed. Regenerate with:
///
///     flutter test test/group_room_shot_test.dart --tags shot --run-skipped --update-goldens
///
/// They land in test/shots/.
class _FakeCall extends GroupCallController {
  _FakeCall(this._fixture)
      : super(TokenStorage(), 'Samandar', 'ABC123', 'uz',
            '/api/v1/auth/avatar/mehash', autoStart: false);

  final GroupCallState _fixture;

  /// `autoStart: false` means no socket is opened and no microphone is asked
  /// for; the state is supplied here instead. Re-asserted between pumps because
  /// the screen's own listeners can move it.
  void pin() => state = _fixture;
}


/// A 64x64 solid PNG, one colour per participant.
const _pngs = <String>[
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAe0lEQVR4nO3PUQkAIBTAQNNa6VU0hiH8OITBAtzWmf11iwsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oIHxiJeBCyyTUcPLeesYAAAAAElFTkSuQmCC',
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAe0lEQVR4nO3PwQkAIBDAMEd1uVvSl0P4CEKhA6Rrz/m6xQUNaEEDWtCAFjSgBQ1oQQNa0IAWNKAFDWhBA1rQgBY0oAUNaEEDWtCAFjSgBQ1oQQNa0IAWNKAFDWhBA1rQgBY0oAUNaEEDWtCAFjSgBQ1oQQNa0MB4xMvABbev8dI5evK6AAAAAElFTkSuQmCC',
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAe0lEQVR4nO3PUQkAIBTAQENZ1lyvkCH8OITBAtzWnvN1iwsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oIHxiJeBC6LCAYe/aqFsAAAAAElFTkSuQmCC',
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAe0lEQVR4nO3PUQkAIBTAQDO/cCYzgCH8OITBAtzWmf11iwsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oAEtaEALGtCCBrSgAS1oQAsa0IIGtKABLWhACxrQgga0oIHxiJeBC8iFwfD7pQXxAAAAAElFTkSuQmCC',
];

/// Serves those bytes for any avatar URL the room asks for.
///
/// Without this the test HttpClient answers 400 and every face falls back to
/// its coloured initial — so the screenshot would look identical whether the
/// avatars worked or not, which is the one thing it is here to show.
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

GroupMember _m(String id, String name, {bool speaking = false, bool connected = true}) {
  final m = GroupMember(
      id: id, name: name, avatar: '/api/v1/auth/avatar/${id}hash');
  m.speaking = speaking;
  m.connected = connected;
  return m;
}


ChatMessage _msg(String id, String from, String name, String text,
    {bool mine = false, int hearts = 0, bool iLiked = false}) {
  final m = ChatMessage(
    id: id,
    from: from,
    name: name,
    text: text,
    at: DateTime(2026, 8, 5, 10, 32),
    mine: mine,
  );
  if (hearts > 0) m.reactions['❤'] = hearts;
  // Outlined chip + filled heart: proves the 'already joined' state draws.
  if (iLiked) m.mine_.add('❤');
  return m;
}

final _chat = [
  _msg('1', 'u1', 'Aziza',
      "For me, it's discovering the local food and trying new dishes.",
      hearts: 12),
  _msg('2', 'u2', 'John',
      'I agree! I also love meeting new people and hearing their stories.',
      hearts: 8, iLiked: true),
  _msg('3', 'u3', 'Maria',
      'The nature and landscapes are my favorite.', hearts: 10),
  _msg('4', 'me', 'Siz',
      'I think the most exciting part is the adventure and the unknown!',
      mine: true),
];

final _started = DateTime.now().subtract(const Duration(minutes: 6, seconds: 13));

void main() {
  setUpAll(() async {
    HttpOverrides.global = _ServeAvatars();
    GoogleFonts.config.allowRuntimeFetching = false;
    // Load the REAL icon font, not just a text face.
    //
    // Without it every icon renders as a blank box and the screenshot proves
    // nothing about icons — which is exactly how three wrong diagnoses of
    // "the icons are invisible on the device" got past this test and onto the
    // server. With it, an icon that will not draw does not draw here either.
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
            Future.value(File(path).readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
  });

  Widget app(_FakeCall call) => ProviderScope(
        overrides: [
          groupCallControllerProvider('ABC123').overrideWith((ref) => call),
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
          home: const GroupCallScreen(code: 'ABC123'),
        ),
      );

  Future<void> shoot(WidgetTester tester, _FakeCall call, String name) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(call));
    // Explicit frames rather than pumpAndSettle: the waveform never stops
    // animating, so settling never happens and the shot is never taken.
    for (var i = 0; i < 6; i++) {
      call.pin();
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Image decoding is asynchronous and there is one decode per face, so a
    // single short drain leaves most of the room still showing initials — the
    // shot then understates what a phone actually draws.
    for (var i = 0; i < 5; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      call.pin();
      await tester.pump(const Duration(milliseconds: 60));
    }
    // Back to the top before capturing: the screen scrolls itself to the newest
    // message on arrival, which is right in a call and useless in a screenshot.
    await tester.drag(find.byType(ListView).first, const Offset(0, 4000));
    await tester.pump();
    await expectLater(
      find.byType(GroupCallScreen),
      matchesGoldenFile('shots/$name.png'),
    );
    // …and again further down, where the chat lives.
    await tester.drag(find.byType(ListView).first, const Offset(0, -560));
    await tester.pump();
    await expectLater(
      find.byType(GroupCallScreen),
      matchesGoldenFile('shots/${name}_chat.png'),
    );
    // …and the foot of the page, where the rules and the settings dots live.
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump();
    await expectLater(
      find.byType(GroupCallScreen),
      matchesGoldenFile('shots/${name}_foot.png'),
    );
  }

  const topic = GroupTopic(
    id: 'travel',
    title: 'Travel',
    prompt: 'What is the most exciting part of traveling to a new country?',
  );

  testWidgets('room as an ordinary member, two people speaking', (tester) async {
    final call = _FakeCall(GroupCallState(
      phase: GroupPhase.live,
      selfId: 'me',
      hostId: 'u1',
      topic: topic,
      title: 'Airport Lounge',
      maxParticipants: 50,
      muted: true,
      messages: _chat,
      startedAt: _started,
      members: [
        _m('u1', 'Aziza', speaking: true),
        _m('u2', 'John', speaking: true),
        _m('u3', 'Maria'),
        _m('u4', 'David'),
        _m('u5', 'Sophie'),
        _m('u6', 'James', connected: false),
        _m('u7', 'Lina'),
        _m('u8', 'Nodira'),
        _m('u9', 'Bekzod'),
      ],
    ));
    await shoot(tester, call, 'group_room_member');
  });

  testWidgets('room as the host, microphone open', (tester) async {
    final call = _FakeCall(GroupCallState(
      phase: GroupPhase.live,
      selfId: 'me',
      hostId: 'me',
      topic: topic,
      title: 'Airport Lounge',
      maxParticipants: 50,
      selfSpeaking: true,
      messages: _chat,
      startedAt: _started,
      members: [
        _m('u1', 'Aziza', speaking: true),
        _m('u2', 'John'),
        _m('u3', 'Maria'),
        _m('u4', 'David'),
        _m('u5', 'Sophie'),
      ],
    ));
    await shoot(tester, call, 'group_room_host');
  });

  testWidgets('quiet room says so rather than showing a gap', (tester) async {
    final call = _FakeCall(GroupCallState(
      phase: GroupPhase.live,
      selfId: 'me',
      hostId: 'u1',
      topic: topic,
      title: 'Airport Lounge',
      maxParticipants: 50,
      muted: true,
      messages: _chat,
      startedAt: _started,
      members: [_m('u1', 'Aziza'), _m('u2', 'John')],
    ));
    await shoot(tester, call, 'group_room_quiet');
  });
}
