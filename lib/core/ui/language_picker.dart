import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../locale_controller.dart';

/// Open the language picker as a modal bottom sheet. The choice is persisted by
/// [localeProvider] and the whole app re-renders in the new language.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final current = AppLanguage.fromCode(
      ref.watch(localeProvider).locale?.languageCode,
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              l.languageTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          for (final lang in AppLanguage.values)
            ListTile(
              onTap: () async {
                await ref.read(localeProvider.notifier).setLanguage(lang);
                if (context.mounted) Navigator.pop(context);
              },
              leading: Icon(
                Icons.translate_rounded,
                color: lang == current ? scheme.primary : scheme.onSurfaceVariant,
              ),
              title: Text(
                lang.endonym,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: lang == current
                  ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                  : null,
            ),
        ],
      ),
    );
  }
}
