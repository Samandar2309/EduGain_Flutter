import 'package:edugain/features/profile/application/referral.dart';
import 'package:flutter_test/flutter_test.dart';

/// The invite card is drawn from what the server says, never from a client
/// decision — so what matters is that a closed or unreadable answer never turns
/// into a visible card.
void main() {
  group('ReferralStatus', () {
    test('an open answer carries the link and the counts', () {
      final r = ReferralStatus.fromJson(const {
        'is_open': true,
        'link': 'https://t.me/edugain_bot?startapp=ref_abc',
        'friends_joined': 3,
        'bonus_seconds': 900,
        'minutes_per_friend': 5,
      });

      expect(r.isOpen, isTrue);
      expect(r.link, endsWith('ref_abc'));
      expect(r.friendsJoined, 3);
      expect(r.minutesLeft, 15, reason: '900 seconds is fifteen minutes');
      // Earned is what the friends were worth; left is what is unspent.
      expect(r.minutesEarned, 15);
      expect(r.minutesPerFriend, 5);
    });

    test('a closed answer carries nothing to draw', () {
      final r = ReferralStatus.fromJson(const {'is_open': false});
      expect(r.isOpen, isFalse);
      expect(r.link, isEmpty);
    });

    test('a missing flag is closed, not open', () {
      // The load-bearing direction. An older server, a truncated body or a
      // proxy that ate the payload must not open a feature that pays out real
      // minutes.
      expect(ReferralStatus.fromJson(const {}).isOpen, isFalse);
    });

    test('partial seconds round down rather than promising a minute', () {
      expect(ReferralStatus.fromJson(const {'bonus_seconds': 59}).minutesLeft, 0);
      expect(ReferralStatus.fromJson(const {'bonus_seconds': 61}).minutesLeft, 1);
    });

    test('earned and left part company as soon as any is spoken', () {
      // The pair the learner actually wants: two friends brought ten minutes,
      // and four of them are gone.
      final r = ReferralStatus.fromJson(const {
        'is_open': true,
        'friends_joined': 2,
        'minutes_per_friend': 5,
        'bonus_seconds': 360,
      });
      expect(r.minutesEarned, 10);
      expect(r.minutesLeft, 6);
    });
  });
}
