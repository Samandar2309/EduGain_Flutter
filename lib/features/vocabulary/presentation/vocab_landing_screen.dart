import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../application/providers.dart';
import '../domain/game.dart';

/// Why the learner opened a set: to read the words, or to be tested on them.
/// The set list is the same either way; only the tap destination differs.
enum VocabIntent { browse, play }

/// The vocabulary entry — the one decision the module opens on: learn the words
/// (see them with translations) or test yourself (the games). A spaced-
/// repetition review nudge sits on top when words are due.
class VocabLandingScreen extends ConsumerWidget {
  const VocabLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(reviewDueProvider);
    final dueCount = due.valueOrNull?.length ?? 0;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Vocabulary'),
        backgroundColor: AppColors.canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xxl),
        children: [
          if (dueCount > 0) ...[
            _ReviewHero(dueCount: dueCount),
            const SizedBox(height: AppSpace.xl),
          ],
          const Text(
            'Nima qilamiz?',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: AppSpace.md),
          _ChoiceCard(
            icon: Icons.menu_book_rounded,
            colors: const [Color(0xFFF6A609), Color(0xFFEA8207)], // amber
            title: "So'zlarni o'rganish",
            subtitle: 'Yangi so‘zlarni tarjimasi va misoli bilan ko‘ring',
            onTap: () => context.push('/vocabulary/sets', extra: VocabIntent.browse),
          ),
          const SizedBox(height: AppSpace.md),
          _ChoiceCard(
            icon: Icons.sports_esports_rounded,
            colors: const [Color(0xFF6366F1), Color(0xFF4F46E5)], // indigo
            title: 'Bilimni sinash',
            subtitle: 'O‘yinlar orqali yodlaganingizni tekshiring',
            onTap: () => context.push('/vocabulary/sets', extra: VocabIntent.play),
          ),
        ],
      ),
    );
  }
}

/// SRS nudge: review the words that are due today (launches a solo review game).
class _ReviewHero extends ConsumerWidget {
  const _ReviewHero({required this.dueCount});
  final int dueCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A34A), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadow.glow(AppColors.brand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
              const SizedBox(width: AppSpace.sm),
              const Text(
                'Kunlik takrorlash',
                style: TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "$dueCount ta so'z takrorlashga tayyor — mustahkamlab oling.",
            style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: AppSpace.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brandDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: () => _startReview(context, ref),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Takrorlashni boshlash',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startReview(BuildContext context, WidgetRef ref) async {
    final items = ref.read(reviewDueProvider).valueOrNull ?? const [];
    if (items.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Takrorlash uchun so'z yetarli emas")),
      );
      return;
    }
    await context.push(
      '/vocabulary/game',
      extra: VocabGameLaunch(items: items, mode: GameMode.solo, title: 'Takrorlash'),
    );
    ref.invalidate(reviewDueProvider);
  }
}

/// A large, premium primary-action card with a gradient face.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadow.glow(colors.first),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70, fontSize: 12.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
