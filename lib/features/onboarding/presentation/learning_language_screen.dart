import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/flags.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// One language we teach, as the list shows it.
///
/// A const list rather than a call to the server: opening a second language is
/// never just a row appearing. It needs lessons, prompts, a voice and a flag
/// drawn — all of which ship in a release anyway, so the catalogue may as well
/// live where the flags do.
class _Course {
  const _Course({required this.code, required this.name, required this.flag});

  final String code;

  /// The endonym — what speakers call it, not what we call it. A learner
  /// scanning for their language looks for "Español", never "Spanish".
  final String name;
  final CustomPainter flag;
}

const _courses = <_Course>[
  _Course(code: 'en', name: 'English', flag: UnionJackPainter()),
  // Adding one here is the whole change: the list grows, the layout does not
  // move, and the first row stops being the only answer.
];

/// The learning-language step, shown once after the name.
///
/// A list, because it will be one — the second language is a row, not a
/// redesign. Today it holds a single course, and the subtitle says so rather
/// than leaving the learner wondering whether the rest failed to load.
///
/// It briefly listed the languages we do NOT teach, each with a "coming soon"
/// badge, and recorded taps on them as votes for what to build next. That put
/// three things you cannot have in front of somebody trying to finish signing
/// up, so it went.
class LearningLanguageScreen extends ConsumerStatefulWidget {
  const LearningLanguageScreen({super.key});

  @override
  ConsumerState<LearningLanguageScreen> createState() =>
      _LearningLanguageScreenState();
}

class _LearningLanguageScreenState
    extends ConsumerState<LearningLanguageScreen> {
  late String _selected = _courses.first.code;
  bool _saving = false;

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(learningLanguage: _selected);
      // Saving is what dismisses this screen: the router watches the learning
      // language and moves on as soon as it is set.
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.localized(l))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Centred, with the heading gone. Top-aligned, a lone card sat
            // under a band of empty space and read as the top of something
            // that had not finished loading. Centring a scroll view keeps the
            // list working when it is longer than the screen.
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final course in _courses) ...[
                        _CourseRow(
                          name: course.name,
                          flag: course.flag,
                          selected: course.code == _selected,
                          // A single row is already the answer; tapping it is
                          // reassurance rather than a choice, and it should still
                          // feel like one.
                          onTap: _saving
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selected = course.code);
                                },
                        ),
                        const SizedBox(height: AppSpace.md),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.continueAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.name,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final CustomPainter flag;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          // Generous for a row that is, today, most of the screen. A thin
          // list item works when there are seven of them; with one it looks
          // like the rest failed to arrive.
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: 22,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.line,
              width: selected ? 1.6 : 1,
            ),
            // The selected row carries its own colour and does not need a
            // shadow as well; unselected ones lift off the canvas.
            boxShadow: selected ? const [] : AppShadow.card,
          ),
          child: Row(
            children: [
              FlagBadge(painter: flag, width: 40),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.brandDeep : AppColors.ink,
                  ),
                ),
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: selected ? 1 : 0,
                child: const Icon(Icons.check_circle, color: AppColors.brand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
