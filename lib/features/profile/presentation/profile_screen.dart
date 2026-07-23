import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/providers.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/language_picker.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/application/providers.dart';
import '../../gamification/domain/models.dart';
import '../../speaking/application/providers.dart' show learnerProfileProvider;
import '../../speaking/domain/models.dart' show AbilityTrend, LearnerProfile;
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

/// The learner's identity + Communication Profile + settings, in the
/// "Premium & Clean" language: a brand gradient hero with the identity and
/// gamification stats, the measured Communication Profile card (abilities with
/// trends, speaking pace, focus tags), the daily goal, then settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final gamification = ref.watch(gamificationProfileProvider);
    final history = ref.watch(xpHistoryProvider);
    final subscription = ref.watch(mySubscriptionProvider);
    final profile = ref.watch(learnerProfileProvider);
    final l = AppLocalizations.of(context);

    if (user == null) {
      return const Scaffold(body: AppLoader());
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gamificationProfileProvider);
          ref.invalidate(xpHistoryProvider);
          ref.invalidate(learnerProfileProvider);
          ref.invalidate(mySubscriptionProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(
              name: user.displayName,
              phone: user.phone,
              cefrLevel: user.cefrLevel,
              gamification: gamification.valueOrNull,
              onEditName: () => _editName(context, ref, user.fullName ?? ''),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Communication Profile ────────────────────────────────
                  SectionHeader(title: l.commProfileTitle),
                  profile.when(
                    loading: () => const AppCard(
                      child: SizedBox(
                        height: 72,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brand,
                            strokeWidth: 2.6,
                          ),
                        ),
                      ),
                    ),
                    error: (_, _) => _EmptyProfileCard(text: l.commProfileEmpty),
                    data: (p) => p.isEmpty
                        ? _EmptyProfileCard(text: l.commProfileEmpty)
                        : _CommunicationProfileCard(profile: p),
                  ),
                  const SizedBox(height: AppSpace.xxl),

                  // ── daily goal ──────────────────────────────────────────
                  gamification.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (g) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: l.dailyGoalLabel),
                        _DailyGoalCard(
                          profile: g,
                          onEdit: () =>
                              _editGoal(context, ref, g.dailyGoalTarget),
                        ),
                        const SizedBox(height: AppSpace.xxl),
                      ],
                    ),
                  ),

                  // ── settings ────────────────────────────────────────────
                  SectionHeader(title: l.settingsTitle),
                  _SettingsTile(
                    icon: Icons.workspace_premium_rounded,
                    color: AppColors.xp,
                    title: l.subscription,
                    value: subscription.maybeWhen(
                      data: (s) => _tierLabels[s.tier] ?? s.tier,
                      orElse: () => '…',
                    ),
                    onTap: () => context.push('/subscriptions'),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _SettingsTile(
                    icon: Icons.translate_rounded,
                    color: AppColors.grammar,
                    title: l.languageTitle,
                    value: (AppLanguage.fromCode(
                              ref.watch(localeProvider)?.languageCode,
                            ) ??
                            AppLanguage.uzbek)
                        .endonym,
                    onTap: () => showLanguagePicker(context),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    color: AppColors.danger,
                    title: l.logout,
                    onTap: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                  ),
                  const SizedBox(height: AppSpace.xxl),

                  // ── XP history ──────────────────────────────────────────
                  SectionHeader(title: l.xpHistory),
                  history.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => Text(
                      l.xpHistoryError,
                      style: const TextStyle(color: AppColors.inkSoft),
                    ),
                    data: (events) => events.isEmpty
                        ? Text(
                            l.noXpYet,
                            style: const TextStyle(color: AppColors.inkSoft),
                          )
                        : AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.lg,
                              vertical: AppSpace.sm,
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < events.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.line,
                                    ),
                                  _XpTile(events[i]),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

