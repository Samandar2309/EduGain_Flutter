import 'package:edugain/core/locale_controller.dart';
import 'package:edugain/features/onboarding/application/onboarding_controller.dart';
import 'package:edugain/features/onboarding/presentation/welcome_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingController', () {
    test('first launch resolves to false after the prefs load', () async {
      SharedPreferences.setMockInitialValues({});
      final c = OnboardingController();
      expect(c.state, isNull); // loading — router must hold the splash
      await pumpEventQueue();
      expect(c.state, isFalse);
    });

    test('a completed device resolves to true', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingController.prefsKey: true,
      });
      final c = OnboardingController();
      await pumpEventQueue();
      expect(c.state, isTrue);
    });

    test('complete() persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final c = OnboardingController();
      await c.complete();
      expect(c.state, isTrue);

      final c2 = OnboardingController();
      await pumpEventQueue();
      expect(c2.state, isTrue);
    });

    test('complete() racing the disk load is not clobbered', () async {
      SharedPreferences.setMockInitialValues({});
      final c = OnboardingController();
      await c.complete(); // before _load resolves
      await pumpEventQueue();
      expect(c.state, isTrue);
    });
  });

  group('WelcomeScreen', () {
    Widget app() => const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ru'), Locale('uz')],
        locale: Locale('en'),
        home: WelcomeScreen(),
      ),
    );

    testWidgets('walks language page and 3 slides to the final CTA', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Page 0 — the language choice with all three endonyms.
      expect(find.text('Choose your language'), findsOneWidget);
      expect(find.text('O‘zbekcha'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Through the three value slides.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Speak with an AI tutor'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Live coaching as you talk'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('A path to your goal'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Continue'), findsNothing); // CTA switched on last page
    });

    testWidgets('final CTA marks onboarding complete', (tester) async {
      SharedPreferences.setMockInitialValues({});
      late ProviderContainer container;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      container = ProviderScope.containerOf(
        tester.element(find.byType(WelcomeScreen)),
      );

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(container.read(onboardingProvider), isTrue);
    });

    testWidgets('skip completes onboarding immediately', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WelcomeScreen)),
      );

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(container.read(onboardingProvider), isTrue);
    });

    testWidgets('tapping a language switches the app locale', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WelcomeScreen)),
      );

      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      expect(container.read(localeProvider).locale, const Locale('ru'));
      expect(
        container.read(localeProvider.notifier).current,
        AppLanguage.russian,
      );
    });
  });
}
