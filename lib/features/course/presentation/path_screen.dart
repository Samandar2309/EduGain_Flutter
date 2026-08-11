import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// The course path — one ordered walk, and exactly one thing to do next.
///
/// The reference designs for this all put a percentage on every node. That
/// looks informative and is the opposite: six nodes each a third finished tells
/// a learner that nothing is done and invites them to pick, which is the
/// decision this screen exists to remove. So a node here is in one of four
/// states, the current one is the only one that looks alive, and the number at
/// the top is the only number on the screen.
class CoursePathScreen extends ConsumerWidget {
  const CoursePathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final path = ref.watch(coursePathProvider);

    return Scaffold(
      backgroundColor: _Path.canvas,
      body: SafeArea(
        child: path.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Failed(
            message: l.questionsError,
            onRetry: () => ref.invalidate(coursePathProvider),
          ),
          data: (levels) => levels.isEmpty
              ? _Failed(
                  message: l.questionsError,
                  onRetry: () => ref.invalidate(coursePathProvider),
                )
              : _PathBody(levels: levels),
        ),
      ),
    );
  }
}

/// The path's own palette.
///
/// Local and deliberately so: this screen is the one place in the app that is
/// a single continuous surface rather than a stack of cards, and it needs a
/// ground of its own to sit on.
abstract final class _Path {
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
  static const gold = AppColors.xp;

  /// One hue per CEFR level, walked in order — the course visibly warms as it
  /// gets harder, which is a thing you can feel while scrolling and cannot
  /// read from a label.
  static const levelHues = [
    Color(0xFF34D399),
    Color(0xFF22D3EE),
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
  ];
}

class _PathBody extends ConsumerStatefulWidget {
  const _PathBody({required this.levels});
  final List<CourseLevel> levels;

  @override
  ConsumerState<_PathBody> createState() => _PathState();
}

class _PathState extends ConsumerState<_PathBody> {
  final _scroll = ScrollController();
  final _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Open where the learner left off, not at the top. After thirty units the
    // top of the path is history, and making somebody scroll past their own
    // finished work to find today's lesson is a small insult repeated daily.
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
  }

  void _jumpToCurrent() {
    final ctx = _currentKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.35,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // The level being walked: the first with an unfinished unit, else the last.
    final active = widget.levels.firstWhere(
      (c) => c.units.any((u) => u.state != UnitState.done),
      orElse: () => widget.levels.last,
    );
    final hue = _hueFor(active);

    final rows = <Widget>[];
    for (var i = 0; i < widget.levels.length; i++) {
      final level = widget.levels[i];
      rows.add(_LevelBanner(level: level, hue: _hueFor(level)));
      for (var n = 0; n < level.units.length; n++) {
        final unit = level.units[n];
        rows.add(
          _Node(
            key: unit.state == UnitState.current ? _currentKey : null,
            unit: unit,
            hue: _hueFor(level),
            // Alternating left and right, with the ends pulled in. A straight
            // column of circles reads as a list; the sway is what makes it a
            // journey, which is the whole point of drawing it this way.
            offset: math.sin(n * 0.9) * 0.62,
            // A line of encouragement in the space the path leaves empty,
            // every few nodes. Not on every one: a thought repeated at every
            // step stops being read, and the path is the content here.
            quote: n >= 2 && (n - 2) % 4 == 0
                ? _Quotes.at(i * 31 + n)
                : null,
            nextOffset: n + 1 < level.units.length
                ? math.sin((n + 1) * 0.9) * 0.62
                : null,
            onTap: () => _open(unit),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(coursePathProvider),
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          // A way out, at the top where a thumb reaches for it.
          //
          // The path has no app bar — it is one continuous surface by design —
          // which left the only exit as the system gesture. On a Telegram Mini
          // App that gesture closes the whole app, so a learner who wanted to
          // go back to the home screen lost the app instead.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, 0, 0),
              child: Row(children: [
                IconButton(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/home'),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: _Path.soft),
                  tooltip: MaterialLocalizations.of(context)
                      .backButtonTooltip,
                ),
                Text(
                  l.lessonCourseTitle,
                  style: const TextStyle(
                    color: _Path.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: _Header(level: active, hue: hue, l: l)),
          SliverList(delegate: SliverChildListDelegate(rows)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxxl)),
        ],
      ),
    );
  }

  Color _hueFor(CourseLevel level) {
    final i = widget.levels.indexOf(level);
    return _Path.levelHues[i % _Path.levelHues.length];
  }

  void _offerJump(UnitNode unit, AppLocalizations l) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Path.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.fast_forward_rounded,
                color: _Path.gold, size: 34),
            const SizedBox(height: AppSpace.md),
            Text(l.courseJumpTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _Path.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpace.sm),
            Text(l.courseJumpBody(12, 80),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _Path.soft, fontSize: 13.5, height: 1.4)),
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _Path.gold,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/course/test-out/${unit.id}');
              },
              child: Text(l.courseJumpStart,
                  style: const TextStyle(
                      color: Color(0xFF2A1B00),
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.courseJumpCancel,
                  style: const TextStyle(color: _Path.soft)),
            ),
          ]),
        ),
      ),
    );
  }

  void _open(UnitNode unit) {
    final l = AppLocalizations.of(context);
    if (unit.state == UnitState.premium) {
      context.push('/plans');
      return;
    }
    if (!unit.state.isOpen) {
      // A locked unit is an offer, not a wall.
      //
      // Nobody should be made to walk through material they already know, so
      // tapping ahead asks whether they do. Saying only "not yet" tells a
      // learner who is genuinely past this that the app has misjudged them,
      // and there is nothing they can do about it.
      _offerJump(unit, l);
      return;
    }
    context.push('/course/unit/${unit.id}');
  }
}

