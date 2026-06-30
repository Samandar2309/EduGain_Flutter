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

/// Holds the chosen UI locale, persisted in SharedPreferences. `null` means
/// "follow the device language" (resolved against the supported locales, with
/// Uzbek as the market fallback). Loads lazily on construction;
/// `SharedPreferences.getInstance()` caches its instance so the lookups are
/// cheap.
class LocaleController extends StateNotifier<Locale?> {
  LocaleController() : super(null) {
    _load();
  }

  static const String prefsKey = 'app.locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = AppLanguage.fromCode(prefs.getString(prefsKey));
    // Don't clobber a choice the user made before prefs finished loading.
    if (lang != null && state == null) state = lang.locale;
  }

  /// The currently active language (defaults to Uzbek until one is chosen).
  AppLanguage get current =>
      AppLanguage.fromCode(state?.languageCode) ?? AppLanguage.uzbek;

  /// Switch the UI language and persist it.
  Future<void> setLanguage(AppLanguage lang) async {
    state = lang.locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, lang.code);
  }
}

final localeProvider = StateNotifierProvider<LocaleController, Locale?>(
  (ref) => LocaleController(),
);
