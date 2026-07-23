import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/game.dart';
import '../domain/models.dart';
import 'vocab_landing_screen.dart';

/// The set library. The learner arrives here having already chosen an intent on
/// the landing screen — to *browse* the words or to *play* (test). The list is
/// identical; only what a set-tap opens differs (a dictionary vs the games).
class VocabSetListScreen extends ConsumerWidget {
  const VocabSetListScreen({required this.intent, super.key});

  final VocabIntent intent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sets = ref.watch(vocabSetsProvider);
    final title =
        intent == VocabIntent.browse ? "So'zlarni o'rganish" : 'Bilimni sinash';
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.canvas,
      ),
      body: sets.when(
        loading: () => const AppLoader(),
        error: (_, _) => Center(child: Text(l.loadFailed)),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xxl),
          children: [
            if (list.isEmpty)
              Center(child: Text(l.noSets))
            else
              ..._grouped(list),
          ],
        ),
      ),
    );
  }

  List<Widget> _grouped(List<VocabSet> sets) {
    final groups = <String, List<VocabSet>>{};
    for (final s in sets) {
      groups.putIfAbsent(s.category, () => []).add(s);
    }
    return [
      for (final entry in groups.entries) ...[
        SectionHeader(title: _titleCase(entry.key)),
        for (final s in entry.value)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: _SetCard(set: s, intent: intent),
          ),
        const SizedBox(height: AppSpace.sm),
      ],
    ];
  }
}

String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _SetCard extends ConsumerWidget {
  const _SetCard({required this.set, required this.intent});
  final VocabSet set;
  final VocabIntent intent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (set.isLocked) {
              showApiError(
                context,
                const ApiException(code: 'PAYWALL', message: '', statusCode: 402),
              );
            } else if (intent == VocabIntent.browse) {
              context.push('/vocabulary/words', extra: set);
            } else {
              _openModeSheet(context, ref, set);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppGradients.accent(AppColors.vocabulary),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadow.glow(AppColors.vocabulary),
                  ),
                  child: Center(
                    child: Text(
                      set.cefrLevel,
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.style_rounded,
                              size: 13, color: AppColors.vocabulary),
                          const SizedBox(width: 4),
                          Text(
                            set.wordCount > 0 ? "${set.wordCount} so'z" : "So'z to'plami",
                            style: const TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                if (set.isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.xp.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 12, color: AppColors.xp),
                        const SizedBox(width: 4),
                        Text(
                          l.premiumBadge,
                          style: const TextStyle(
                            color: AppColors.xp, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppGradients.accent(AppColors.vocabulary),
                      shape: BoxShape.circle,
                      boxShadow: AppShadow.glow(AppColors.vocabulary),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 24),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks "how do you want to play this set?" — the one decision point between
/// the library and a game. A premium, compact sheet: four game modes then a
/// divider and the review option. `isScrollControlled` + a scroll view guarantee
/// every option is reachable on any screen size (the fifth was clipping before).
Future<void> _openModeSheet(BuildContext context, WidgetRef ref, VocabSet set) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.lg + MediaQuery.of(ctx).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            // header: CEFR chip + set title
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppGradients.accent(AppColors.vocabulary),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      set.cefrLevel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const Text(
                        "Qanday o'ynaymiz?",
                        style: TextStyle(color: AppColors.inkFaint, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            _ModeTile(
              icon: Icons.person_rounded,
              color: AppColors.vocabulary,
              title: "Solo o'ynash",
              subtitle: "O'z tezligingizda so'z yodlang",
              onTap: () => _launch(ctx, ref, set, GameMode.solo),
            ),
            const SizedBox(height: AppSpace.sm),
            _ModeTile(
              icon: Icons.spellcheck_rounded,
              color: AppColors.streak,
              title: "Harflardan yig'ish",
              subtitle: "So'zni xotiradan harflab tuzing",
              onTap: () =>
                  _launch(ctx, ref, set, GameMode.solo, route: '/vocabulary/spell'),
            ),
            const SizedBox(height: AppSpace.sm),
            _ModeTile(
              icon: Icons.sports_esports_rounded,
              color: AppColors.speaking,
              title: 'Gainsy bilan bellashuv',
              subtitle: 'Botga qarshi tezlik poygasi',
              onTap: () => _launch(ctx, ref, set, GameMode.duel),
            ),
            const SizedBox(height: AppSpace.sm),
            _ModeTile(
              icon: Icons.groups_rounded,
              color: AppColors.placement,
              title: "Odam bilan o'ynash",
              subtitle: 'Jonli raqib bilan tezlik poygasi',
              onTap: () => _launch(ctx, ref, set, GameMode.online),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _launch(
  BuildContext sheetCtx, WidgetRef ref, VocabSet set, GameMode mode,
  {String? route}) async {
  Navigator.of(sheetCtx).pop();
  final messenger = ScaffoldMessenger.of(sheetCtx);
  final router = GoRouter.of(sheetCtx);
  showDialog<void>(
    context: sheetCtx,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final detail = await ref.read(vocabularyRepositoryProvider).getSet(set.id);
    router.pop(); // close the loader
    if (detail.items.length < 2) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Bu to'plamda o'yin uchun so'z yetarli emas")),
      );
      return;
    }
    final launch = VocabGameLaunch(
      items: detail.items,
      mode: mode,
      title: set.title,
      setId: set.id,
    );
    // Each game has its own screen; online duels their own matchmaking flow.
    final target = route ??
        (mode == GameMode.online ? '/vocabulary/duel' : '/vocabulary/game');
    router.push(target, extra: launch);
  } on Object {
    router.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Yuklashda xatolik. Qayta urinib ko‘ring.')),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Explicit ink colour — inheriting the sheet's default text
                    // style rendered the title faded (near-invisible) before.
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
