import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../application/word_pool.dart';
import '../domain/game.dart';
import '../domain/models.dart';

/// Pick a way to play, and play.
///
/// Getting into a game used to mean choosing a set first, then a mode from a
/// sheet — two decisions before anything happened, the first of which nobody
/// arrives wanting to make. The deck is now chosen for the learner from the
/// words they are actually working on, so this screen is the only step left.
class GameModesScreen extends ConsumerWidget {
  const GameModesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(learningWordsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text("So'z o'yinlari"),
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: words.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Empty(
          text: 'So‘zlarni yuklab bo‘lmadi. Qayta urinib ko‘ring.',
        ),
        data: (pool) {
          if (!canPlay(pool)) {
            return const _Empty(
              text: 'O‘yin uchun so‘z yetarli emas. Darslardan bir nechta '
                  'so‘z o‘rganing va qayting.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.xxl,
            ),
            children: [
              _ModeCard(
                icon: Icons.person_rounded,
                colour: AppColors.vocabulary,
                title: "Yolg'iz o'ynash",
                subtitle: "O'z tezligingizda",
                onTap: () => _play(context, pool, GameMode.solo),
              ),
              const SizedBox(height: AppSpace.md),
              _ModeCard(
                icon: Icons.sports_esports_rounded,
                colour: AppColors.speaking,
                title: 'Gainsy bilan bellashuv',
                subtitle: 'Botga qarshi tezlik poygasi',
                onTap: () => _play(context, pool, GameMode.duel),
              ),
              const SizedBox(height: AppSpace.md),
              _ModeCard(
                icon: Icons.groups_rounded,
                colour: AppColors.placement,
                title: "Odam bilan o'ynash",
                subtitle: 'Jonli raqib bilan tezlik poygasi',
                onTap: () => _play(context, pool, GameMode.online),
              ),
              const SizedBox(height: AppSpace.md),
              _ModeCard(
                icon: Icons.spellcheck_rounded,
                colour: AppColors.streak,
                title: "Harflardan yig'ish",
                subtitle: "So'zni xotiradan harflab tuzing",
                onTap: () => _play(
                  context,
                  pool,
                  GameMode.solo,
                  route: '/vocabulary/spell',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _play(
    BuildContext context,
    List<VocabItem> pool,
    GameMode mode, {
    String? route,
  }) {
    // No loading dialog: the words are already here. Fetching them once, up
    // front, is what lets a tap on a mode be the last thing that happens
    // before the game starts.
    final launch = VocabGameLaunch(
      items: pool,
      mode: mode,
      title: "So'z o'yini",
    );
    context.push(
      route ?? (mode == GameMode.online ? '/vocabulary/duel' : '/vocabulary/game'),
      extra: launch,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.inkSoft, height: 1.45),
      ),
    ),
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.colour,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colour.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: colour, size: 24),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
