import 'package:edugain/core/ui/flags.dart';
import 'package:edugain/features/onboarding/presentation/learning_language_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The learning-language step, after it stopped being a question.
///
/// It used to list four languages — English open, three marked "coming soon"
/// — and tapping a closed one registered a vote for what to build next. The
/// tests that went with it are gone along with the feature: a chooser with one
/// real answer is a question the app already knew the answer to, put in front
/// of somebody three screens into signing up.
///
/// What is left has to hold: the screen says English, shows the flag, offers
/// nothing else to tap, and still writes the value the router is waiting for.
void main() {
  Widget app({Locale locale = const Locale('uz')}) => ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const LearningLanguageScreen(),
    ),
  );

  testWidgets('every row carries a drawn flag, not an emoji', (tester) async {
    // An emoji flag renders as the letters "GB" on Windows, where this app is
    // built and reviewed, and differently again in each browser. The painter
    // is the point.
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byType(FlagBadge), findsOneWidget);
  });

  testWidgets('the one course is chosen before anything is tapped', (
    tester,
  ) async {
    """Continue must work on the first tap.

    With one row, making the learner select it first would be a step whose only
    purpose is to be completed.""";
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('nothing on this screen is a choice', (tester) async {
    """The whole complaint about the old version.

    Three tappable rows that could not be chosen, each wearing a "coming soon"
    badge, on a gate somebody is trying to get through. If a language list ever
    comes back it should be because a second language opened.""";
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    for (final ghost in ['한국어', 'Русский', 'Türkçe', 'Tez kunda']) {
      expect(find.text(ghost), findsNothing, reason: '$ghost should be gone');
    }
    // One button, and it goes forward.
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('there is no heading above the list', (tester) async {
    """Removed on the owner's instruction.

    The screen had a title and a line explaining why only one language was
    listed. With a single row and a Continue button, the explanation was more
    screen than the thing it explained.""";
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Whatever is on this screen, it is the row and the button.
    expect(find.byType(FlagBadge), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    final texts = tester.widgetList<Text>(find.byType(Text)).length;
    expect(texts, lessThanOrEqualTo(2), reason: 'the language and the button');
  });

  testWidgets('the button reads in all three interface languages', (
    tester,
  ) async {
    for (final code in ['uz', 'en', 'ru']) {
      await tester.pumpWidget(app(locale: Locale(code)));
      await tester.pumpAndSettle();
      final l = await AppLocalizations.delegate.load(Locale(code));
      expect(find.text(l.continueAction), findsOneWidget, reason: code);
      // The language name is not translated — a learner looks for the endonym.
      expect(find.text('English'), findsOneWidget, reason: code);
    }
  });
}
