import 'package:edugain/core/api/token_storage.dart';
import 'package:edugain/features/group/application/group_call_controller.dart';
import 'package:edugain/features/group/presentation/group_call_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Everybody in the room has a face — including the person holding the phone.
///
/// Their own seat is the one the screen assembles by itself, because the
/// server's participant list deliberately leaves the reader out of it. That is
/// exactly why it shipped without a photo while every other seat had one: the
/// member list was fixed and looked fixed, and nothing pointed at the one face
/// that does not come from it. So this asserts on the self seat specifically.
class _FakeCall extends GroupCallController {
  _FakeCall(this._fixture, String avatar)
      : super(TokenStorage(), 'Samandar', 'ABC123', 'uz', avatar,
            autoStart: false);

  final GroupCallState _fixture;
  void pin() => state = _fixture;
}

GroupMember _m(String id, String name, String avatar) {
  final m = GroupMember(id: id, name: name, avatar: avatar);
  m.connected = true;
  return m;
}

/// Every URL the room is currently trying to draw.
Set<String> _drawn(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((i) => i.image)
    .whereType<NetworkImage>()
    .map((n) => n.url)
    .toSet();

void main() {
  Widget app(_FakeCall call) => ProviderScope(
        overrides: [
          groupCallControllerProvider('ABC123').overrideWith((ref) => call),
        ],
        child: MaterialApp(
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

  Future<Set<String>> render(WidgetTester tester, _FakeCall call) async {
    // Deliberately wider than a phone. The real Inter and icon fonts are not
    // loaded here, so the fallback face is wide enough to overflow a 390pt top
    // bar — a layout complaint about this test's fonts, not about the screen.
    // The screenshot test, which loads the real fonts, owns how the room looks;
    // this one owns what it draws.
    tester.view.physicalSize = const Size(900 * 2, 1600 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(call));
    // Explicit frames, not pumpAndSettle: the waveform animates forever, so
    // there is no settled state to wait for.
    for (var i = 0; i < 3; i++) {
      call.pin();
      await tester.pump(const Duration(milliseconds: 100));
    }
    return _drawn(tester);
  }

  const mine = 'https://example.test/me.jpg';

  testWidgets('my own seat draws my picture, not just my initial',
      (tester) async {
    final call = _FakeCall(
      GroupCallState(
        phase: GroupPhase.live,
        selfId: 'me',
        hostId: 'u1',
        title: 'Airport Lounge',
        maxParticipants: 50,
        members: [_m('u1', 'Aziza', 'https://example.test/aziza.jpg')],
      ),
      mine,
    );
    final urls = await render(tester, call);
    expect(urls, contains(mine));
    expect(urls, contains('https://example.test/aziza.jpg'));
  });

  testWidgets('no picture is not an error — the initial stands in',
      (tester) async {
    final call = _FakeCall(
      GroupCallState(
        phase: GroupPhase.live,
        selfId: 'me',
        hostId: 'me',
        title: 'Airport Lounge',
        maxParticipants: 50,
        members: [_m('u1', 'Aziza', '')],
      ),
      '',
    );
    final urls = await render(tester, call);
    expect(urls, isEmpty);
    expect(find.text('S'), findsWidgets);
  });
}
