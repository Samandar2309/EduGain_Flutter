import 'package:edugain/features/gamification/domain/leaderboard.dart';
import 'package:flutter_test/flutter_test.dart';

/// The board's client side.
///
/// Most of what can go wrong here is a shape problem off the wire: a missing
/// avatar read as a failure, an own-rank row drawn twice, an initial sliced out
/// of a surrogate pair. None of them throw — they just render wrong.
void main() {
  Map<String, dynamic> row(
    int rank,
    String name, {
    int xp = 100,
    String avatar = '',
    bool you = false,
  }) => {
    'rank': rank,
    'name': name,
    'xp': xp,
    'avatar_url': avatar,
    'is_you': you,
  };

  test('a board parses into ranked rows', () {
    final b = Leaderboard.fromJson({
      'top': [row(1, 'Aziz', xp: 2450), row(2, 'Ali', xp: 2390)],
      'you': row(2, 'Ali', xp: 2390, you: true),
      'is_previous': false,
    });
    expect(b.top.map((s) => s.name), ['Aziz', 'Ali']);
    expect(b.you!.rank, 2);
    expect(b.isPrevious, isFalse);
  });

  test('a learner inside the top is not drawn a second time', () {
    // Their row is already on screen; repeating it below reads as two people.
    final b = Leaderboard.fromJson({
      'top': [row(1, 'Aziz'), row(2, 'Ali', you: true)],
      'you': row(2, 'Ali', you: true),
    });
    expect(b.needsOwnRow, isFalse);
  });

  test('a learner outside the top gets their own row', () {
    // The reason `you` is sent separately at all: a board you cannot find
    // yourself in is one you stop opening.
    final b = Leaderboard.fromJson({
      'top': [row(1, 'Aziz'), row(2, 'Ali'), row(3, 'Dilnoza')],
      'you': row(17, 'Samandar', xp: 240, you: true),
    });
    expect(b.needsOwnRow, isTrue);
    expect(b.you!.rank, 17);
  });

  test('no XP yet means no row at all, not rank zero', () {
    final b = Leaderboard.fromJson({'top': [], 'you': null});
    expect(b.you, isNull);
    expect(b.needsOwnRow, isFalse);
    expect(b.isEmpty, isTrue);
  });

  test('a missing photo is a state, not a failure', () {
    // A locked-down Telegram profile has none. The UI draws initials for it,
    // so this has to be an ordinary empty string.
    final s = Standing.fromJson(row(1, 'Ali'));
    expect(s.hasPhoto, isFalse);
    expect(s.initial, 'A');
  });

  test('a photo is used when there is one', () {
    final s = Standing.fromJson(
      row(1, 'Ali', avatar: 'https://t.me/i/userpic/320/x.jpg'),
    );
    expect(s.hasPhoto, isTrue);
  });

  test('the initial survives a name that starts outside ASCII', () {
    // Telegram names carry emoji and non-Latin scripts. `substring(0, 1)`
    // would cut a surrogate pair in half and render a replacement box.
    expect(Standing.fromJson(row(1, 'Ўктам')).initial, 'Ў');
    expect(Standing.fromJson(row(1, '🌟Aziz')).initial, '🌟');
    expect(Standing.fromJson(row(1, '  ')).initial, '?');
    expect(Standing.fromJson(row(1, '')).initial, '?');
  });

  // ── the podium and the gap ──────────────────────────────────────────────

  test('the podium is the first three and the list is the rest', () {
    final b = Leaderboard.fromJson({
      'top': [for (var i = 1; i <= 6; i++) row(i, 'L$i', xp: 100 - i)],
    });
    expect(b.podium.map((s) => s.rank), [1, 2, 3]);
    expect(b.rest.map((s) => s.rank), [4, 5, 6]);
  });

  test('a board of two still has a podium and an empty rest', () {
    final b = Leaderboard.fromJson({
      'top': [row(1, 'A'), row(2, 'B')],
    });
    expect(b.podium.length, 2);
    expect(b.rest, isEmpty);
  });

  test('the gap says what it would take to move up one place', () {
    // A rank on its own is a verdict; "61 XP to 6th" is something to do
    // tonight. It is the one number that turns the board into an action.
    final b = Leaderboard.fromJson({
      'top': [
        row(5, 'Ahead', xp: 2100),
        row(6, 'Next', xp: 2040),
        row(7, 'Me', xp: 1980, you: true),
      ],
      'you': row(7, 'Me', xp: 1980, you: true),
    });
    expect(b.toNextPlace!.rank, 6);
    expect(b.toNextPlace!.xp, 61); // one more than the difference
  });

  test('first place has nowhere to climb', () {
    final b = Leaderboard.fromJson({
      'top': [row(1, 'Me', xp: 900, you: true), row(2, 'B', xp: 800)],
      'you': row(1, 'Me', xp: 900, you: true),
    });
    expect(b.toNextPlace, isNull);
  });

  test('the bar measures the gap, not the learner total', () {
    /// `xp / (xp + gap)` grows with the total, so a learner on 5 000 XP would
    /// show an almost-full bar while needing exactly the same points as one on
    /// 200. Both of these need 61; both must read the same.
    Leaderboard at(int mine, int ahead, int behind) => Leaderboard.fromJson({
      'top': [
        row(6, 'Ahead', xp: ahead),
        row(7, 'Me', xp: mine, you: true),
        row(8, 'Behind', xp: behind),
      ],
      'you': row(7, 'Me', xp: mine, you: true),
    });
    final small = at(200, 260, 100);
    final large = at(5000, 5060, 4900);
    expect(small.gapProgress, closeTo(large.gapProgress, 0.001));
    expect(small.gapProgress, greaterThan(0.55));
    expect(small.gapProgress, lessThan(0.75));
  });

  test('the streak rides along with the row', () {
    expect(Standing.fromJson({...row(1, 'A'), 'streak': 14}).streak, 14);
    expect(Standing.fromJson(row(1, 'A')).streak, 0);
  });

  test('a truncated payload does not crash the screen', () {
    // Every field falls back rather than throwing. The name lands on the
    // placeholder dash, so the disc shows a dash — legible, and better than a
    // row that fails to build and takes the list with it.
    final s = Standing.fromJson(const {});
    expect(s.rank, 0);
    expect(s.xp, 0);
    expect(s.isYou, isFalse);
    expect(s.hasPhoto, isFalse);
    expect(s.initial, isNotEmpty);
  });
}
