import 'dart:ui';

import 'package:edugain/core/locale_controller.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleController', () {
    test('starts null (follow device) when nothing is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final c = LocaleController();
      await pumpEventQueue();
      expect(c.state, isNull);
      expect(c.current, AppLanguage.uzbek); // default fallback
    });

    test('loads a persisted language on construction', () async {
      SharedPreferences.setMockInitialValues({
        LocaleController.prefsKey: 'ru',
      });
      final c = LocaleController();
      await pumpEventQueue();
      expect(c.state, const Locale('ru'));
      expect(c.current, AppLanguage.russian);
    });

    test('setLanguage updates state and persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final c = LocaleController();
      await c.setLanguage(AppLanguage.english);
      expect(c.state, const Locale('en'));

      final c2 = LocaleController();
      await pumpEventQueue();
      expect(c2.current, AppLanguage.english);
    });
  });

  group('AppLanguage', () {
    test('fromCode maps known codes and rejects unknown', () {
      expect(AppLanguage.fromCode('uz'), AppLanguage.uzbek);
      expect(AppLanguage.fromCode('ru'), AppLanguage.russian);
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
      expect(AppLanguage.fromCode('fr'), isNull);
      expect(AppLanguage.fromCode(null), isNull);
    });
  });

  group('AppLocalizations', () {
    test('supports exactly en, ru, uz', () {
      final codes =
          AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      expect(codes, {'en', 'ru', 'uz'});
    });

    test('resolves keys (incl. placeholders) for every locale', () async {
      for (final code in ['en', 'ru', 'uz']) {
        final l = await AppLocalizations.delegate.load(Locale(code));
        expect(l.greeting('Aziz'), contains('Aziz'));
        expect(l.otpSentTo('+998').contains('+998'), isTrue);
        expect(l.wordsWaiting(3), contains('3'));
        expect(l.languageTitle, isNotEmpty);
        expect(l.sendCode, isNotEmpty);
      }
    });
  });
}
