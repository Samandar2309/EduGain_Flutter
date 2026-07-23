import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/models.dart';

Color _scoreColor(int v) => v >= 75
    ? AppColors.success
    : v >= 50
    ? AppColors.warning
    : AppColors.danger;

Future<void> showFeedbackSheet(BuildContext context, FeedbackReport report) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FeedbackSheet(report: report),
  );
}

class _FeedbackSheet extends StatelessWidget {
  const _FeedbackSheet({required this.report});

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.brand),
              const SizedBox(width: 8),
              Text(
                l.feedbackTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (report.cefrEstimate != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    report.cefrEstimate!,
                    style: const TextStyle(
                      color: AppColors.brandDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (report.scores != null) ...[
            _ScoreCard(scores: report.scores!, deltas: report.scoreDeltas),
            const SizedBox(height: 20),
          ],
          if (report.summary.isNotEmpty)
            Text(report.summary, style: const TextStyle(height: 1.45)),
          if (report.strengths.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l.strengths,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...report.strengths.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s, style: const TextStyle(height: 1.35))),
                  ],
                ),
              ),
            ),
          ],
          if (report.errors.isNotEmpty || report.isLocked) ...[
            const SizedBox(height: 20),
            Text(
              l.mistakes,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...report.errors.map((e) => _ErrorCard(error: e)),
          ],
          // Free tier: the report beyond the teaser exists but is redacted —
          // a blurred skeleton makes the hidden depth *visible*, and the CTA
          // sits right where the value is.
          if (report.isLocked) ...[
            const SizedBox(height: 4),
            const _LockedReportTeaser(),
          ],
        ],
      ),
    );
  }
}

/// The headline report card: a circular Overall gauge beside four skill bars
/// (with progress deltas vs the previous session), and an honesty note that
/// fluency/pronunciation are text-estimated.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.scores, required this.deltas});

  final FeedbackScores scores;
  final Map<String, int>? deltas;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ScoreRing(
                value: scores.overall,
                label: l.scoreOverall,
                delta: deltas?['overall'],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _SkillBar(
                      label: l.scoreGrammar,
                      value: scores.grammar,
                      delta: deltas?['grammar'],
                    ),
                    _SkillBar(
                      label: l.scoreVocabulary,
                      value: scores.vocabulary,
                      delta: deltas?['vocabulary'],
                    ),
                    _SkillBar(
                      label: l.scoreFluency,
                      value: scores.fluency,
                      delta: deltas?['fluency'],
                      estimated: true,
                    ),
                    _SkillBar(
                      label: l.scorePronunciation,
                      value: scores.pronunciation,
                      delta: deltas?['pronunciation'],
                      estimated: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.inkFaint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.scoresEstimatedNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.value, required this.label, this.delta});

  final int value;
  final String label;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(value);
    final d = delta;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: CustomPaint(
            painter: _RingPainter(value / 100, color, AppColors.line),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 27,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  if (d != null && d != 0)
                    Text(
                      d > 0 ? '▲$d' : '▼${d.abs()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: d > 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color, this.track);

  final double t;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    const sw = 9.0;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..color = track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * t.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.t != t || o.color != color;
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({
    required this.label,
    required this.value,
    this.delta,
    this.estimated = false,
  });

  final String label;
  final int value;
  final int? delta;
  final bool estimated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(value);
    final d = delta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  estimated ? '$label  ≈' : label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (d != null && d != 0) ...[
                Icon(
                  d > 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 11,
                  color: d > 0 ? AppColors.success : AppColors.danger,
                ),
                Text(
                  '${d.abs()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: d > 0 ? AppColors.success : AppColors.danger,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '$value',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              backgroundColor: AppColors.canvasAlt,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final FeedbackError error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  error.original,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.danger,
                    color: AppColors.danger,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.inkFaint,
                ),
              ),
              Expanded(
                child: Text(
                  error.correction,
                  style: const TextStyle(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (error.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              error.explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkSoft,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The free-tier paywall: the redacted rest of the report rendered as a
/// blurred skeleton (the depth is *seen*, not described), with the unlock CTA
/// floating exactly where the value is.
class _LockedReportTeaser extends StatelessWidget {
  const _LockedReportTeaser();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Skeleton "hidden mistakes" — blurred so it reads as real content.
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Column(
              children: List.generate(3, (i) => _SkeletonErrorRow(seed: i)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.30),
                    Colors.white.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  shape: BoxShape.circle,
                  boxShadow: AppShadow.glow(AppColors.brand),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.paywallReportTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l.paywallReportBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.push('/subscriptions'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 12,
                  ),
                ),
                child: Text(l.paywallSeePlans),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A fake redacted error row: grey text-bars in the same layout as
/// [_ErrorCard], believable once blurred.
class _SkeletonErrorRow extends StatelessWidget {
  const _SkeletonErrorRow({required this.seed});
  final int seed;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, Color c) => Container(
      width: w,
      height: 11,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    final widths = [
      [86.0, 118.0, 140.0],
      [120.0, 84.0, 168.0],
      [70.0, 132.0, 120.0],
    ][seed % 3];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              bar(widths[0], AppColors.danger.withValues(alpha: 0.45)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.inkFaint,
                ),
              ),
              bar(widths[1], AppColors.brand.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          bar(widths[2], AppColors.canvasAlt),
        ],
      ),
    );
  }
}
