import 'package:edugain/core/api/api_client.dart';
import 'package:edugain/core/api/api_exception.dart';
import 'package:edugain/core/api/token_storage.dart';
import 'package:edugain/features/feedback/application/providers.dart';
import 'package:edugain/features/feedback/data/feedback_repository.dart';
import 'package:edugain/features/feedback/presentation/feedback_form_screen.dart';
import 'package:edugain/features/feedback/presentation/session_rating_strip.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What learners tell us, from the client's side.
///
/// Two rules shape nearly every test here. A rating is a courtesy the learner
/// did us, so it is sent the instant it is tapped — waiting for them to
/// explain would lose the verdict from everyone who does not — and it is never
/// allowed to put an error on the screen showing their result. A written
/// report is the opposite: they went looking for the form, so it is worth
/// telling them plainly when it did not go through.
class _FakeRepo extends FeedbackRepository {
  _FakeRepo({this.failWith}) : super(ApiClient(tokens: TokenStorage()));

  final Object? failWith;
  final List<Map<String, Object?>> sent = [];

  @override
  Future<void> report({required String message, required String locale}) async {
    if (failWith != null) throw failWith!;
    sent.add({'message': message, 'locale': locale});
  }

  @override
  Future<void> rateSession({
    required String sessionId,
    required int stars,
    required String locale,
    String comment = '',
  }) async {
    if (failWith != null) throw failWith!;
    sent.add({'session': sessionId, 'stars': stars, 'comment': comment});
  }
}

Widget _wrap(_FakeRepo repo, Widget child) => ProviderScope(
  overrides: [feedbackRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ru'), Locale('uz')],
    locale: const Locale('en'),
    home: Scaffold(body: child),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('diagnostics', () {
    test('carry what triage would otherwise have to go and ask for', () {
      final context = FeedbackRepository.diagnostics('uz');
      expect(context['locale'], 'uz');
      expect(context['platform'], isNotEmpty);
      expect(context.containsKey('telegram'), isTrue);
    });

    test('carry nothing the server does not already know from the token', () {
      // Whatever is in here gets rendered into a Telegram message and an admin
      // page, so it stays limited to what triage needs.
      expect(
        FeedbackRepository.diagnostics('en').keys.toSet(),
        {'platform', 'locale', 'telegram'},
      );
    });
  });

  group('the written report', () {
    testWidgets('sends what was typed, and nothing else to fill in', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_wrap(repo, const FeedbackFormScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Add more topics');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(repo.sent.single['message'], 'Add more topics');
    });

    testWidgets('asks the learner to classify nothing', (tester) async {
      // One box. Deciding whether your problem is a bug or an idea is our
      // job, not a toll charged on the person doing us a favour.
      final repo = _FakeRepo();
      await tester.pumpWidget(_wrap(repo, const FeedbackFormScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('refuses to send an empty one', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_wrap(repo, const FeedbackFormScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(repo.sent, isEmpty);
      expect(find.text('Please write something first'), findsOneWidget);
    });

    testWidgets('trims before sending', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_wrap(repo, const FeedbackFormScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  spacey  ');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(repo.sent.single['message'], 'spacey');
    });

    testWidgets('explains the daily cap in the learner\'s own language', (
      tester,
    ) async {
      // The server's 429 body is English prose about a limit. Someone who
      // reached it deserves a sentence they can read.
      final repo = _FakeRepo(
        failWith: const ApiException(
          code: 'RATE_LIMITED',
          message: 'At most 10 reports a day',
          statusCode: 429,
        ),
      );
      await tester.pumpWidget(_wrap(repo, const FeedbackFormScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'again');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(
        find.text("That's enough messages for today. Let's carry on tomorrow."),
        findsOneWidget,
      );
      expect(find.text('At most 10 reports a day'), findsNothing);
    });

    testWidgets('says so when it did not go through', (tester) async {
      final repo = _FakeRepo(failWith: ApiException.network());
      await tester.pumpWidget(_wrap(repo, const FeedbackFormScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'something');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Unlike a rating, this one they deliberately sat down to write.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(FeedbackFormScreen), findsOneWidget);
    });
  });

  group('the session rating', () {
    Widget strip(_FakeRepo repo) =>
        _wrap(repo, const SessionRatingStrip(sessionId: 's-1'));

    Future<void> tapStar(WidgetTester tester, int n) async {
      await tester.tap(find.bySemanticsLabel('$n'));
      await tester.pumpAndSettle();
    }

    testWidgets('sends the star on the tap itself', (tester) async {
      // The load-bearing one. Most people will never write a comment, and
      // holding the rating until they do would throw away all those votes.
      final repo = _FakeRepo();
      await tester.pumpWidget(strip(repo));
      await tester.pumpAndSettle();

      await tapStar(tester, 4);

      expect(repo.sent.single['stars'], 4);
      expect(repo.sent.single['session'], 's-1');
      expect(repo.sent.single['comment'], '');
    });

    testWidgets('offers all five', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(strip(repo));
      await tester.pumpAndSettle();

      for (var n = 1; n <= 5; n++) {
        expect(find.bySemanticsLabel('$n'), findsOneWidget);
      }
    });

    testWidgets('a comment updates the same vote', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(strip(repo));
      await tester.pumpAndSettle();

      await tapStar(tester, 2);
      await tester.enterText(find.byType(TextField), 'Meni tushunmadi');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // The server upserts on (learner, session), so this is one vote that
      // gained detail, not two votes.
      expect(repo.sent.length, 2);
      expect(repo.sent.last['stars'], 2);
      expect(repo.sent.last['comment'], 'Meni tushunmadi');
    });

    testWidgets('the comment box is offered whatever the score', (tester) async {
      // A five-star session can still have one thing worth telling us, and a
      // learner should not have to rate us badly to earn the right to explain.
      final repo = _FakeRepo();
      await tester.pumpWidget(strip(repo));
      await tester.pumpAndSettle();

      await tapStar(tester, 5);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('nothing is asked before a star is given', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(strip(repo));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('an empty comment is not sent as one', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(strip(repo));
      await tester.pumpAndSettle();

      await tapStar(tester, 3);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(repo.sent.length, 1, reason: 'only the star should have gone');
    });

    testWidgets('changing your mind re-sends the new star', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(strip(repo));
      await tester.pumpAndSettle();

      await tapStar(tester, 1);
      await tapStar(tester, 5);

      expect(repo.sent.last['stars'], 5);
    });

    testWidgets('a failed rating never lands on the result screen', (
      tester,
    ) async {
      // They came to this screen to read their score. Charging them an error
      // for the courtesy of rating us would be exactly backwards.
      final repo = _FakeRepo(failWith: ApiException.network());
      await tester.pumpWidget(strip(repo));
      await tester.pumpAndSettle();

      await tapStar(tester, 2);

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
      // And the strip still behaves as though it landed, so they are not left
      // tapping something that appears to do nothing.
      expect(find.text('Thanks — that helps.'), findsOneWidget);
    });
  });
}
