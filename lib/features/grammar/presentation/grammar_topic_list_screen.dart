import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// The grammar library: topics as premium cards with the CEFR level as the
/// visual anchor (sky accent) and locked topics clearly marked.
class GrammarTopicListScreen extends ConsumerWidget {
  const GrammarTopicListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final topics = ref.watch(grammarTopicsProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Grammar'),
        backgroundColor: AppColors.canvas,
      ),
      body: topics.when(
        loading: () => const AppLoader(),
        error: (_, _) => Center(child: Text(l.loadFailed)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noTopics))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.sm,
                  AppSpace.lg,
                  AppSpace.xxl,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.md),
                  child: _TopicCard(topic: list[i]),
                ),
              ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});
  final GrammarTopic topic;

  @override
  Widget build(BuildContext context) {
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
            if (topic.isLocked) {
              showApiError(
                context,
                const ApiException(code: 'PAYWALL', message: '', statusCode: 402),
              );
            } else {
              _openTopicSheet(context, topic);
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
                    gradient: AppGradients.accent(AppColors.grammar),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadow.glow(AppColors.grammar),
                  ),
                  child: Center(
                    child: Text(
                      topic.cefrLevel,
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
                        topic.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15.5, color: AppColors.ink),
                      ),
                      const SizedBox(height: 3),
                      const Row(
                        children: [
                          Icon(Icons.school_rounded, size: 13, color: AppColors.grammar),
                          SizedBox(width: 4),
                          Text('Qoida + mashq',
                              style: TextStyle(
                                color: AppColors.inkSoft, fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                if (topic.isLocked)
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
                      gradient: AppGradients.accent(AppColors.grammar),
                      shape: BoxShape.circle,
                      boxShadow: AppShadow.glow(AppColors.grammar),
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

/// Learn the rule, or jump straight to practice — the one decision per topic.
Future<void> _openTopicSheet(BuildContext context, GrammarTopic topic) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg,
          AppSpace.lg + MediaQuery.of(ctx).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(topic.title,
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: AppSpace.lg),
            _TopicMode(
              icon: Icons.menu_book_rounded,
              color: AppColors.grammar,
              title: "Qoidani o'rganish",
              subtitle: 'Qoida, misollar va naqsh',
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/grammar/learn', extra: topic);
              },
            ),
            const SizedBox(height: AppSpace.md),
            _TopicMode(
              icon: Icons.sports_esports_rounded,
              color: AppColors.speaking,
              title: 'Mashq qilish',
              subtitle: "Bo'shliqni to'ldirish + gap tuzish o'yinlari",
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/grammar/practice', extra: topic);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _TopicMode extends StatelessWidget {
  const _TopicMode({
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
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
                    Text(title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
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
