import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/ui/glass.dart';
import '../../../core/ui/tokens.dart';
import '../application/providers.dart';
import '../domain/models.dart';
import 'lesson_launch.dart';
import 'scenario_theme.dart';
import 'widgets/lesson_widgets.dart';

/// The lessons inside one track. Only what the learner is ready for is tappable;
/// premium / too-advanced lessons show a lock, so beginners aren't overwhelmed.
class TrackDetailScreen extends ConsumerStatefulWidget {
  const TrackDetailScreen({required this.track, super.key});

  final TrackSummary track;

  @override
  ConsumerState<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends ConsumerState<TrackDetailScreen> {
  bool _starting = false;

  Future<void> _start(TrackLesson lesson) async {
    if (lesson.isLocked) {
      _snack(
        lesson.isPremium
            ? 'This lesson is part of Premium.'
            : 'Reach ${lesson.cefrMin} to unlock this lesson.',
      );
      return;
    }
    await launchLesson(
      context,
      ref,
      lessonKey: lesson.key,
      backdropKey: lesson.backdrop,
      title: lesson.title,
      onBusy: (b) {
        if (mounted) setState(() => _starting = b);
      },
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final backdrop = backdropForKey(widget.track.backdrop);
    final detail = ref.watch(trackLessonsProvider(widget.track.track));
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: AppColors.canvasDark,
        body: Stack(
          children: [
            Positioned.fill(
              child: ImmersiveBackground(
                top: backdrop.top,
                bottom: backdrop.bottom,
                accent: backdrop.accent,
                watermark: backdrop.icon,
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(title: widget.track.title, subtitle: widget.track.subtitle),
                  Expanded(
                    child: detail.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const _DetailError(),
                      data: (d) => ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        children: [
                          for (final lesson in d.lessons)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LessonTile(
                                title: lesson.title,
                                subtitle: lesson.subtitle,
                                difficulty: lesson.difficulty,
                                estMinutes: lesson.estMinutes,
                                xpReward: lesson.xpReward,
                                grammarFocus: lesson.grammarFocus,
                                accent: backdrop.accent,
                                isPremium: lesson.isPremium,
                                isLocked: lesson.isLocked,
                                isDone: lesson.isDone,
                                onTap: () => _start(lesson),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_starting)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "Couldn't load these lessons. Please try again.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