// ── hero ─────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero({
    required this.name,
    required this.phone,
    required this.cefrLevel,
    required this.gamification,
    required this.onEditName,
  });

  final String name;
  final String? phone;
  final String? cefrLevel;
  final GamificationProfile? gamification;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final g = gamification;
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Center(
                  child: Text(
                    name.characters.first.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (phone != null)
                      Text(
                        phone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    if (cefrLevel != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          l.levelLabel(cefrLevel!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: onEditName,
              ),
            ],
          ),
          if (g != null) ...[
            const SizedBox(height: AppSpace.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatPill(
                  icon: Icons.bolt_rounded,
                  value: '${g.xp}',
                  label: l.statXp,
                  color: AppColors.xp,
                  onLight: true,
                ),
                StatPill(
                  icon: Icons.military_tech_rounded,
                  value: '${g.level}',
                  label: l.statLevel,
                  color: Colors.white,
                  onLight: true,
                ),
                StatPill(
                  icon: Icons.local_fire_department_rounded,
                  value: '${g.streak}',
                  label: 'Streak',
                  color: AppColors.streak,
                  onLight: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Communication Profile ────────────────────────────────────────────────────
class _EmptyProfileCard extends StatelessWidget {
  const _EmptyProfileCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const IconChip(
            icon: Icons.record_voice_over_rounded,
            color: AppColors.speaking,
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunicationProfileCard extends StatelessWidget {
  const _CommunicationProfileCard({required this.profile});
  final LearnerProfile profile;

  static const _abilityOrder = ['grammar', 'vocabulary', 'overall'];

  String _abilityLabel(AppLocalizations l, String key) => switch (key) {
    'grammar' => l.scoreGrammar,
    'vocabulary' => l.scoreVocabulary,
    'overall' => l.scoreOverall,
    'fluency' => l.scoreFluency,
    'pronunciation' => l.scorePronunciation,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = profile;
    final abilities = [
      for (final key in _abilityOrder)
        if (p.abilities[key] != null) (key, p.abilities[key]!),
    ];
    final samples = abilities.isEmpty ? 0 : abilities.first.$2.samples;
    final wpm = p.wordsPerMinute;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ability trends — the smoothed report card.
          for (final (key, trend) in abilities) ...[
            _AbilityRow(label: _abilityLabel(l, key), trend: trend),
            const SizedBox(height: AppSpace.md),
          ],
          if (abilities.isNotEmpty && samples > 0) ...[
            Text(
              l.basedOnSessions(samples),
              style: const TextStyle(color: AppColors.inkFaint, fontSize: 11.5),
            ),
            const Divider(height: AppSpace.xxl, color: AppColors.line),
          ],

          // Measured fluency — only what was actually observed.
          if (wpm != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.speed_rounded,
                  size: 18,
                  color: AppColors.speaking,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.paceLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Text(
                  l.paceValue(wpm.round()),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.speaking,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l.paceTarget(p.wpmTarget),
                  style: const TextStyle(
                    color: AppColors.inkFaint,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: (wpm / p.wpmTarget).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: AppColors.canvasAlt,
                color: AppColors.speaking,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          Row(
            children: [
              if (p.voicedMinutes != null)
                Expanded(
                  child: _MiniStat(
                    icon: Icons.timer_outlined,
                    value: p.voicedMinutes!.toStringAsFixed(
                      p.voicedMinutes! >= 10 ? 0 : 1,
                    ),
                    label: l.minutesSpoken,
                  ),
                ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: '${p.spokenWords}',
                  label: l.wordsSpoken,
                ),
              ),
            ],
          ),

          // What the tutor is working on with the learner right now.
          if (p.focusTags.isNotEmpty) ...[
            const Divider(height: AppSpace.xxl, color: AppColors.line),
            Text(
              l.focusTagsTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final tag in p.focusTags.take(6))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      tag.replaceAll('_', ' '),
                      style: const TextStyle(
                        color: AppColors.brandDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AbilityRow extends StatelessWidget {
  const _AbilityRow({required this.label, required this.trend});

  final String label;
  final AbilityTrend trend;

  Color get _color => trend.current >= 75
      ? AppColors.success
      : trend.current >= 50
          ? AppColors.warning
          : AppColors.danger;

  @override
  Widget build(BuildContext context) {
    final delta = trend.delta;
    final showDelta = delta != null && delta.abs() >= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
            if (showDelta) ...[
              Icon(
                delta > 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 13,
                color: delta > 0 ? AppColors.success : AppColors.danger,
              ),
              Text(
                delta.abs().round().toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: delta > 0 ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${trend.current.round()}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: _color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: (trend.current / 100).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: AppColors.canvasAlt,
            color: _color,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.inkFaint),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.inkFaint, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

// ── daily goal ───────────────────────────────────────────────────────────────
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.profile, required this.onEdit});

  final GamificationProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ProgressRing(
            progress: profile.goalRatio,
            size: 56,
            stroke: 7,
            color: AppColors.brand,
            trackColor: AppColors.canvasAlt,
            center: Text(
              '${(profile.goalRatio * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text(
              '${profile.dailyGoalProgress} / ${profile.dailyGoalTarget} XP',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.inkSoft),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

// ── settings ─────────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      onTap: onTap,
      child: Row(
        children: [
          IconChip(icon: icon, color: color, size: 40, iconSize: 20),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.inkFaint,
            size: 22,
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.xp, size: 20),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  event.createdAt.split('T').first,
                  style: const TextStyle(
                    color: AppColors.inkFaint,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${event.amount}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.success,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