/// The one number on the screen.
class _Header extends StatelessWidget {
  const _Header({required this.level, required this.hue, required this.l});

  final CourseLevel level;
  final Color hue;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final done = level.units.where((u) => u.state == UnitState.done).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hue.withValues(alpha: 0.22), _Path.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: hue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                level.title,
                style: const TextStyle(
                  color: _Path.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Text(
              '${level.percent}%',
              style: TextStyle(
                color: hue,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ]),
          const SizedBox(height: 3),
          Text(
            l.courseUnitsDone(done, level.units.length),
            style: const TextStyle(color: _Path.soft, fontSize: 12.5),
          ),
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: level.units.isEmpty ? 0 : done / level.units.length,
              minHeight: 7,
              backgroundColor: _Path.canvas,
              valueColor: AlwaysStoppedAnimation(hue),
            ),
          ),
        ],
      ),
    );
  }
}

/// The divider between one CEFR level and the next.
class _LevelBanner extends StatelessWidget {
  const _LevelBanner({required this.level, required this.hue});

  final CourseLevel level;
  final Color hue;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
        AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.sm),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: hue.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: hue.withValues(alpha: 0.4)),
        ),
        child: Text(
          level.cefrLevel,
          style: TextStyle(
              color: hue, fontSize: 11.5, fontWeight: FontWeight.w900),
        ),
      ),
      const SizedBox(width: AppSpace.sm),
      Expanded(
        child: Text(
          level.title,
          style: const TextStyle(
              color: _Path.soft, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      Expanded(child: Container(height: 1, color: _Path.line)),
    ]),
  );
}

/// One unit on the path.
class _Node extends StatelessWidget {
  const _Node({
    super.key,
    required this.unit,
    required this.hue,
    required this.offset,
    required this.nextOffset,
    required this.quote,
    required this.onTap,
  });

  final UnitNode unit;
  final Color hue;

  /// -1 hard left, 1 hard right.
  final double offset;

  /// Where the next node sits, so the connector can actually reach it. Null on
  /// the last node of a level, which has nothing to connect to.
  final double? nextOffset;

  /// Deliberately English, whatever the app's language is set to.
  ///
  /// These are not interface text. They are the language being learned, met in
  /// passing — the one place in the app where reading English is the point
  /// rather than the obstacle, and where nobody has to understand it for the
  /// screen to work.
  final String? quote;
  final VoidCallback onTap;

  static const _size = 60.0;

