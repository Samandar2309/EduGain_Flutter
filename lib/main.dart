import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale_controller.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';

void main() {
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
