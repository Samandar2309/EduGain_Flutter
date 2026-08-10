import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';
import 'question_home.dart';
import 'worked_answer_card.dart';

/// The question set, reachable from inside a live call.
///
/// A sheet rather than a screen, because leaving the call to look something up
/// is not a thing anyone will do mid-conversation — they will sit in silence
/// instead, which is the problem this exists to solve.
///
/// It navigates inside itself (part → topics → questions) so the call stays
/// mounted underneath the whole time. Pass [partIndex] to land on that part's
/// topics — the caller already chose the part, so the tile grid is skipped and
/// the sequence picks up from the step after it.
Future<void> showQuestionsSheet(BuildContext context, {int? partIndex}) =>
    showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppColors.canvas,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
  ),
  builder: (_) => _QuestionsSheet(partIndex: partIndex),
);

class _QuestionsSheet extends ConsumerStatefulWidget {
  const _QuestionsSheet({this.partIndex});

  final int? partIndex;

  @override
  ConsumerState<_QuestionsSheet> createState() => _QuestionsSheetState();
}

class _QuestionsSheetState extends ConsumerState<_QuestionsSheet> {
  late int _part = widget.partIndex ?? 0;
  QuestionTopic? _open;
  bool _savedOnly = false;

  /// The four-tile home. Skipped entirely when the caller already named a
  /// part: showing the tiles again would ask a question already answered.
  late bool _home = widget.partIndex == null;

  void _back() => setState(() {
    if (_open != null) {
      _open = null;
    } else {
      _home = true;
      _savedOnly = false;
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bank = ref.watch(questionBankProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (context, scrollController) => bank.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpace.xxl),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.questionsError,
                    style: const TextStyle(color: AppColors.inkSoft)),
                const SizedBox(height: AppSpace.md),
                FilledButton(
                  onPressed: () => ref.invalidate(questionBankProvider),
                  child: Text(l.retry),
                ),
              ],
            ),
          ),
        ),
        data: (parts) => _body(context, l, parts, scrollController),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l,
    List<QuestionPart> parts,
    ScrollController scrollController,
  ) {
    final open = _open;
    return Column(
      children: [
        // Only shown with somewhere to go back to. On the browse view the
        // chips already say where you are, and repeating it costs a line of
        // the few a sheet has.
        if (open != null || _savedOnly || !_home)
          _Header(
            title: open?.title ??
                (_savedOnly
                    ? l.questionsSaved
                    : parts.isEmpty ? '' : parts[_part].title),
            onBack: _back,
          ),
        // Inside the browse path only. On the home view the four tiles ARE the
        // part switcher, and drawing both is the same control twice.
        if (!_home && open == null && !_savedOnly)
          _PartTabs(
            parts: parts,
            selected: _part,
            savedCount: ref.watch(bookmarksProvider).length,
            onPart: (i) => setState(() => _part = i),
            onSaved: () => setState(() => _savedOnly = true),
          ),
        Expanded(
          child: open != null
              ? _Questions(topic: open, controller: scrollController)
              : _savedOnly
                  ? _Saved(controller: scrollController)
                  : _home
                      ? QuestionHome(
                          parts: parts,
                          controller: scrollController,
                          savedCount: ref.watch(bookmarksProvider).length,
                          onSaved: () => setState(() {
                            _savedOnly = true;
                            _home = false;
                          }),
                          onPart: (i) => setState(() {
                            _part = i;
                            _home = false;
                          }),
                        )
                      : _Topics(
                          part: parts.isEmpty ? null : parts[_part],
                          controller: scrollController,
                          onOpen: (t) => setState(() => _open = t),
                        ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.lg, AppSpace.sm),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              color: AppColors.ink,
            )
          else
            const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartTabs extends StatelessWidget {
  const _PartTabs({
    required this.parts,
    required this.selected,
    required this.savedCount,
    required this.onPart,
    required this.onSaved,
  });

  final List<QuestionPart> parts;
  final int selected;
  final int savedCount;
  final ValueChanged<int> onPart;
  final VoidCallback onSaved;

  static const _accents = [
    AppColors.speaking,
    AppColors.grammar,
    AppColors.vocabulary,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < parts.length; i++) ...[
                    _Chip(
                      label: parts[i].title,
                      color: _accents[i % _accents.length],
                      selected: i == selected,
                      onTap: () => onPart(i),
                    ),
                    const SizedBox(width: AppSpace.sm),
                  ],
                ],
              ),
            ),
          ),
          // Pinned, not scrolled with the parts: a bookmark button caught
          // half-off the edge is the first thing that reads as broken.
          const SizedBox(width: AppSpace.xs),
          _SavedButton(count: savedCount, onTap: onSaved),
        ],
      ),
    );
  }
}

