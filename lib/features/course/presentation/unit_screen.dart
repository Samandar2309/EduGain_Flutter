import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// One unit: the rule, then its lessons.
///
/// Built around a complaint. Learners said they could not tell what to do, and
/// the usual cause is a screen that offers several equal-looking things and
/// trusts you to pick. So there is exactly one filled button here, it is the
/// next lesson, and it says what will happen when it is pressed. Everything
/// else on the screen is quieter than it.
class UnitScreen extends ConsumerWidget {
  const UnitScreen({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final unit = ref.watch(unitDetailProvider(unitId));

    return Scaffold(
      backgroundColor: _U.canvas,
      appBar: AppBar(
        backgroundColor: _U.canvas,
        foregroundColor: _U.ink,
        elevation: 0,
        title: Text(
          unit.asData?.value.title ?? '',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: unit.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l.questionsError,
                  style: const TextStyle(color: _U.soft)),
              const SizedBox(height: AppSpace.md),
              FilledButton(
                onPressed: () => ref.invalidate(unitDetailProvider(unitId)),
                child: Text(l.retry),
              ),
            ]),
          ),
        ),
        data: (u) => _Body(unit: u, l: l),
      ),
    );
  }
}

abstract final class _U {
  // Mapped onto the app's own tokens rather than kept as a private dark
  // set. Three screens in this section each carried an identical copy of
  // that palette while the lesson and test-out screens next door already
  // used AppColors — so the course was the only place in the app that
  // went dark, and it was not even consistent with itself.
  static const canvas = AppColors.canvas;
  static const surface = AppColors.surface;
  static const line = AppColors.line;
  static const ink = AppColors.ink;
  static const soft = AppColors.inkSoft;
  static const faint = AppColors.inkFaint;
  static const brand = AppColors.brand;
  static const gold = AppColors.xp;
}

class _Body extends StatelessWidget {
  const _Body({required this.unit, required this.l});

  final UnitDetail unit;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final next = unit.lessons.firstWhere(
      (x) => x.state == LessonState.current,
      orElse: () => unit.lessons.isEmpty
          ? const LessonRef(
              id: '', index: 0, itemCount: 0, state: LessonState.locked)
          : unit.lessons.last,
    );
    final doneCount =
        unit.lessons.where((x) => x.state == LessonState.done).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
            children: [
              // What this unit teaches, said in one line before anything else.
              // "Unit 5" tells a learner nothing they can act on.
              _Teaches(unit: unit, l: l),
              const SizedBox(height: AppSpace.lg),
              if (unit.explanation.trim().isNotEmpty) ...[
                _Rule(text: unit.explanation, l: l),
                const SizedBox(height: AppSpace.lg),
              ],
              Row(children: [
                Text(
                  l.courseLessons.toUpperCase(),
                  style: const TextStyle(
                    color: _U.faint,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text('$doneCount / ${unit.lessons.length}',
                    style: const TextStyle(color: _U.faint, fontSize: 11.5)),
              ]),
              const SizedBox(height: AppSpace.sm),
              for (final lesson in unit.lessons) ...[
                _LessonRow(lesson: lesson, unitId: unit.id, l: l),
                const SizedBox(height: AppSpace.sm),
              ],
            ],
          ),
        ),
        // The one button. Pinned, so it is on screen whatever the rule's
        // length — a call to action you have to scroll to find is a call to
        // action for the people who were already going to find it.
        if (next.id.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _U.brand,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                onPressed: () =>
                    context.push('/course/lesson/${next.id}'),
                child: Text(
                  doneCount == 0
                      ? l.courseStartLesson
                      : l.courseContinueLesson(next.index + 1),
                  style: const TextStyle(
                    color: Color(0xFF06281C),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "This unit teaches X, using the words for Y."
class _Teaches extends StatelessWidget {
  const _Teaches({required this.unit, required this.l});

  final UnitDetail unit;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.lg),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        // Was a dark navy fading into the old dark surface. On the light
        // canvas it read as a hole punched through the top of the screen.
        colors: [AppColors.brandTint, _U.surface],
      ),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: _U.line),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.courseYouWillLearn,
          style: const TextStyle(
              color: _U.faint,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8)),
      const SizedBox(height: AppSpace.sm),
      _Line(icon: Icons.rule_rounded, text: unit.grammar, colour: _U.brand),
      const SizedBox(height: 6),
      _Line(
          icon: Icons.translate_rounded,
          text: unit.vocab,
          colour: const Color(0xFF60A5FA)),
      if (unit.mastery > 0) ...[
        const SizedBox(height: AppSpace.md),
        Row(children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Icon(
                i < unit.mastery ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 15,
                color: i < unit.mastery ? _U.gold : _U.line,
              ),
            ),
          const SizedBox(width: 6),
          // Flexible, because the same sentence in Russian is half again as
          // long as in Uzbek and five stars have already taken the room.
          Flexible(
            child: Text(l.courseMastery(unit.mastery, 5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _U.soft, fontSize: 11.5)),
          ),
        ]),
      ],
    ]),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, required this.colour});

  final IconData icon;
  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 17, color: colour),
    const SizedBox(width: AppSpace.sm),
    Expanded(
      child: Text(text,
          style: const TextStyle(
              color: _U.ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
    ),
  ]);
}

