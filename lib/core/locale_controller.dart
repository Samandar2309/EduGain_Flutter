import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The UI languages the app supports. Order = display order in the picker.
enum AppLanguage {
  uzbek('uz'),
  russian('ru'),
  english('en');

  const AppLanguage(this.code);

  final String code;

  Locale get locale => Locale(code);

  /// Native name of the language, shown the same regardless of the active UI
  /// language (so users always recognise their own).
  String get endonym => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.russian => 'Русский',
    AppLanguage.uzbek => 'O‘zbekcha',
  };

  static AppLanguage? fromCode(String? code) {
    for (final lang in AppLanguage.values) {
      if (lang.code == code) return lang;
    }
    return null;
  }
}

/// The chosen UI language, and whether we have finished looking for it.
///
/// Both halves are needed. "Has this learner picked a language yet?" decides
/// whether to show them the picker on the way in, and a plain `Locale?` cannot
/// answer it: null means both "preferences are still loading" and "never
/// chose". Treating the first as the second asks the question again on every
/// launch; treating the second as the first never asks it at all — and the
/// default is Uzbek, so a Russian speaker would simply be given an Uzbek app.
class LocaleChoice {
  const LocaleChoice._(this.locale, this.isLoaded);

  /// Preferences have not answered yet.
  const LocaleChoice.loading() : this._(null, false);

  /// Preferences answered: [locale] is the saved choice, or null if there
  /// isn't one.
  const LocaleChoice.resolved(Locale? locale) : this._(locale, true);

  /// The explicitly chosen locale, or null when none was chosen.
  final Locale? locale;

  /// Whether persistence has answered.
  final bool isLoaded;

  /// Whether the learner still has to be asked. Only true once we actually
  /// know there is nothing saved.
  bool get needsChoosing => isLoaded && locale == null;
}

/// Holds the chosen UI locale, persisted in SharedPreferences.
/// `SharedPreferences.getInstance()` caches its instance, so the lookups here
/// are cheap.
class LocaleController extends StateNotifier<LocaleChoice> {
  LocaleController() : super(const LocaleChoice.loading()) {
    _load();
  }

  static const String prefsKey = 'app.locale';

  Future<void> _load() async {
    AppLanguage? lang;
    try {
      lang = AppLanguage.fromCode(
        (await SharedPreferences.getInstance()).getString(prefsKey),
      );
    } catch (_) {
      // Storage unavailable — resolve as "not chosen" rather than staying in
      // `loading` forever, which would hold the app on the splash screen.
      lang = null;
    }
    if (!mounted) return;
    // Don't clobber a choice made while prefs were loading, but do mark the
    // state resolved either way.
    state = LocaleChoice.resolved(state.locale ?? lang?.locale);
  }

  /// The language the UI renders in — Uzbek until a choice is made, since this
  /// is a single-market product and it is the most likely one.
  AppLanguage get current =>
      AppLanguage.fromCode(state.locale?.languageCode) ?? AppLanguage.uzbek;

  /// Switch the UI language and persist it.
  Future<void> setLanguage(AppLanguage lang) async {
    state = LocaleChoice.resolved(lang.locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, lang.code);
  }
}

final localeProvider = StateNotifierProvider<LocaleController, LocaleChoice>(
  (ref) => LocaleController(),
);
