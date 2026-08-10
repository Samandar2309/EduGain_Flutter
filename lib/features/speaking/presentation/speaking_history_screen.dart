import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';
import 'feedback_view.dart';

/// Past conversations, newest first. The server has always kept them — this is
/// the first screen that shows them, so a learner can look back at what they
/// practised and re-read the report they were given.
class SpeakingHistoryScreen extends ConsumerWidget {
  const SpeakingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final history = ref.watch(speakingHistoryProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l.speakingHistoryTitle),
        backgroundColor: AppColors.canvas,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(speakingHistoryProvider),
        child: history.when(
          loading: () => const AppLoader(),
          error: (_, _) => ListView(children: [Center(child: Text(l.loadFailed))]),
          data: (rows) => rows.isEmpty
              ? _Empty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xxl),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: _SessionCard(session: rows[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, 120, AppSpace.xl, 0),
      children: [
        const Icon(Icons.forum, size: 60, color: AppColors.inkFaint),
        const SizedBox(height: AppSpace.md),
        Text(l.speakingHistoryEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(l.speakingHistoryEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.inkFaint, fontSize: 13, height: 1.4)),
      ],
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.session});

  final SpeakingSession session;

  /// A conversation is only worth opening if it produced a report; an
  /// abandoned one has nothing to show.
  bool get _hasReport => session.status == 'completed';

  String _title(AppLocalizations l) {
    final topic = session.freeTopic?.trim();
    if (topic != null && topic.isNotEmpty) return topic;
    final key = session.lessonKey;
    if (key != null && key.isNotEmpty) {
      // The catalogue key is "track.lesson"; show the lesson part, humanised.
      final leaf = key.split('.').last.replaceAll('_', ' ');
      return leaf.isEmpty ? l.speakingFreeTopicLabel : '${leaf[0].toUpperCase()}${leaf.substring(1)}';
    }
    return l.speakingFreeTopicLabel;
  }

  String _when() {
    final d = session.startedAt?.toLocal();
    if (d == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _hasReport ? () => _openReport(context, ref, l) : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppGradients.accent(AppColors.speaking),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadow.glow(AppColors.speaking),
                  ),
                  child: const Icon(Icons.record_voice_over,
                      color: Colors.white, size: 23),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppColors.ink)),
                      const SizedBox(height: 3),
                      Text(
                        [
                          _when(),
                          l.speakingTurnsCount(session.turnCount),
                          if (!_hasReport) l.speakingUnfinished,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (_hasReport)
                  const Icon(Icons.chevron_right,
                      color: AppColors.speaking, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReport(
      BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final report = await ref
          .read(speakingRepositoryProvider)
          .sessionFeedback(session.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // the loader
      await showFeedbackSheet(context, report, sessionId: session.id);
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l.speakingNoReport)));
    }
  }
}