/// The rule, collapsed.
///
/// Open by default the first time and foldable after: somebody on their third
/// visit wants the lessons, and making them scroll past an explanation they
/// have read is how a screen starts feeling long.
class _Rule extends StatefulWidget {
  const _Rule({required this.text, required this.l});

  final String text;
  final AppLocalizations l;

  @override
  State<_Rule> createState() => _RuleState();
}

class _RuleState extends State<_Rule> {
  bool _open = true;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _U.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: _U.line),
    ),
    child: Column(children: [
      InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(children: [
            const Icon(Icons.menu_book_rounded, size: 17, color: _U.soft),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(widget.l.courseRule,
                  style: const TextStyle(
                      color: _U.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800)),
            ),
            Icon(_open ? Icons.expand_less : Icons.expand_more,
                color: _U.soft, size: 20),
          ]),
        ),
      ),
      if (_open)
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.md, 0, AppSpace.md, AppSpace.md),
          child: Align(
            alignment: Alignment.centerLeft,
            // The explanation is authored as light markdown. Rendered as plain
            // text with the asterisks stripped rather than with a markdown
            // engine: it is one paragraph and a few bold words, and a
            // dependency for that is a dependency to keep updated for ever.
            child: Text(
              widget.text.replaceAll('**', '').replaceAll('*', ''),
              style: const TextStyle(
                  color: _U.soft, fontSize: 13.5, height: 1.5),
            ),
          ),
        ),
    ]),
  );
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.unitId,
    required this.l,
  });

  final LessonRef lesson;
  final String unitId;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final done = lesson.state == LessonState.done;
    final current = lesson.state == LessonState.current;
    final open = done || current;

    return Opacity(
      opacity: open ? 1 : 0.5,
      child: Material(
        color: current ? _U.brand.withValues(alpha: 0.12) : _U.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open ? () => context.push('/course/lesson/${lesson.id}') : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: current ? _U.brand : _U.line),
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _U.brand : Colors.transparent,
                  border: Border.all(color: done ? _U.brand : _U.line),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Color(0xFF06281C))
                    : Text('${lesson.index + 1}',
                        style: const TextStyle(
                            color: _U.soft,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.courseLessonN(lesson.index + 1),
                        style: const TextStyle(
                            color: _U.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text(l.courseItemCount(lesson.itemCount),
                        style:
                            const TextStyle(color: _U.faint, fontSize: 11.5)),
                  ],
                ),
              ),
              Icon(
                open ? Icons.chevron_right : Icons.lock_rounded,
                color: _U.faint,
                size: open ? 20 : 15,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
