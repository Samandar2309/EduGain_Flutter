import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Whether the learner has waved the level test away for this run of the app.
///
/// Deliberately not persisted. Skipping means "not now", and storing it as
/// "never" would quietly leave them on the guessed A2 for good — the exact
/// outcome the test exists to prevent. This way it costs one dismissal per
/// launch, and stops entirely the moment a level exists.
final levelInviteSkippedProvider = StateProvider<bool>((_) => false);

/// Whether to put the invite in front of Speaking.
///
/// A named rule rather than a condition inline in the widget, because it is
/// the one place these two facts meet and both ways of getting it wrong are
/// silent: too eager and it blocks learners who already have a level, too shy
/// and nobody is ever asked at all.
bool shouldInviteToLevelTest({
  required String? cefrLevel,
  required bool skipped,
}) =>
    !skipped && (cefrLevel == null || cefrLevel.isEmpty);

/// Shown once, in front of Speaking, to a learner with no measured level.
///
/// Without one the tutor is pitched at A2 — a guess, and the wrong one for
/// most people. The symptom nobody reports as a level problem is reaching for
/// Translate six times a session. Two minutes here removes the guess.
///
/// Here rather than on the home screen because this is where the level is
/// actually spent: the reason to take the test is the conversation about to
/// start, and a prompt on the home screen has to explain that from cold.
class LevelInvite extends ConsumerWidget {
  const LevelInvite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
                boxShadow: AppShadow.glow(AppColors.brand),
              ),
              child: const Center(
                child: Icon(
                  Icons.tune,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xxl),
            Text(
              l.levelInviteTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              l.levelInviteBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            // The cost, stated before the tap rather than discovered at
            // question four. Most people abandon a test because they cannot
            // see the end of it, not because it is hard.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.canvasAlt,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                l.levelInviteMeta,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.push('/placement'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
                child: Text(l.levelInviteStart),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            // Skippable on purpose. A hard gate in front of the one feature
            // people came for turns a two-minute detour into a reason to close
            // the app, and a learner who never speaks is worse off than one
            // taught at the wrong level.
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () =>
                    ref.read(levelInviteSkippedProvider.notifier).state = true,
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(
                  l.levelInviteSkip,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
