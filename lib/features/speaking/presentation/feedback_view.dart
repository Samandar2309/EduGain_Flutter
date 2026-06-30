import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/models.dart';

Color _scoreColor(int v) => v >= 75
    ? const Color(0xFF10B981)
    : v >= 50
    ? const Color(0xFFF59E0B)
    : const Color(0xFFEF4444);

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
              Icon(Icons.insights_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l.feedbackTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (report.cefrEstimate != null)
                Chip(label: Text(report.cefrEstimate!)),
            ],
          ),
          const SizedBox(height: 16),
          if (report.scores != null) ...[
            _ScoreCard(scores: report.scores!),
            const SizedBox(height: 20),
          ],
          if (report.summary.isNotEmpty) Text(report.summary),
          if (report.strengths.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(l.strengths, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...report.strengths.map(
              (s) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                title: Text(s),
              ),
            ),
          ],
          if (report.errors.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(l.mistakes, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...report.errors.map((e) => _ErrorCard(error: e)),
          ],
          if (report.isLocked) ...[
            const SizedBox(height: 20),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.feedbackLocked),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The headline report card: a circular Overall gauge beside four skill bars,
/// with an honesty note that fluency/pronunciation are text-estimated.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.scores});

  final FeedbackScores scores;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ScoreRing(value: scores.overall, label: l.scoreOverall),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _SkillBar(label: l.scoreGrammar, value: scores.grammar),
                    _SkillBar(label: l.scoreVocabulary, value: scores.vocabulary),
                    _SkillBar(
                      label: l.scoreFluency,
                      value: scores.fluency,
                      estimated: true,
                    ),
                    _SkillBar(
                      label: l.scorePronunciation,
                      value: scores.pronunciation,
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
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.scoresEstimatedNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
  const _ScoreRing({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: CustomPaint(
            painter: _RingPainter(
              value / 100,
              color,
              theme.colorScheme.outlineVariant,
            ),
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
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
        ..color = track.withValues(alpha: 0.35),
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
    this.estimated = false,
  });

  final String label;
  final int value;
  final bool estimated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(value);
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
              backgroundColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.3,
              ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  error.original,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.red,
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 16),
                Expanded(
                  child: Text(
                    error.correction,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
