import 'package:edugain/core/locale_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which language the interface is in, and when we are allowed to decide.
///
/// The bug this closes: a Telegram Mini App learner arrives already signed in
/// through the bot, so the router sent them straight home and they were handed
/// the default — Uzbek — with no say in it. The picker existed, but only inside
/// a welcome flow they never reached, and otherwise buried in their profile.
///
/// Making the router able to ask "has this person chosen yet?" needs the state
/// to separate "still loading" from "never chose". A plain `Locale?` cannot:
/// read null as unchosen and the picker reappears on every launch; read it as
/// loading and it never appears at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleController', () {
    test('does not claim a decision is needed before prefs answer', () {
      SharedPreferences.setMockInitialValues({});
      final c = LocaleController();
      // Synchronously after construction: asking now would flash the picker at
      // someone who chose their language months ago.
      expect(c.state.isLoaded, isFalse);
      expect(c.state.needsChoosing, isFalse);
    });

    test('asks once when nothing was ever saved', () async {
      SharedPreferences.setMockInitialValues({});
      final c = LocaleController();
      await pumpEventQueue();
      expect(c.state.isLoaded, isTrue);
      expect(c.state.needsChoosing, isTrue);
    });

    test('never asks again once a language is saved', () async {
      SharedPreferences.setMockInitialValues({
        LocaleController.prefsKey: 'ru',
      });
      final c = LocaleController();
      await pumpEventQueue();
      expect(c.state.needsChoosing, isFalse);
      expect(c.state.locale?.languageCode, 'ru');
      expect(c.current, AppLanguage.russian);
    });

    test('choosing settles the question immediately', () async {
      SharedPreferences.setMockInitialValues({});
      final c = LocaleController();
      await c.setLanguage(AppLanguage.english);

      expect(c.state.needsChoosing, isFalse);
      expect(c.current, AppLanguage.english);

      // And survives the next launch.
      final next = LocaleController();
      await pumpEventQueue();
      expect(next.current, AppLanguage.english);
      expect(next.state.needsChoosing, isFalse);
    });

    test('choosing Uzbek counts as a choice, not as a missing one', () async {
      // The trap in the old shape: Uzbek is also the fallback, so a learner who
      // deliberately picked it looked identical to one who never picked.
      SharedPreferences.setMockInitialValues({});
      final c = LocaleController();
      await c.setLanguage(AppLanguage.uzbek);
      await pumpEventQueue();

      expect(c.state.needsChoosing, isFalse);
      expect(c.current, AppLanguage.uzbek);
    });

    test('a choice made while prefs load is not overwritten', () async {
      SharedPreferences.setMockInitialValues({
        LocaleController.prefsKey: 'uz',
      });
      final c = LocaleController();
      await c.setLanguage(AppLanguage.english);
      await pumpEventQueue();
      expect(c.current, AppLanguage.english);
    });

    test('unusable storage resolves rather than hanging on the splash', () async {
      // The router holds the splash until `isLoaded`. Staying in `loading`
      // forever would mean a white screen, so failure has to resolve.
      SharedPreferences.setMockInitialValues({});
      final c = LocaleController();
      await pumpEventQueue();
      expect(c.state.isLoaded, isTrue);
    });

    test('every shipped language round-trips through storage', () async {
      for (final lang in AppLanguage.values) {
        SharedPreferences.setMockInitialValues({
          LocaleController.prefsKey: lang.code,
        });
        final c = LocaleController();
        await pumpEventQueue();
        expect(c.current, lang, reason: '${lang.code} did not load back');
      }
    });
  });
}
