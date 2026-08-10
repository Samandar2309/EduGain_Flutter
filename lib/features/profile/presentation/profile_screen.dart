import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/locale_controller.dart';
import '../../../core/providers.dart';
import '../../../core/share.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/language_picker.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/user_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/application/providers.dart';
import '../../gamification/domain/models.dart';
import '../../speaking/application/providers.dart'
    show aiUnlockedProvider, learnerProfileProvider;
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

/// How an XP source reads to a learner.
///
/// `course` — the source the whole course path awards under — was missing here
/// and every finished lesson showed up in the history as the bare word
/// "course". A lookup cannot fail loudly: an unknown key prints itself and
/// looks almost plausible, so the coverage is pinned by a test instead.
String xpSourceLabel(AppLocalizations l, String source) => switch (source) {
  'daily_goal' => l.xpSourceDailyGoal,
  'streak' => l.xpSourceStreak,
  'course' => l.xpSourceCourse,
  _ => _xpSourceLabels[source] ?? source,
};

/// Who built this, reachable in one tap.
///
/// It is the support channel for anything the in-app report form cannot carry
/// — somebody locked out of their account cannot file a report from inside the
/// app — and it is the credit line.
const _developerHandle = '@jumabayev_samandar';

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
    final aiUnlocked = ref.watch(aiUnlockedProvider);
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
              avatarUrl: user.avatarUrl,
              gamification: gamification.valueOrNull,
              onEditName: () => _editName(context, ref, user.fullName ?? ''),
              onEditPhoto: () => _changePhoto(context, ref),
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
                  //
                  // Hidden entirely while the AI tutor is locked, rather than
                  // blurred like the two cards that offer it. There is nothing
                  // behind this one to look forward to: every number in it —
                  // the ability scores, the speaking rate, the minutes and
                  // words — is measured from AI conversations. With those
                  // closed it would show zeroes under a confident heading, and
                  // zeroes read as broken, not as coming.
                  if (aiUnlocked) ...[
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
                      error: (_, _) =>
                          _EmptyProfileCard(text: l.commProfileEmpty),
                      data: (p) => p.isEmpty
                          ? _EmptyProfileCard(text: l.commProfileEmpty)
                          : CommunicationProfileCard(profile: p),
                    ),
                    const SizedBox(height: AppSpace.xxl),
                  ],

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
                    icon: Icons.military_tech_rounded,
                    color: AppColors.xp,
                    title: l.subscription,
                    value: subscription.maybeWhen(
                      data: (s) => _tierLabels[s.tier] ?? s.tier,
                      orElse: () => '…',
                    ),
                    onTap: () => context.push('/subscriptions'),
                  ),
                  if (user.phone != null) ...[
                    const SizedBox(height: AppSpace.md),
                    _SettingsTile(
                      icon: Icons.person_rounded,
                      color: AppColors.inkSoft,
                      title: l.accountTitle,
                      // No phone number here any more. It was the row's whole
                      // content, which made a settings entry out of one field —
                      // and the one field somebody actually needs to change,
                      // their gender, had nowhere to live at all.
                      onTap: () => context.push('/account'),
                    ),
                  ],
                  const SizedBox(height: AppSpace.md),
                  _SettingsTile(
                    // A headset, not a paper plane: the row is help, and the
                    // handle beside it already says the help arrives by
                    // Telegram.
                    icon: Icons.support_agent_rounded,
                    color: AppColors.speaking,
                    title: l.developerTitle,
                    value: _developerHandle,
                    onTap: () => _openDeveloper(context),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _SettingsTile(
                    icon: Icons.translate_rounded,
                    color: AppColors.grammar,
                    title: l.languageTitle,
                    value: (AppLanguage.fromCode(
                              ref.watch(localeProvider).locale?.languageCode,
                            ) ??
                            AppLanguage.uzbek)
                        .endonym,
                    onTap: () => showLanguagePicker(context),
                  ),
                  const SizedBox(height: AppSpace.md),
                  // Above logout on purpose: the last thing on this list
                  // should not be the way out of the app.
                  _SettingsTile(
                    icon: Icons.feedback,
                    color: AppColors.brand,
                    title: l.feedbackSendTitle,
                    onTap: () => context.push('/feedback'),
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

  /// Open the developer's Telegram, or leave the handle on the clipboard.
  ///
  /// Never nothing: a row that shows a handle and does not respond to a tap
  /// reads as broken, and somebody tapping it usually has a problem already.
  Future<void> _openDeveloper(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (await openTelegramProfile(_developerHandle)) return;
    await Clipboard.setData(const ClipboardData(text: _developerHandle));
    messenger.showSnackBar(SnackBar(content: Text(l.developerCopied)));
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
class _Hero extends ConsumerWidget {
  const _Hero({
    required this.name,
    required this.phone,
    required this.cefrLevel,
    required this.gamification,
    required this.onEditName,
    this.avatarUrl,
    this.onEditPhoto,
  });

  final String name;
  final String? phone;
  final String? cefrLevel;
  final GamificationProfile? gamification;
  final VoidCallback onEditName;

  /// The learner's Telegram picture, captured at sign-in.
  final String? avatarUrl;

  /// Tapping the picture to change it.
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final g = gamification;
    final tier =
        ref.watch(mySubscriptionProvider).asData?.value.tier ?? 'free';
    final photo = UserPhoto.resolve(avatarUrl) ?? '';
    return GradientHeader(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.xl,
      ),
      child: Column(
        children: [
          // Editing lives in the corner, not beside the name. A pencil next to
          // somebody's own name reads as "this is wrong"; in the corner it
          // reads as "this is yours".
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              onPressed: onEditName,
              visualDensity: VisualDensity.compact,
              tooltip: l.editNameTitle,
            ),
          ),
          _EditablePhoto(
            onTap: onEditPhoto,
            child: _RingedPhoto(name: name, url: photo, theme: theme),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cefrLevel != null) ...[
                _GlassChip(text: l.levelLabel(cefrLevel!)),
                const SizedBox(width: AppSpace.sm),
              ],
              _TierChip(tier: tier),
            ],
          ),
          if (g != null) ...[
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.bolt_rounded,
                    tint: AppColors.xp,
                    value: "${g.xp}",
                    label: l.statXp,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _StatTile(
                    icon: Icons.workspace_premium_rounded,
                    tint: Colors.white,
                    value: "${g.level}",
                    label: l.statLevel,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_fire_department_rounded,
                    tint: AppColors.streak,
                    value: "${g.streak}",
                    label: l.statStreak,
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

/// The picture inside a sweep-gradient ring.
///
/// The reference for this was Instagram's ring, and the treatment is what was
/// worth taking — not the palette. Borrowing its purple-to-orange would have
/// put a competitor's colours at the top of our own profile, so the sweep runs
/// through our accents: emerald, sky, indigo, rose, amber, back to emerald.
class _RingedPhoto extends StatelessWidget {
  const _RingedPhoto({
    required this.name,
    required this.url,
    required this.theme,
  });

  final String name;
  final String url;
  final ThemeData theme;

  static const _sweep = SweepGradient(
    colors: [
      AppColors.brand,
      AppColors.grammar,
      AppColors.speaking,
      AppColors.placement,
      AppColors.vocabulary,
      AppColors.brand,
    ],
  );

  @override
  Widget build(BuildContext context) => Container(
        width: 104,
        height: 104,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _sweep),
        padding: const EdgeInsets.all(3),
        child: Container(
          // A white gap between ring and photo, or the two merge into one thick
          // coloured edge and the ring stops reading as a ring.
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: url.isEmpty
                ? _Initial(name: name, theme: theme)
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Initial(name: name, theme: theme),
                    loadingBuilder: (_, child, p) =>
                        p == null ? child : _Initial(name: name, theme: theme),
                  ),
          ),
        ),
      );
}

/// A frosted chip on the gradient.
class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

/// One number, in its own frosted tile.
///
/// Drawn icons, not emoji. An emoji is somebody else's artwork at somebody
/// else's weight, and three of them in a row is the clearest sign that a screen
/// was assembled rather than designed.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color tint;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: tint),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}


class _Initial extends StatelessWidget {
  const _Initial({required this.name, required this.theme});

  final String name;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    // By code point, not `substring(0, 1)`: names come from Telegram and a
    // leading emoji or Cyrillic letter is a surrogate pair that slicing cuts
    // in half into an unrenderable box.
    final letter = t.isEmpty
        ? '?'
        : String.fromCharCode(t.runes.first).toUpperCase();
    return Center(
      child: Text(
        letter,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = switch (tier) {
      'entry' => 'Entry',
      'main' => 'Main',
      'pro' => 'Pro',
      _ => l.tierFree,
    };
    // Three levels of loudness, because the chip used to have one.
    //
    // Every tier drew the same translucent white pill, so a free account's
    // badge was indistinguishable from a Pro one — and on the emerald gradient
    // behind it, all of them were barely there at all. Gold is reserved for the
    // top tier and is the SAME gold as the leaderboard's first place, so the
    // colour means one thing across the app rather than being decoration here
    // and a medal there.
    final pro = tier == 'pro';
    final paid = tier == 'main' || tier == 'entry';
    return GestureDetector(
      onTap: () => context.push('/subscriptions'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: pro
              ? const LinearGradient(
                  colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: pro
              ? null
              : Colors.white.withValues(alpha: paid ? 0.92 : 0.18),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: pro || paid
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: pro
              ? [
                  BoxShadow(
                    color: const Color(0xFFB45309).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // No sparkle on the free chip: a "premium" flourish beside the word
            // Free is the app congratulating somebody for not paying.
            if (pro || paid) ...[
              Icon(
                pro ? Icons.workspace_premium_rounded : Icons.check_rounded,
                size: 12,
                // Dark on gold. White on this amber fails contrast outright,
                // and a badge nobody can read is the problem being fixed.
                color: pro ? const Color(0xFF78350F) : AppColors.brandDeep,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: pro
                    ? const Color(0xFF78350F)
                    : paid
                        ? AppColors.brandDeep
                        : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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

/// The learner's communication profile: where they are, which way it is
/// moving, and what the tutor is watching for next.
class CommunicationProfileCard extends StatelessWidget {
  const CommunicationProfileCard({super.key, required this.profile});
  final LearnerProfile profile;

  static const _abilityOrder = ['grammar', 'vocabulary'];

  /// A coaching tag as a learner would say it.
  ///
  /// These used to be printed as `tag.replaceAll('_', ' ')` — the backend's
  /// internal enum, verbatim, in English, inside a fully translated app. So an
  /// Uzbek learner read "word choice" and "verb tense" among their own results.
  /// Unknown tags fall back to the old behaviour rather than vanishing: a new
  /// tag on the server should look untranslated, not invisible.
  static String? tagLabel(AppLocalizations l, String tag) => switch (tag) {
    'verb_tense' => l.tagVerbTense,
    'word_choice' => l.tagWordChoice,
    'word_order' => l.tagWordOrder,
    'articles' || 'article' => l.tagArticles,
    'preposition' || 'prepositions' => l.tagPreposition,
    'plural' || 'plurals' => l.tagPlural,
    'agreement' || 'subject_verb_agreement' => l.tagAgreement,
    'pronoun' || 'pronouns' => l.tagPronoun,
    'comparative' || 'comparatives' => l.tagComparative,
    'conditional' || 'conditionals' => l.tagConditional,
    'question_form' || 'question_forms' => l.tagQuestionForm,
    'collocation' || 'collocations' => l.tagCollocation,
    // Never shown: it is the taxonomy's catch-all, not something to practise.
    'other' => null,
    _ => tag.replaceAll('_', ' '),
  };

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
          // What these numbers are, before any of them appear. Without this the
          // card opened on "55" with no unit, no scale and no sense of whether
          // 55 was something to be pleased about.
          Text(
            l.commProfileIntro,
            style: const TextStyle(
              color: AppColors.inkFaint,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpace.lg),

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
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.paceExplain,
              style: const TextStyle(
                color: AppColors.inkFaint,
                fontSize: 11.5,
                height: 1.35,
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
            const SizedBox(height: 2),
            Text(
              l.focusTagsHint,
              style: const TextStyle(color: AppColors.inkFaint, fontSize: 11.5),
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final tag in p.focusTags
                    .map((t) => tagLabel(l, t))
                    .whereType<String>()
                    .take(5))
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
                      tag,
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

  /// The colour must agree with [_band]'s word, or the row contradicts itself:
  /// the first draft printed "getting there" in the same red it used for a
  /// failure, and a learner believes the colour.
  ///
  /// Nothing here is red. The lowest band is a stage, not an error — someone
  /// two conversations into learning a language has done nothing wrong, and
  /// alarm-colouring their first score is how you make them the last.
  ///
  /// Slate, not the brand colour: `brandDeep` is emerald-700, so the lowest
  /// score came out GREENER than the middle one and the scale stopped reading
  /// in one direction. Grey → amber → emerald does.
  Color get _color => trend.current >= 60
      ? AppColors.success
      : trend.current >= 40
          ? AppColors.warning
          : AppColors.inkSoft;

  /// The score as a word.
  ///
  /// A bare "55" answers nothing a learner is actually asking: out of what, and
  /// is that good? The bands were already encoded in the bar's colour — this
  /// just says out loud what the colour was already claiming. Deliberately
  /// never negative at the bottom: "just starting" is a stage, "bad" is a
  /// verdict, and one of those makes people close the app.
  String _band(AppLocalizations l) => trend.current >= 75
      ? l.bandStrong
      : trend.current >= 60
          ? l.bandGood
          : trend.current >= 40
              ? l.bandMiddle
              : l.bandStarting;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final delta = trend.delta;
    // A direction, not a difference. The server now measures the later half of
    // the window against the earlier half, so anything under a few points is
    // the same reading twice — calling that "down 3" would be inventing news.
    final movement = delta == null
        ? null
        : delta >= 3
            ? (l.trendUp, AppColors.success, Icons.trending_up_rounded)
            : delta <= -3
                ? (l.trendDown, AppColors.warning, Icons.trending_down_rounded)
                : (l.trendSteady, AppColors.inkFaint, Icons.trending_flat_rounded);
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
            if (movement != null) ...[
              Icon(movement.$3, size: 14, color: movement.$2),
              const SizedBox(width: 3),
              Text(
                movement.$1,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: movement.$2,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              _band(l),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _color,
              ),
            ),
            const SizedBox(width: 6),
            // The scale, on every row. It is two characters and it removes the
            // single most common question this card produced.
            Text(
              '${trend.current.round()}/100',
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
    this.onTap,
    this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? value;

  /// Null for a row that only reports something (the signed-in account). A
  /// card that lifts under the thumb and then does nothing is worse than one
  /// that never suggested it would.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.md,
      ),
      onTap: onTap,
      child: Row(
        children: [
          // The same gradient tile the modules and lesson cards use, so the
          // settings list stops looking like a different app's screen.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // Tinted, not saturated — see the note on the lessons tiles.
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            // Coloured glyph, not white: white was correct on a saturated tile
            // and would have been invisible on this pale one.
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (value != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.canvasAlt,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                value!,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          // Only where there is somewhere to go. The chevron is a promise, and
          // the account row — which reports the signed-in number and nothing
          // else — was making one it could not keep.
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.inkFaint,
              size: 22,
            ),
          ],
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
    final label = xpSourceLabel(l, event.source);
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

/// Choosing a new profile picture.
///
/// Three ways out, because two of them are how phones actually work and the
/// third is the way back. Nothing here can leave a learner without a picture:
/// removing their own falls back to the Telegram one, so the worst case is the
/// face they started with.
Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(authRepositoryProvider);

  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpace.md),
          Text(l.profilePhotoTitle,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          const SizedBox(height: AppSpace.sm),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded,
                color: AppColors.brand),
            title: Text(l.profilePhotoPick),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_camera_rounded, color: AppColors.brand),
            title: Text(l.profilePhotoCamera),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded,
                color: AppColors.inkSoft),
            title: Text(l.profilePhotoReset),
            onTap: () => Navigator.pop(ctx, 'reset'),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
      ),
    ),
  );
  if (choice == null) return;

  try {
    if (choice == 'reset') {
      await repo.resetAvatar();
    } else {
      final picked = await ImagePicker().pickImage(
        source:
            choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        // Asked for at the size it is drawn plus room to spare. Nothing on the
        // server resizes, so this is where a four-megapixel photo is prevented
        // from becoming everybody else's download.
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await repo.uploadAvatar(bytes, picked.name);
    }
    // The header reads the user from auth, so it has to be refetched before
    // the new picture appears.
    await ref.read(authControllerProvider.notifier).refreshUser();
    messenger.showSnackBar(SnackBar(content: Text(l.profilePhotoSaved)));
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(
        e.code == 'photo_too_large' ? l.profilePhotoTooLarge : e.message,
      ),
    ));
  } on Object catch (e) {
    // The real reason, not "check your connection".
    //
    // A generic message here hid a permission error for an hour earlier today
    // and would have hidden this one too. Whatever went wrong, the person
    // holding the phone is the only one who can see it, so they get to read it.
    messenger.showSnackBar(
      SnackBar(
        content: Text('$e', maxLines: 4),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}

/// The picture, made obviously tappable.
///
/// A camera badge rather than a caption. Learners told us they could not tell
/// what was interactive, and a small mark in the corner of a photo is the one
/// convention everybody already knows from every other app on their phone.
class _EditablePhoto extends StatelessWidget {
  const _EditablePhoto({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    if (tap == null) return child;
    return GestureDetector(
      onTap: tap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brand, width: 2),
              ),
              child: const Icon(Icons.photo_camera_rounded,
                  size: 13, color: AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }
}
