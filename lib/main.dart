import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/speaking/presentation/avatar/photo_hero.dart';

import 'core/locale_controller.dart';
import 'core/router.dart';
import 'core/telegram_safe_area.dart';
import 'core/telegram_webapp.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Decode the hero art before the user ever reaches Speaking, so the stage
  // opens straight onto the finished hero (no fallback flash).
  PhotoHeroImages.load(rootBundle).ignore();
  // Settle "are we inside Telegram?" BEFORE anything reads it. The SDK is a
  // remote script; if startup and the router answer that question differently
  // the learner is stranded on the register screen, so it is resolved once
  // here and frozen. Instant off-web and in the normal in-Telegram case.
  await TelegramWebApp.waitForSdk();
  // No-op outside a Telegram Mini App: hides Telegram's own loading spinner
  // and claims the full viewport height once Flutter has taken over.
  TelegramWebApp.ready();
  TelegramWebApp.expand();
  // Telegram dismisses a Mini App on a downward drag — the same gesture as
  // scrolling a list back up. Without this the app closes itself while
  // somebody is reading, which is what "the bot just exits" was.
  // Telegram remembers the mode a Mini App was last opened in, and one
  // reverted `requestFullscreen()` was enough to make the chat-list entry
  // point keep arriving fullscreen — header gone, its close button over the
  // greeting, the bottom bar among the phone's navigation keys.
  TelegramWebApp.keepWindowed();
  TelegramWebApp.disableVerticalSwipes();
  // The page runs underneath the system navigation buttons and Flutter web
  // reports nothing about it, so the bottom bar landed on top of them.
  TelegramWebApp.watchInsets();
  runApp(const ProviderScope(child: EduGainApp()));
}

class EduGainApp extends ConsumerWidget {
  const EduGainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider).locale;
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
      // Folded in above every screen: the insets come from the device and
      // Telegram, not from the browser, so `SafeArea` would otherwise be a
      // no-op on exactly the phones that need it.
      builder: (_, child) =>
          TelegramSafeArea(child: child ?? const SizedBox.shrink()),
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