class _SavedButton extends StatelessWidget {
  const _SavedButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = count > 0;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).questionsSaved,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: has ? 12 : 11),
          decoration: BoxDecoration(
            color: has ? AppColors.brandTint : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: has ? AppColors.brand : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark,
                size: 18,
                color: has ? AppColors.brandDeep : AppColors.inkFaint,
              ),
              if (has) ...[
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDeep,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _Questions extends ConsumerWidget {
  const _Questions({required this.topic, required this.controller});

  final QuestionTopic topic;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = topic.cueCard;
    final saved = ref.watch(bookmarksProvider);

    // A cue card is ONE task, so it is rendered as one card. Split into rows
    // it reads as four interchangeable questions, and a learner who answers
    // them one by one gives four short replies instead of the single long
    // turn the exercise is for — the exact mistake it exists to prevent.
    if (card != null) {
      return ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        children: [
          _CueCardBody(
            card: card,
            isSaved: saved.contains(card.prompt),
            onSave: () {
              HapticFeedback.selectionClick();
              ref.read(bookmarksProvider.notifier).toggle(card.prompt);
            },
          ),
        ],
      );
    }

    // The breakdown rides above the questions, collapsed. It answers "how do
    // I do this at all?", which is the question someone has before they pick
    // one — but collapsed, so a learner who already knows scrolls past it in
    // one row rather than past an essay.
    final lead = topic.worked != null
        ? WorkedAnswerCard(worked: topic.worked!)
        : topic.hasWorked
            ? const WorkedAnswerLocked()
            : null;

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.xxl,
      ),
      itemCount: topic.questions.length + (lead == null ? 0 : 1),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, i) {
        if (lead != null && i == 0) return lead;
        final question = topic.questions[i - (lead == null ? 0 : 1)];
        return QuestionRow(
          text: question,
          isSaved: saved.contains(question),
          onSave: () {
            HapticFeedback.selectionClick();
            ref.read(bookmarksProvider.notifier).toggle(question);
          },
        );
      },
    );
  }
}

class _CueCardBody extends StatelessWidget {
  const _CueCardBody({
    required this.card,
    required this.isSaved,
    required this.onSave,
  });

  final CueCard card;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  card.prompt,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: onSave,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: Icon(
                  isSaved
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                  size: 20,
                  color: isSaved ? AppColors.brand : AppColors.inkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            l.cueCardYouShouldSay,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          for (final bullet in card.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 9, right: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.xs),
          // Set apart because it carries most of the marks and is the line
          // learners skip. Inside the bullet list it reads as an optional
          // fourth point.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              card.closing,
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.brandDeep,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            l.cueCardHint,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _Saved extends ConsumerWidget {
  const _Saved({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final saved = ref.watch(bookmarksProvider).toList();
    if (saved.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Text(
            l.questionsNoneSaved,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.xxl,
      ),
      itemCount: saved.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, i) => QuestionRow(
        text: saved[i],
        isSaved: true,
        onSave: () {
          HapticFeedback.selectionClick();
          ref.read(bookmarksProvider.notifier).toggle(saved[i]);
        },
      ),
    );
  }
}

/// One question, sized to be read at a glance while speaking.
class QuestionRow extends StatelessWidget {
  const QuestionRow({
    required this.text,
    required this.isSaved,
    required this.onSave,
    super.key,
  });

  final String text;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        // Centred, not top-aligned: on a one-line question a top-aligned
        // button leaves a pocket of empty space under the text and the row
        // stops matching its neighbours.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          IconButton(
            onPressed: onSave,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            // Material's 48dp minimum makes a one-line question sit in a
            // two-line card — the rows stop looking like a list and start
            // looking like a mistake. 36 is still a comfortable target.
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_outline,
              size: 20,
              color: isSaved ? AppColors.brand : AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}



/// A part's topics — the middle step of part → topics → questions.
///
/// The step is worth keeping. The topics are how the exam is organised and how
/// learners already think about it, and a part flattened into sixty questions
/// in one scroll is a wall nobody reads to the end of.
class _Topics extends StatelessWidget {
  const _Topics({
    required this.part,
    required this.controller,
    required this.onOpen,
  });

  final QuestionPart? part;
  final ScrollController controller;
  final void Function(QuestionTopic topic) onOpen;

  @override
  Widget build(BuildContext context) {
    final p = part;
    final l = AppLocalizations.of(context);
    if (p == null || p.topics.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xxl),
      itemCount: p.topics.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, i) {
        final topic = p.topics[i];
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onOpen(topic),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: AppColors.brandDeep,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(topic.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                        ),
                        if (topic.isNew) ...[
                          const SizedBox(width: AppSpace.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.brand,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(l.questionsNew,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        // A cue card is one task; promising "0 questions"
                        // would be both wrong and baffling.
                        topic.isCueCard
                            ? l.cueCardLabel
                            : l.questionsCount(topic.questionCount),
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.inkFaint),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.inkFaint, size: 20),
              ]),
            ),
          ),
        );
      },
    );
  }
}
