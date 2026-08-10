import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// The first thing you see when you reach for a question mid-call.
///
/// The parts used to be a row of chips above a list of topics, which is three
/// taps and a decision before anybody says anything — and someone who opened
/// this because the conversation stalled has neither the patience nor the
/// attention for a menu. So the parts are targets you can hit without looking,
/// and Draw hands you something to say in one tap.
class QuestionHome extends ConsumerStatefulWidget {
  const QuestionHome({
    super.key,
    required this.parts,
    required this.onPart,
    required this.onSaved,
    required this.savedCount,
    this.controller,
    this.embedded = false,
    this.onDark = false,
  });

  final List<QuestionPart> parts;

  /// Open a part's topics — the browse path, unchanged.
  final void Function(int index) onPart;

  /// The bookmark list. Kept reachable from here because the tiles took the
  /// place of the tab row it used to live in.
  final VoidCallback onSaved;
  final int savedCount;
  final ScrollController? controller;

  /// Laid out inside somebody else's scroll view. Two nested scrollables fight
  /// each other for a drag and neither one wins convincingly.
  final bool embedded;

  /// On the call screen, where the background is near-black. The sheet is a
  /// light surface, so the same widget has to work on both grounds.
  final bool onDark;

  @override
  ConsumerState<QuestionHome> createState() => _QuestionHomeState();
}

class _QuestionHomeState extends ConsumerState<QuestionHome> {
  DrawnQuestion? _drawn;
  bool _wrapped = false;

  /// The accent per part. Distinct enough to aim at from the corner of an eye,
  /// which is the whole point of them being tiles.
  static const _accents = [
    AppColors.brand,
    AppColors.grammar,
    AppColors.streak,
  ];

  void _draw() {
    var wrapped = false;
    final picked = ref
        .read(seenQuestionsProvider.notifier)
        .draw(widget.parts, onWrap: () => wrapped = true);
    if (picked == null) return;
    setState(() {
      _drawn = picked;
      _wrapped = wrapped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final children = <Widget>[
        _Stage(drawn: _drawn, wrapped: _wrapped, l: l),
        const SizedBox(height: AppSpace.lg),
        // A fixed 2x2 rather than a scrolling grid: four targets that never
        // move are four targets you learn the position of.
        Row(children: [
          Expanded(child: _partTile(0)),
          const SizedBox(width: AppSpace.md),
          Expanded(child: _partTile(1)),
        ]),
        const SizedBox(height: AppSpace.md),
        Row(children: [
          Expanded(child: _partTile(2)),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _DrawTile(
              label: l.questionsDraw,
              onTap: widget.parts.isEmpty ? null : _draw,
            ),
          ),
        ]),
        if (widget.savedCount > 0) ...[
          const SizedBox(height: AppSpace.md),
          Center(
            child: TextButton.icon(
              onPressed: widget.onSaved,
              icon: const Icon(Icons.bookmark_outline,
                  size: 16, color: AppColors.inkSoft),
              label: Text('${l.questionsSaved} · ${widget.savedCount}',
                  style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
    ];

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xxl),
      children: children,
    );
  }

  Widget _partTile(int index) {
    if (index >= widget.parts.length) {
      // Fewer parts than tiles: an empty box holds the grid's shape rather
      // than letting the Draw tile slide under Part 1.
      return const SizedBox(height: 116);
    }
    final part = widget.parts[index];
    return _PartTile(
      number: '${index + 1}',
      title: part.title,
      accent: _accents[index % _accents.length],
      onDark: widget.onDark,
      onTap: () => widget.onPart(index),
    );
  }
}

/// Where a drawn question lands.
///
/// Above the tiles and always present, empty or not. A panel that appears only
/// once you have pressed something makes the grid jump under your thumb at the
/// exact moment you are looking at it.
class _Stage extends StatelessWidget {
  const _Stage({required this.drawn, required this.wrapped, required this.l});

  final DrawnQuestion? drawn;
  final bool wrapped;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final q = drawn;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2438), AppColors.inkDark],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.lineDark),
        ),
        child: q == null
            ? Row(children: [
                const Icon(Icons.auto_awesome_outlined,
                    color: AppColors.inkFaint, size: 20),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(l.questionsDrawHint,
                      style: const TextStyle(
                          color: AppColors.inkFaint,
                          fontSize: 13,
                          height: 1.4)),
                ),
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(q.partTitle,
                          style: const TextStyle(
                              color: AppColors.brand,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ),
                    if (wrapped) ...[
                      const SizedBox(width: AppSpace.sm),
                      // Said once, when it happens: a learner who has answered
                      // every question deserves to know why one is repeating
                      // rather than to think the app lost track.
                      Expanded(
                        child: Text(l.questionsAllSeen,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.inkFaint, fontSize: 10.5)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: AppSpace.md),
                  SelectableText(
                    q.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// One part, as a target rather than a menu entry.
class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.number,
    required this.title,
    required this.accent,
    required this.onDark,
    required this.onTap,
  });

  final String number;
  final String title;
  final Color accent;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: onDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 116,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: onDark ? AppColors.lineDark : AppColors.line),
            ),
            child: Row(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.mic_rounded, color: accent, size: 26),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: onDark ? Colors.white70 : AppColors.inkSoft,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            height: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
              // The numeral band, carried over from the reference — it is what
              // makes the four tiles readable at a glance — but as a tint of
              // the accent rather than a slab of pure colour.
              Container(
                width: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent, Color.lerp(accent, Colors.black, 0.22)!],
                  ),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// The fourth tile: one tap, one question.
class _DrawTile extends StatelessWidget {
  const _DrawTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        color: AppColors.speaking,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 116,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF818CF8), AppColors.speaking],
              ),
            ),
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.casino_outlined, color: Colors.white, size: 28),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.2),
                ),
              ],
            ),
          ),
        ),
      );
}
