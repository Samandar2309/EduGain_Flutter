import 'package:edugain/features/speaking/presentation/level_invite.dart';
import 'package:flutter_test/flutter_test.dart';

/// Who gets asked for their level before their first conversation.
///
/// A learner with no measured level is taught at a guessed A2, which is wrong
/// for most of them — the symptom is reaching for Translate six times a
/// session, and nobody reports that as a level problem. So the ask goes in
/// front of Speaking, where the level is actually spent.
///
/// Both ways of getting this rule wrong are silent. Too eager and it stands in
/// front of people who were already placed; too shy and nobody is ever asked
/// and the guess stands forever. Hence a rule with a name and a test.
void main() {
  bool invite({String? level, bool skipped = false}) =>
      shouldInviteToLevelTest(cefrLevel: level, skipped: skipped);

  test('never measured means we ask', () {
    expect(invite(), isTrue);
  });

  test('an empty level is not a level', () {
    // The same trap this codebase has walked into three times: a value that is
    // absent and a value that is blank meaning different things by accident.
    // A learner sent "" has not been placed any more than one sent null.
    expect(invite(level: ''), isTrue);
  });

  test('already placed means we stay out of the way', () {
    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(
        invite(level: level),
        isFalse,
        reason: '$level is a measured level; asking again is nagging',
      );
    }
  });

  test('A1 counts as placed', () {
    // Worth its own line: A1 is the lowest band, so an implementation that
    // treats "lowest" as "unset" would keep asking exactly the beginners who
    // found the test hardest.
    expect(invite(level: 'A1'), isFalse);
  });

  test('saying not now is respected', () {
    expect(invite(skipped: true), isFalse);
  });

  test('skipping does not have to be repeated once a level exists', () {
    // Both conditions point the same way here; the check is that neither one
    // can flip the answer back on.
    expect(invite(level: 'B2', skipped: true), isFalse);
  });
}
