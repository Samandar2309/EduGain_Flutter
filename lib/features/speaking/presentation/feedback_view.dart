import 'package:flutter/material.dart';

import '../domain/models.dart';

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
                'Natija',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (report.cefrEstimate != null)
                Chip(label: Text(report.cefrEstimate!)),
            ],
          ),
          const SizedBox(height: 12),
          if (report.summary.isNotEmpty) Text(report.summary),
          if (report.strengths.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Kuchli tomonlar', style: theme.textTheme.titleMedium),
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
            Text('Xatolar', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...report.errors.map((e) => _ErrorCard(error: e)),
          ],
          if (report.isLocked) ...[
            const SizedBox(height: 20),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'To\'liq tahlil (barcha xatolar, maslahatlar) Premium bilan ochiladi.',
                ),
              ),
            ),
          ],
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
