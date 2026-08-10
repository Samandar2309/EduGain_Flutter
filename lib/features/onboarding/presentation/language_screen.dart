import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale_controller.dart';
import '../../../core/ui/tokens.dart';

/// "Which language should the app be in?" — asked once, on the way in.
///
/// It has to be here rather than only inside the welcome flow, because a
/// Telegram Mini App learner never reaches that flow: they arrive already
/// signed in through the bot, so the router took them straight home and they
/// were given the default (Uzbek) with no say in it. A Russian speaker had to
/// go hunting in their profile to find the switch.
///
/// Deliberately wordless. Someone who cannot read the interface yet cannot read
/// an explanation of how to change it either — so the only content is the three
/// languages, each written in itself.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider.notifier).current;
    ref.watch(localeProvider); // rebuild as the selection moves

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppGradients.accent(AppColors.brand),
                    shape: BoxShape.circle,
                    boxShadow: AppShadow.glow(AppColors.brand),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                // The one line of text, repeated in all three languages so it
                // is legible to everyone who could be reading this screen.
                const Text(
                  'Tilni tanlang\nВыберите язык\nChoose your language',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
                for (final lang in AppLanguage.values) ...[
                  _LanguageOption(
                    lang: lang,
                    selected: lang == current,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // Persisting the choice is what dismisses this screen:
                      // the router watches for it, so there is no separate
                      // "continue" step to get stuck behind.
                      ref.read(localeProvider.notifier).setLanguage(lang);
                    },
                  ),
                  const SizedBox(height: AppSpace.md),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: lang.endonym,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.lg,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.line,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? const [] : AppShadow.card,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lang.endonym,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.brandDeep : AppColors.ink,
                  ),
                ),
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: selected ? 1 : 0,
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
