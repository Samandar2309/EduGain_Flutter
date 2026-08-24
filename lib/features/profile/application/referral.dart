import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/live_data.dart';
import '../../../core/providers.dart';

/// "Invite a friend", as the server describes it to this learner.
///
/// [isOpen] is the whole gate. The feature is closed by default and opened for
/// named accounts, so the client asks rather than decides — a build shipped
/// while it was closed must start showing the card the day it opens, without
/// another release.
class ReferralStatus {
  const ReferralStatus({
    required this.isOpen,
    this.link = '',
    this.friendsJoined = 0,
    this.bonusSeconds = 0,
    this.minutesPerFriend = 0,
  });

  const ReferralStatus.closed() : this(isOpen: false);

  final bool isOpen;

  /// The learner's own invite link, built server-side (the bot's name is
  /// deployment configuration, not something the app should guess).
  final String link;
  final int friendsJoined;

  /// Earned speaking time still unspent. These minutes do not expire, which is
  /// what makes them worth showing next to the daily allowance rather than
  /// inside it.
  final int bonusSeconds;
  final int minutesPerFriend;

  /// Still unspent — the number that answers "can I keep talking".
  int get minutesLeft => bonusSeconds ~/ 60;

  /// Everything these friends have ever been worth.
  ///
  /// Derived rather than stored: the difference between this and [minutesLeft]
  /// is what has already been spoken, which is the pair the learner wants to
  /// see. (It assumes every friend earned today's rate — true until the rate is
  /// changed, and a rounding error in the learner's favour if it ever is.)
  int get minutesEarned => friendsJoined * minutesPerFriend;

  factory ReferralStatus.fromJson(Map<String, dynamic> json) => ReferralStatus(
    isOpen: json['is_open'] as bool? ?? false,
    link: json['link'] as String? ?? '',
    friendsJoined: (json['friends_joined'] as num?)?.toInt() ?? 0,
    bonusSeconds: (json['bonus_seconds'] as num?)?.toInt() ?? 0,
    minutesPerFriend: (json['minutes_per_friend'] as num?)?.toInt() ?? 0,
  );
}

/// Closed on any failure, never an error state: this sits on a screen the
/// learner opens for other reasons, and a red box where an invite might have
/// been is worse than no invite.
///
/// Re-read when the app comes back to the foreground, because that is exactly
/// when it has changed: inviting a friend means leaving for Telegram, and they
/// join while the learner is away. Without this the card answers with whatever
/// it fetched before the invite was sent — which reads as the invite having
/// done nothing at all.
final referralStatusProvider = FutureProvider<ReferralStatus>((ref) async {
  refreshOnResume(ref);
  try {
    final data = await ref.read(apiClientProvider).get('/invite/referral');
    return ReferralStatus.fromJson(data);
  } catch (_) {
    return const ReferralStatus.closed();
  }
});
