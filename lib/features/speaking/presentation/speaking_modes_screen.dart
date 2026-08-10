import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';
import 'lesson_launch.dart';
import 'level_invite.dart';

/// The Speaking hub: the ways to practise, grouped by who the learner talks to.
///
/// Tiles carry a tinted wash behind a coloured glyph rather than a saturated
/// gradient behind a white one. Six saturated squares on one screen compete for
/// attention and none of them wins; the same hue at low opacity says the same
/// thing quietly, and lets colour mean something — indigo for the AI, warm for
/// people, green for preparation.
class SpeakingModesScreen extends ConsumerStatefulWidget {
  const SpeakingModesScreen({super.key});

  @override
  ConsumerState<SpeakingModesScreen> createState() =>
      _SpeakingModesScreenState();
}

class _SpeakingModesScreenState extends ConsumerState<SpeakingModesScreen> {
  bool _starting = false;

  /// Open the conversation with nothing decided. The tutor asks what they feel
  /// like talking about, rather than handing over a prescribed topic.
  Future<void> _startFree() async {
    await launchLesson(
      context,
      ref,
      backdropKey: 'default',
      title: AppLocalizations.of(context).speakingFreeTitle,
      onBusy: (b) {
        if (mounted) setState(() => _starting = b);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // A learner with no measured level is taught at a guessed A2. Ask before
    // the first conversation rather than after a hundred of them.
    final invite = shouldInviteToLevelTest(
      cefrLevel: ref.watch(authControllerProvider).user?.cefrLevel,
      skipped: ref.watch(levelInviteSkippedProvider),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Speaking'),
        backgroundColor: AppColors.canvas,
        actions: [
          if (!invite)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: l.speakingHistoryTitle,
              onPressed: () => context.push('/speaking/history'),
            ),
        ],
      ),
      body: invite
          ? const LevelInvite()
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xxxl,
                  ),
                  children: [
                    _Section(l.speakingSectionAi),
                    // IntrinsicHeight so the pair matches.
                    //
                    // A Row sizes each child to its own content, so the card
                    // with a tag was taller and the other one hung short beside
                    // it — which reads as one being unfinished rather than as
                    // two choices of equal standing.
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _ModeCard(
                              icon: Icons.mic,
                              colour: _Tint.indigo,
                              title: l.speakingFreeTitle,
                              subtitle: l.speakingFreeSubtitle,
                              tag: l.speakingRecommended,
                              onTap: _startFree,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: _ModeCard(
                              icon: Icons.menu_book,
                              colour: _Tint.sky,
                              title: l.speakingTopicsTitle,
                              subtitle: l.speakingTopicsSubtitle,
                              // Its own tag, and not only for symmetry: what a
                              // learner wants to know about this card is which
                              // exams and frameworks it covers.
                              tag: l.speakingTopicsTag,
                              onTap: () => context.push('/speaking/ai'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Group and 1:1 used to sit here too. They are on the
                    // home screen, one tap from launch, and repeating them here
                    // meant the same two rooms had two front doors — so this
                    // screen is now only what it is for: practising with the AI.
                    // Routes `/speaking/group` and `/peer` are untouched.
                    _Section(l.speakingSectionPrepare),
                    _ModeCard(
                      icon: Icons.help_outline,
                      colour: _Tint.green,
                      title: l.questionsTitle,
                      subtitle: l.questionsModeSubtitle,
                      wide: true,
                      onTap: () => context.push('/questions'),
                    ),
                    const _RecentSessions(),
                  ],
                ),
                if (_starting)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}

/// A tile's two colours: a wash to sit on, and the glyph's own.
class _Tint {
  const _Tint(this.bg, this.fg);
  final Color bg;
  final Color fg;

  static const indigo = _Tint(Color(0xFFEEF0FF), Color(0xFF4F46E5));
  static const sky = _Tint(Color(0xFFE5F4FE), Color(0xFF0369A1));
  static const green = _Tint(Color(0xFFE6F9F1), Color(0xFF047857));
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, AppSpace.lg, 2, AppSpace.sm),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
        color: AppColors.inkFaint,
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
    this.tag,
    this.wide = false,
  });

  final IconData icon;
  final _Tint colour;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? tag;
  final bool wide;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        // Shadow alone, no drawn border. The two together read as an outline
        // someone drew; a shadow on its own reads as a sheet of paper.
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x240F172A),
            blurRadius: 16,
            spreadRadius: -8,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colour.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colour.fg, size: 22),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.inkFaint,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: AppColors.inkSoft,
            ),
          ),
          if (tag != null) ...[
            // Pushes the tag to the foot of the card so the two line up.
            // `wide` cards are alone in their row and must not stretch.
            if (!wide) const Spacer() else const SizedBox(height: 9),
            if (!wide) const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colour.bg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                tag!.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: colour.fg,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// The learner's last few conversations.
///
/// No duration shown: the session payload does not carry one, and inventing a
/// number that looks measured is worse than leaving it out. What it does carry
/// is the subject, which is the part someone scans for when they want to pick
/// up where they left off.
class _RecentSessions extends ConsumerWidget {
  const _RecentSessions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sessions = ref.watch(speakingHistoryProvider).valueOrNull;
    if (sessions == null || sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, AppSpace.lg, 2, AppSpace.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.speakingHistoryTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: AppColors.inkFaint,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/speaking/history'),
                child: Text(
                  l.seeAll,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x240F172A),
                blurRadius: 16,
                spreadRadius: -8,
                offset: Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final s in sessions.take(3)) _RecentRow(session: s),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.session});

  final SpeakingSession session;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final free = (session.freeTopic ?? '').trim();
    final lesson = (session.lessonKey ?? '').trim();
    final isFree = lesson.isEmpty;
    final tint = isFree ? _Tint.indigo : _Tint.sky;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFree ? Icons.mic : Icons.menu_book,
              color: tint.fg,
              size: 17,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree ? l.speakingFreeTitle : l.speakingTopicsTitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (free.isNotEmpty || lesson.isNotEmpty)
                  Text(
                    free.isNotEmpty ? free : lesson,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.inkFaint,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 17,
            color: AppColors.inkFaint,
          ),
        ],
      ),
    );
  }
}