  @override
  Widget build(BuildContext context) {
    final current = unit.state == UnitState.current;
    final done = unit.state == UnitState.done;
    final premium = unit.state == UnitState.premium;

    return LayoutBuilder(
      builder: (context, box) {
        final travel = (box.maxWidth - _size) / 2 - AppSpace.xl;
        return SizedBox(
          // The current node carries the "start" label above it, so its row is
          // taller. Giving every row that height instead would space the whole
          // path out to suit the one node that needs it.
          height: current ? 150 : 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The connector, drawn behind everything and only as far as the
              // learner has reached: a lit trail behind and a dim one ahead is
              // the progress bar this screen does not otherwise need.
              Positioned.fill(
                child: CustomPaint(
                  painter: _Trail(
                    offset: offset,
                    nextOffset: nextOffset,
                    travel: travel,
                    lit: done || current,
                    hue: hue,
                  ),
                ),
              ),
              if (quote != null)
                // Opposite the node, in the half the sway left over.
                Align(
                  alignment: Alignment(-offset.sign, -0.15),
                  child: SizedBox(
                    width: box.maxWidth * 0.33,
                    child: _Quote(text: quote!),
                  ),
                ),
              Align(
                alignment: Alignment(offset, -1),
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The single most important thing on this screen.
                      //
                      // Learners told us they could not tell what to do. A
                      // glowing circle is a designer's idea of an invitation;
                      // a word that says "start", attached to the one node
                      // they may tap, is everybody else's.
                      if (current) _StartCallout(hue: hue),
                      _Disc(
                        unit: unit,
                        hue: hue,
                        size: _size,
                        current: current,
                        done: done,
                        premium: premium,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 136,
                        child: Text(
                          unit.title,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: current ? _Path.ink : _Path.soft,
                            fontSize: 12,
                            fontWeight:
                                current ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.unit,
    required this.hue,
    required this.size,
    required this.current,
    required this.done,
    required this.premium,
  });

  final UnitNode unit;
  final Color hue;
  final double size;
  final bool current;
  final bool done;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final fill = done
        ? hue
        : current
            ? hue
            : _Path.surface;
    return SizedBox(
      width: size,
      height: size + 10,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done || current
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(fill, Colors.white, 0.22)!,
                        Color.lerp(fill, Colors.black, 0.18)!,
                      ],
                    )
                  : null,
              color: done || current ? null : _Path.surface,
              border: Border.all(
                color: current
                    // Was a white ring, which glowed against the old dark
                    // canvas and disappears entirely against this one.
                    ? AppColors.brand
                    : done
                        ? Colors.transparent
                        : _Path.line,
                width: current ? 3 : 1.5,
              ),
              boxShadow: current
                  ? [
                      BoxShadow(
                        color: hue.withValues(alpha: 0.45),
                        blurRadius: 26,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: premium
                ? const Icon(Icons.workspace_premium_rounded,
                    color: _Path.gold, size: 25)
                : done
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 28)
                    : Text(
                        unit.number,
                        style: TextStyle(
                          color: current ? Colors.white : _Path.faint,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
          ),
          if (!current && !done && !premium)
            Positioned(
              bottom: 6,
              child: Icon(Icons.lock_rounded,
                  size: 15, color: _Path.faint.withValues(alpha: 0.9)),
            ),
          // Mastery, as filled pips rather than a percentage. "Level 2 of 5"
          // is a thing to finish; "36%" is a thing to feel bad about.
          if (done)
            Positioned(
              bottom: -2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < unit.maxMastery; i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < unit.mastery ? _Path.gold : _Path.line,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Short lines of English, shown beside the path.
///
/// Kept in English on purpose, and NOT put through the localisation files.
/// Translating them would make them interface copy; left alone they are a small
/// piece of the language the learner came here for, met without being tested on
/// it. Nobody has to understand one for the screen to work, so an unfamiliar
/// word here costs nothing and may be worth something.
abstract final class _Quotes {
  static const lines = [
    'A little every day beats a lot one day.',
    'You are closer than you were yesterday.',
    'Mistakes are the lesson.',
    'Slow is fine. Stopping is not.',
    'One more word. Then one more.',
    'Fluency is a habit, not a gift.',
    'Say it badly first. Say it well later.',
    'The hard part is showing up.',
    'Small steps, every single day.',
    'You will speak this. Keep going.',
  ];

  /// Picked by position rather than at random, so scrolling up and down does
  /// not reshuffle the page under the reader.
  static String at(int seed) => lines[seed.abs() % lines.length];
}

class _Quote extends StatelessWidget {
  const _Quote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: _Path.faint.withValues(alpha: 0.85),
      fontSize: 12,
      height: 1.45,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// "Start" — pointing at the only node that can be tapped.
class _StartCallout extends StatefulWidget {
  const _StartCallout({required this.hue});
  final Color hue;

  @override
  State<_StartCallout> createState() => _StartCalloutState();
}

class _StartCalloutState extends State<_StartCallout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(
      // A small, slow bob. Enough to catch the eye on a screen that is
      // otherwise still; not enough to be the thing you look at.
      offset: Offset(0, -3 * _c.value),
      child: child,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.hue,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: widget.hue.withValues(alpha: 0.45),
                blurRadius: 16,
              ),
            ],
          ),
          child: Text(
            AppLocalizations.of(context).courseStart.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        // The little tail, so the label belongs to the circle rather than
        // floating above it.
        CustomPaint(size: const Size(12, 6), painter: _Tail(widget.hue)),
        const SizedBox(height: 2),
      ],
    ),
  );
}

class _Tail extends CustomPainter {
  const _Tail(this.hue);
  final Color hue;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = hue);
  }

  @override
  bool shouldRepaint(_Tail old) => old.hue != hue;
}

/// The dashes from one node to the next.
///
/// Curved, and aimed at where the next node actually is. A straight stub
/// pointing down from each node connects nothing and reads as decoration; the
/// line has to arrive somewhere for the path to look like a path.
class _Trail extends CustomPainter {
  const _Trail({
    required this.offset,
    required this.nextOffset,
    required this.travel,
    required this.lit,
    required this.hue,
  });

  final double offset;
  final double? nextOffset;
  final double travel;
  final bool lit;
  final Color hue;

  @override
  void paint(Canvas canvas, Size size) {
    final next = nextOffset;
    if (next == null) return;

    final paint = Paint()
      ..color = lit ? hue.withValues(alpha: 0.5) : _Path.line
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    final from = Offset(midX + offset * travel, 46);
    final to = Offset(midX + next * travel, size.height + 12);

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(
        from.dx, from.dy + (to.dy - from.dy) * 0.5,
        to.dx, from.dy + (to.dy - from.dy) * 0.5,
        to.dx, to.dy,
      );

    // Dashed by walking the curve rather than by drawing straight segments:
    // the gaps have to follow the bend or they bunch up on the corners.
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      var d = 0.0;
      while (d < metric.length) {
        final end = math.min(d + 6, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_Trail old) =>
      old.lit != lit || old.offset != offset || old.nextOffset != nextOffset;
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: _Path.faint, size: 40),
          const SizedBox(height: AppSpace.md),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _Path.soft)),
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    ),
  );
}
