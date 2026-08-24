import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/share.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/referral.dart';

/// "Invite a friend", drawn only when the server says this learner may see it.
///
/// The minutes it earns are the point, so they are what the card leads with —
/// and the fact that they do not expire is said out loud, because every other
/// number in this app is a daily allowance and a learner has no reason to
/// assume this one is different.
class ReferralCard extends ConsumerWidget {
  const ReferralCard({super.key, required this.status});

  final ReferralStatus status;

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(apiClientProvider);
    final text = l.referralShareText(status.link);
    // Same route as every other invite in the app: inside a Mini App this must
    // not navigate, or Telegram tears the app down.
    final outcome = await shareInvite(
      text,
      prepare: () => prepareInvite(api, text: text),
    );
    if (!context.mounted || outcome != ShareOutcome.copied) return;
    messenger.showSnackBar(SnackBar(content: Text(l.inviteCopied)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: AppColors.xp, size: 22),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  l.referralTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            l.referralBody(status.minutesPerFriend),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          // Only once there is something to report: a pair of zeroes reads as a
          // feature that is not working rather than one nobody has used yet.
          if (status.friendsJoined > 0 || status.minutesLeft > 0) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              children: [
                CountChip(
                  text: l.referralFriends(status.friendsJoined),
                  color: AppColors.speaking,
                ),
                CountChip(
                  text: l.referralEarned(status.minutesEarned),
                  color: AppColors.xp,
                ),
                // Earned and left are different numbers the moment any of it is
                // spoken, and the second is the one that answers "can I keep
                // going today". Showing only a total would go stale in a way
                // the learner would read as the bonus not working.
                CountChip(
                  text: l.referralLeft(status.minutesLeft),
                  color: AppColors.brandDark,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _invite(context, ref),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(l.referralCta),
            ),
          ),
        ],
      ),
    );
  }
}


/// A small tinted pill for a number on a WHITE card.
///
/// Deliberately not `_GlassChip`, which is white-on-white by design — it is
/// built for the gradient header, and reusing it here drew three chips nobody
/// could see, leaving a gap in the card where the counts should have been.
class CountChip extends StatelessWidget {
  const CountChip({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
