import 'package:edugain/core/media/microphone_service.dart';
import 'package:edugain/core/providers.dart';
import 'package:edugain/features/peer/application/peer_call_controller.dart';
import 'package:edugain/features/peer/data/peer_models.dart';
import 'package:edugain/features/peer/presentation/peer_hub_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

/// The order the "Find a partner" tap does things in.
///
/// The microphone must be dealt with FIRST — before the route push, the socket
/// and the queue. A browser only shows a permission dialog while the tap that
/// justified it is still live, and the request used to sit behind a partner
/// match: minutes of queue, then a WebSocket frame. Chrome tolerated that;
/// WebKit — which is what Telegram's iOS WebView runs — did not, and refused
/// in silence.
///
/// A gender filter sheet sat between the tap and the search until the numbers
/// killed it: over half of all accounts carry no gender, and the matcher hides
/// those learners from anyone who picks one. There is nothing between the tap
/// and the queue now except the microphone.
///
/// Between the tap and the system dialog sits one screen of our own: the
/// primer. It exists because the system dialog is in the phone's language and
/// quotes a hostname nobody recognises, and learners were dismissing it — which
/// is close to permanent, since the browser then stops asking. Its button is
/// what calls `getUserMedia`, so the request still rides a live gesture.
///
/// These assertions are about ORDER and about what must NOT happen.

/// Stands in for a real `MediaStream`; nothing in this flow reads one.
class _FakeStream implements MediaStream {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeMic extends MicrophoneService {
  _FakeMic({required this.allow, required this.permission, required this.log});

  final bool allow;
  final MicPermission permission;
  final List<String> log;

  @override
  Future<MicPermission> checkPermission() async => permission;

  @override
  Future<MediaStream> prepare() async {
    log.add('mic');
    if (!allow) throw const MicException(MicFailure.denied);
    return _FakeStream();
  }

  @override
  Future<void> release() async {}
}

Future<AppLocalizations> _pumpHub(
  WidgetTester tester, {
  required bool allow,
  required List<String> log,
  MicPermission permission = MicPermission.prompt,
}) async {
  final router = GoRouter(
    initialLocation: '/peer',
    routes: [
      GoRoute(path: '/peer', builder: (_, _) => const PeerHubScreen()),
      GoRoute(
        path: '/peer/call',
        builder: (_, _) {
          log.add('navigated');
          return const Scaffold(body: Text('call'));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        microphoneServiceProvider.overrideWithValue(
          _FakeMic(allow: allow, permission: permission, log: log),
        ),
        peerHubProvider.overrideWith(
          (ref) async => const PeerHub(calls: [], online: 3),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.delegate.load(const Locale('en'));
}

/// By icon, not by text: in English the hero heading and the CTA carry the
/// same string, so `find.text` matches two widgets.
Future<void> _tapFind(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.search_rounded));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the tap explains the microphone before anything else happens', (
    tester,
  ) async {
    final log = <String>[];
    final l = await _pumpHub(tester, allow: true, log: log);
    await _tapFind(tester);

    // The primer is up...
    expect(find.text(l.micPrimerTitle), findsOneWidget);
    // ...and nothing else has started. Not the request, not the filter, not
    // the search.
    expect(log, isEmpty, reason: 'nothing may run before the learner agrees');
  });

  testWidgets('agreeing opens the microphone, and only then searches', (
    tester,
  ) async {
    final log = <String>[];
    final l = await _pumpHub(tester, allow: true, log: log);
    await _tapFind(tester);
    await tester.tap(find.text(l.micPrimerContinue));
    await tester.pumpAndSettle();

    // The whole order, in one assertion: microphone, then the search. Nothing
    // in between — the filter sheet that used to sit here is gone.
    expect(log, ['mic', 'navigated']);
  });

  testWidgets('an already-granted microphone shows no primer at all', (
    tester,
  ) async {
    final log = <String>[];
    final l = await _pumpHub(
      tester,
      allow: true,
      log: log,
      permission: MicPermission.granted,
    );
    await _tapFind(tester);

    // Nothing to explain: no dialog will appear, so none is announced.
    expect(find.text(l.micPrimerTitle), findsNothing);
    expect(log, ['mic', 'navigated']);
  });

  testWidgets('a refused microphone opens no sheet and starts no search', (
    tester,
  ) async {
    final log = <String>[];
    final l = await _pumpHub(tester, allow: false, log: log);
    await _tapFind(tester);
    await tester.tap(find.text(l.micPrimerContinue));
    await tester.pumpAndSettle();

    // The learner is told why...
    expect(find.text(l.micNeededTitle), findsOneWidget);
    // ...and the search never started.
    expect(log, ['mic'], reason: 'a refusal must not reach navigation');
  });

  testWidgets('a blocked microphone never even asks', (tester) async {
    final log = <String>[];
    final l = await _pumpHub(
      tester,
      allow: false,
      log: log,
      permission: MicPermission.denied,
    );
    await _tapFind(tester);

    // Asking would show no dialog and fail, so it goes straight to how to
    // undo it — no primer, no request, no search.
    expect(find.text(l.micNeededTitle), findsOneWidget);
    expect(find.text(l.micPrimerTitle), findsNothing);
    expect(log, isEmpty);
  });
}
