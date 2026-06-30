import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/providers.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/language_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/application/providers.dart';
import '../../gamification/domain/models.dart';
import '../../subscriptions/application/providers.dart';

// Product-name XP sources stay as-is; 'streak' / 'daily_goal' are localized in
// [_XpTile] (they have a translatable label).
const _xpSourceLabels = {
  'speaking': 'Speaking',
  'writing': 'Writing',
  'vocab': 'Vocabulary',
  'grammar': 'Grammar',
  'listening': 'Listening',
};

const _tierLabels = {'free': 'Free', 'entry': 'Entry', 'main': 'Main', 'pro': 'Pro'};

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final gamification = ref.watch(gamificationProfileProvider);
    final history = ref.watch(xpHistoryProvider);
    final subscription = ref.watch(mySubscriptionProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l.logout,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── identity ──────────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(
                  user.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.phone != null) Text(user.phone!),
                    if (user.cefrLevel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Chip(
                          label: Text(l.levelLabel(user.cefrLevel!)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => _editName(context, ref, user.fullName ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── gamification ──────────────────────────────────────────────
          gamification.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (g) => _GamificationCard(
              profile: g,
              onEditGoal: () => _editGoal(context, ref, g.dailyGoalTarget),
            ),
          ),
          const SizedBox(height: 16),

          // ── subscription ──────────────────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_rounded),
              title: Text(l.subscription),
              subtitle: Text(
                subscription.maybeWhen(
                  data: (s) => _tierLabels[s.tier] ?? s.tier,
                  orElse: () => '...',
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/subscriptions'),
            ),
          ),
          const SizedBox(height: 8),

          // ── language ──────────────────────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(l.languageTitle),
              subtitle: Text(
                (AppLanguage.fromCode(
                          ref.watch(localeProvider)?.languageCode,
                        ) ??
                        AppLanguage.uzbek)
                    .endonym,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showLanguagePicker(context),
            ),
          ),
          const SizedBox(height: 24),

          // ── XP history ────────────────────────────────────────────────
          Text(
            l.xpHistory,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          history.when(
            loading: () =>
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (_, _) => Text(l.xpHistoryError),
            data: (events) => events.isEmpty
                ? Text(l.noXpYet)
                : Column(children: events.map(_XpTile.new).toList()),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editNameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.nameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(fullName: name);
    } on ApiException catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  Future<void> _editGoal(BuildContext context, WidgetRef ref, int current) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: current.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.dailyGoalTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: l.dailyGoalHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (value == null || value < 10) return;
    try {
      await ref.read(gamificationRepositoryProvider).setDailyGoal(value);
      ref.invalidate(gamificationProfileProvider);
    } on ApiException catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }
}

class _GamificationCard extends StatelessWidget {
  const _GamificationCard({required this.profile, required this.onEditGoal});

  final GamificationProfile profile;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(icon: Icons.bolt_rounded, value: '${profile.xp}', label: l.statXp),
                _Stat(icon: Icons.military_tech_rounded, value: '${profile.level}', label: l.statLevel),
                _Stat(
                  icon: Icons.local_fire_department_rounded,
                  value: '${profile.streak}',
                  label: 'Streak',
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.dailyGoalLabel, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: profile.goalRatio,
                        borderRadius: BorderRadius.circular(8),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.dailyGoalProgress} / ${profile.dailyGoalTarget} XP',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: onEditGoal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _XpTile extends StatelessWidget {
  const _XpTile(this.event);

  final XpEvent event;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = switch (event.source) {
      'daily_goal' => l.xpSourceDailyGoal,
      'streak' => l.xpSourceStreak,
      _ => _xpSourceLabels[event.source] ?? event.source,
    };
    return ListTile(
      dense: true,
      leading: const Icon(Icons.bolt_rounded),
      title: Text(label),
      subtitle: Text(event.createdAt.split('T').first),
      trailing: Text(
        '+${event.amount}',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
      ),
    );
  }
}
