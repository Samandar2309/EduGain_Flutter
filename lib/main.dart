import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/speaking/presentation/avatar/photo_hero.dart';

import 'core/locale_controller.dart';
import 'core/router.dart';
import 'core/telegram_webapp.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Decode the hero art before the user ever reaches Speaking, so the stage
  // opens straight onto the finished hero (no fallback flash).
  PhotoHeroImages.load(rootBundle).ignore();
  // No-op outside a Telegram Mini App: hides Telegram's own loading spinner
  // and claims the full viewport height once Flutter has taken over.
  TelegramWebApp.ready();
  TelegramWebApp.expand();
  runApp(const ProviderScope(child: EduGainApp()));
}

class EduGainApp extends ConsumerWidget {
  const EduGainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'EduGain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // The whole product is designed in the light "Premium & Clean" language
      // (the games, cards and heroes all use the light tokens). Pin to light so
      // the app never renders half-dark when the Telegram Mini App / device is
      // in dark mode — a proper dark theme is a separate, deliberate project.
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // No explicit choice → follow the device language if supported, else fall
      // back to Uzbek (the primary market) rather than the codegen default.
      localeResolutionCallback: (device, supported) {
        if (locale != null) return locale;
        return AppLanguage.fromCode(device?.languageCode)?.locale ??
            const Locale('uz');
      },
    );
  }
}
