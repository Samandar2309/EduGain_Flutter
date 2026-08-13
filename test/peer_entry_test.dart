import 'package:edugain/core/media/microphone_service.dart';
import 'package:edugain/core/providers.dart';
import 'package:edugain/features/peer/presentation/peer_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:edugain/l10n/app_localizations.dart';

/// Where the bot's "join the conversation" button lands.
///
/// The hub it used to open is not shown any more. Its whole reason for
/// existing was the microphone: a page loaded from a link has no user gesture
/// behind it, so the hub's button supplied one. That tap is now spent in
/// Telegram, and this screen decides on arrival.
///
/// Two outcomes, and the second is the one worth pinning. A learner who does
/// not grant the microphone must NOT reach a live room: two of them once met
/// where neither had been asked, both heard silence, and both concluded the
/// app was broken. Home is a worse outcome than a working call and a far
/// better one than that.

class _FakeMic implements MicrophoneService {
  _FakeMic({required this.grant});

  final bool grant;
  int checks = 0;

  /// A granted microphone is modelled as one already open, which is a real
  /// state (the gate's own first line) and keeps `MediaStream` — impossible to
  /// build in a test — out of this file entirely.
  @override
  bool get hasLiveStream => grant;

  @override
  Future<MicPermission> checkPermission() async {
    checks += 1;
    return grant ? MicPermission.granted : MicPermission.denied;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoRouter _router() => GoRouter(
  initialLocation: '/peer',
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, _) => const Scaffold(body: Text('HOME')),
    ),
    GoRoute(path: '/peer', builder: (_, _) => const PeerEntryScreen()),
    GoRoute(
      path: '/peer/call',
      builder: (_, state) =>
          Scaffold(body: Text('SEARCHING ${state.extra.runtimeType}')),
    ),
  ],
);

Future<void> _open(WidgetTester tester, _FakeMic mic) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [microphoneServiceProvider.overrideWithValue(mic)],
      child: MaterialApp.router(
        routerConfig: _router(),
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
  // Fixed pumps, not `pumpAndSettle`: the screen shows a spinner while it
  // decides, and a spinner never settles.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('the hub is not what the link opens any more', (tester) async {
    final mic = _FakeMic(grant: true);
    await _open(tester, mic);
    // Nothing from the hub: no history, no room code, no second tap.
    expect(find.text('Suhbatlar tarixi'), findsNothing);
  });

  testWidgets('a granted microphone goes straight into the search', (
    tester,
  ) async {
    final mic = _FakeMic(grant: true);
    await _open(tester, mic);

    expect(find.textContaining('SEARCHING'), findsOneWidget);
    expect(
      find.text('SEARCHING PeerLaunchMatch'),
      findsOneWidget,
      reason: 'the call route is only entered with a launch object, which is '
          'what proves a microphone was opened for it',
    );
  });

  testWidgets('a refused microphone lands home, never in a room', (
    tester,
  ) async {
    final mic = _FakeMic(grant: false);
    await _open(tester, mic);

    // A learner whose microphone is blocked is told how to undo it — that
    // sheet is the gate's own, and dismissing it is what returns "no".
    final dismiss = find.byType(TextButton).evaluate().isNotEmpty
        ? find.byType(TextButton).last
        : find.byType(FilledButton).last;
    await tester.tap(dismiss);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('HOME'), findsOneWidget);
    expect(
      find.textContaining('SEARCHING'),
      findsNothing,
      reason: 'a room with no microphone is the failure this exists to stop',
    );
  });

  testWidgets('it decides once, not once per rebuild', (tester) async {
    final mic = _FakeMic(grant: false);
    await _open(tester, mic);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(mic.checks, 1);
  });
}
