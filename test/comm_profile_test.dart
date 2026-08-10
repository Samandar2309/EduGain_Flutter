import 'package:edugain/features/profile/presentation/profile_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The card must speak the learner's language, and must not leak the taxonomy.
///
/// Both failures shipped and neither was visible to `flutter analyze` or to any
/// test: the chips rendered the backend enum verbatim, so an Uzbek learner read
/// "word choice" and "verb tense" among their own results, and "other" — the
/// catch-all bucket — appeared as something to practise.
void main() {
  Future<AppLocalizations> load(String code) =>
      AppLocalizations.delegate.load(Locale(code));

  test('the catch-all bucket is never shown to anybody', () async {
    for (final code in ['uz', 'en', 'ru']) {
      final l = await load(code);
      expect(CommunicationProfileCard.tagLabel(l, 'other'), isNull,
          reason: '"other" reached the $code UI');
    }
  });

  test('every tag the server can emit is translated in all three languages',
      () async {
    // The closed taxonomy from fastapi_app/app/domain/speaking/coaching.py.
    const tags = [
      'verb_tense',
      'word_choice',
      'word_order',
      'articles',
      'preposition',
      'plural',
      'agreement',
      'pronoun',
      'comparative',
      'conditional',
      'question_form',
      'collocation',
    ];
    final english = await load('en');
    for (final code in ['uz', 'ru']) {
      final l = await load(code);
      for (final tag in tags) {
        final label = CommunicationProfileCard.tagLabel(l, tag);
        expect(label, isNotNull, reason: '$tag missing in $code');
        // An untranslated key falls through to the raw enum with underscores
        // swapped for spaces — which is exactly what shipped.
        expect(label, isNot(tag.replaceAll('_', ' ')),
            reason: '$tag is still the raw enum in $code');
        expect(label, isNot(CommunicationProfileCard.tagLabel(english, tag)),
            reason: '$tag was left in English in $code');
      }
    }
  });

  test('an unknown tag degrades to readable text rather than disappearing',
      () async {
    final l = await load('en');
    expect(CommunicationProfileCard.tagLabel(l, 'future_perfect'),
        'future perfect');
  });

  _xpLabels();
}

/// XP history must not print the server's enum at a learner.
///
/// `course` — the source the entire course path awards under — was missing
/// from the label map, so every lesson anybody finished showed up in their
/// history as the bare word "course". A map cannot fail loudly here: an
/// unknown key prints itself and looks almost plausible.
void _xpLabels() {
  test('every XP source the server can send has a label', () async {
    // apps/gamification/models.py :: XpSource
    const sources = [
      'speaking',
      'course',
      'writing',
      'vocab',
      'grammar',
      'listening',
      'streak',
      'daily_goal',
    ];
    for (final code in ['uz', 'en', 'ru']) {
      final l = await AppLocalizations.delegate.load(Locale(code));
      for (final source in sources) {
        final label = xpSourceLabel(l, source);
        expect(label, isNot(source), reason: '$source is raw in $code');
        expect(label, isNotEmpty);
      }
    }
  });
}
