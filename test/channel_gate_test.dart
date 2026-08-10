import 'dart:async';

import 'package:edugain/core/api/api_client.dart';
import 'package:edugain/core/api/token_storage.dart';
import 'package:edugain/features/onboarding/application/channel_gate_controller.dart';
import 'package:edugain/features/onboarding/data/channel_repository.dart';
import 'package:edugain/features/onboarding/domain/channel_gate.dart';
import 'package:edugain/features/onboarding/presentation/channel_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The "join our channel" gate, from the client's side.
///
/// The router now holds the splash screen until this resolves, which makes
/// "always resolves" the property everything else rests on: a state that can
/// stay unknown is a white screen the learner cannot escape. So most of what
/// follows is about the ways the answer can fail to arrive — the server is
/// down, the request hangs, the payload is nonsense — and checking that each
/// one ends with the gate open rather than with nobody getting in.
class _FakeRepo extends ChannelRepository {
  _FakeRepo(this._answer) : super(ApiClient(tokens: TokenStorage()));

  final Future<ChannelGate> Function() _answer;
  int calls = 0;

  @override
  Future<ChannelGate> status() {
    calls++;
    return _answer();
  }
}

_FakeRepo _answers(ChannelGate gate) => _FakeRepo(() async => gate);
_FakeRepo _fails() => _FakeRepo(() async => throw Exception('server down'));
_FakeRepo _hangs() => _FakeRepo(() => Completer<ChannelGate>().future);

const _mustJoin = ChannelGate(
  username: 'EduGain_one',
  url: 'https://t.me/EduGain_one',
  mustJoin: true,
  subscribed: false,
);
const _joined = ChannelGate(
  username: 'EduGain_one',
  url: 'https://t.me/EduGain_one',
  mustJoin: false,
  subscribed: true,
);

const _notYet =
    "We can't see your subscription yet. Join the channel and try again.";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChannelGate', () {
    test('reads the server verdict', () {
      final gate = ChannelGate.fromJson({
        'username': 'EduGain_one',
        'url': 'https://t.me/EduGain_one',
        'required': true,
        'subscribed': false,
      });
      expect(gate.mustJoin, isTrue);
      expect(gate.username, 'EduGain_one');
    });

    test('a payload we cannot read opens the gate', () {
      // Being wrong this way lets an unsubscribed learner in. Being wrong the
      // other way locks everyone out of the product they came for.
      expect(ChannelGate.fromJson(const {}).mustJoin, isFalse);
    });
  });

  group('the gate always resolves', () {
    test('starts unknown, so nothing acts on a verdict we do not have', () {
      final c = ChannelGateController(_answers(_mustJoin));
      expect(c.state.isLoaded, isFalse);
      // Not yet true even though the server will say join: acting now would
      // show the join screen to people who already subscribed.
      expect(c.state.mustJoin, isFalse);
    });

    test('carries the verdict through when the server answers', () async {
      final c = ChannelGateController(_answers(_mustJoin));
      await c.refresh();
      expect(c.state.isLoaded, isTrue);
      expect(c.state.mustJoin, isTrue);
      expect(c.state.gate?.url, 'https://t.me/EduGain_one');
    });

    test('a subscribed learner is not gated', () async {
      final c = ChannelGateController(_answers(_joined));
      await c.refresh();
      expect(c.state.mustJoin, isFalse);
    });

    test('a failing server opens the gate rather than closing the app', () async {
      final c = ChannelGateController(_fails());
      await c.refresh();
      expect(c.state.isLoaded, isTrue, reason: 'the splash must not hang');
      expect(c.state.mustJoin, isFalse);
    });

    test('a hung request opens the gate on its own deadline', () {
      // The one that would otherwise be invisible: no error ever arrives, so
      // without the deadline the router sits on the splash forever.
      fakeAsync((async) {
        final c = ChannelGateController(_hangs());
        c.refresh();
        async.elapse(ChannelGateController.deadline - const Duration(seconds: 1));
        expect(c.state.isLoaded, isFalse, reason: 'still waiting, correctly');

        async.elapse(const Duration(seconds: 2));
        expect(c.state.isLoaded, isTrue);
        expect(c.state.mustJoin, isFalse);
      });
    });

    test('the deadline is short enough not to read as a broken app', () {
      expect(
        ChannelGateController.deadline,
        lessThanOrEqualTo(const Duration(seconds: 5)),
      );
    });

    test('signing out clears the verdict', () async {
      // Otherwise the next learner on this device inherits the previous one's.
      final c = ChannelGateController(_answers(_joined));
      await c.refresh();
      expect(c.state.isLoaded, isTrue);

      c.reset();
      expect(c.state.isLoaded, isFalse);
      expect(c.state.gate, isNull);
    });

    test('re-checking asks the server again', () async {
      // "I've subscribed" only works if this is a fresh question every time.
      final repo = _FakeRepo(() async => _mustJoin);
      final c = ChannelGateController(repo);
      await c.refresh();
      await c.refresh();
      expect(repo.calls, 2);
    });
  });

  group('ChannelScreen', () {
    Widget app(ChannelGateController controller) => ProviderScope(
      overrides: [
        channelGateProvider.overrideWith((ref) => controller),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ru'), Locale('uz')],
        locale: Locale('en'),
        home: ChannelScreen(),
      ),
    );

    testWidgets('names the channel it is asking them to join', (tester) async {
      final c = ChannelGateController(_answers(_mustJoin));
      await c.refresh();
      await tester.pumpWidget(app(c));
      await tester.pumpAndSettle();

      expect(find.text('Join our channel'), findsOneWidget);
      expect(find.text('@EduGain_one'), findsOneWidget);
      expect(find.text('Open the channel'), findsOneWidget);
      expect(find.text("I've subscribed"), findsOneWidget);
    });

    testWidgets('says so when the subscription still is not visible', (
      tester,
    ) async {
      final c = ChannelGateController(_answers(_mustJoin));
      await c.refresh();
      await tester.pumpWidget(app(c));
      await tester.pumpAndSettle();

      await tester.tap(find.text("I've subscribed"));
      await tester.pumpAndSettle();

      // Silence here would read as a dead button, and the learner would keep
      // tapping it.
      expect(find.text(_notYet), findsOneWidget);
    });

    testWidgets('stays quiet when the re-check succeeds', (tester) async {
      // The router moves them on; a "not yet" toast on the way out would be
      // both wrong and the last thing they see.
      var joined = false;
      final repo = _FakeRepo(() async => joined ? _joined : _mustJoin);
      final c = ChannelGateController(repo);
      await c.refresh();
      await tester.pumpWidget(app(c));
      await tester.pumpAndSettle();

      joined = true;
      await tester.tap(find.text("I've subscribed"));
      await tester.pumpAndSettle();

      expect(find.text(_notYet), findsNothing);
    });
  });
}
