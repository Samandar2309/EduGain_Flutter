import 'dart:ui';

import 'package:edugain/core/locale_controller.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// `AppLanguage` and the localisation bundles themselves.
///
/// `LocaleController` is covered in locale_choice_test.dart, where the question
/// that matters — whether a language has been chosen yet — is the subject.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
