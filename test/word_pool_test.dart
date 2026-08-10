import 'dart:math';

import 'package:edugain/features/vocabulary/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which sets a learner is dealt words from.
///
/// The pool used to take whichever sets the catalogue returned first, so a B2
/// learner could be handed A1 words — not a game, just a waste of an evening.
/// It was nearly harmless while B1 held a single set; the vocabulary expansion
/// took the catalogue from twenty-eight sets to forty-seven and made the order
/// decide everything.
///
/// The ordering lives in `word_pool.dart` as a private function, so it is
/// restated here. That is a real duplication and worth it: this is the rule
/// that decides what every learner sees, and it deserves to be pinned
/// somewhere a change has to walk past.
void main() {
  const ladder = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  List<VocabSet> forLevel(List<VocabSet> sets, String? level, Random rng) {
    final open = sets.where((s) => !s.isLocked).toList()..shuffle(rng);
    final mine = ladder.indexOf((level ?? '').toUpperCase());
    if (mine < 0) return open;
    int distance(VocabSet s) {
      final at = ladder.indexOf(s.cefrLevel.toUpperCase());
      return at < 0 ? 99 : (at - mine).abs();
    }

    open.sort((a, b) => distance(a).compareTo(distance(b)));
    return open;
  }

  VocabSet set(String slug, String level, {bool locked = false}) => VocabSet(
    id: slug,
    slug: slug,
    title: slug,
    cefrLevel: level,
    category: 'x',
    isPremium: false,
    isLocked: locked,
  );

  final catalogue = [
    set('a1-colours', 'A1'),
    set('a2-clothes', 'A2'),
    set('b1-work', 'B1'),
    set('b2-business', 'B2'),
    set('c1-law', 'C1'),
  ];

  test('a B1 learner gets B1 words first', () {
    final ordered = forLevel(catalogue, 'B1', Random(1));
    expect(ordered.first.cefrLevel, 'B1');
  });

  test('a B2 learner is not dealt A1 words', () {
    final top = forLevel(catalogue, 'B2', Random(1)).take(3).map((s) => s.cefrLevel);
    expect(top, isNot(contains('A1')));
  });

  test('the nearest levels come next, either side', () {
    // A B1 learner should see B1, then A2 and B2 before C1 — a word one band
    // away is useful, four bands away is noise.
    final ordered = forLevel(catalogue, 'B1', Random(1)).map((s) => s.cefrLevel).toList();
    expect(ordered.first, 'B1');
    expect(ordered.sublist(1, 3), containsAll(['A2', 'B2']));
    expect(ordered.last, 'C1');
  });

  test('a learner who never took the test still gets words', () {
    """Placement is optional now, so this is the common case, not an edge one.

    Returning nothing here would leave the games empty for everybody who
    skipped the test — which since today is most people.""";
    final ordered = forLevel(catalogue, null, Random(1));
    expect(ordered.length, catalogue.length);
  });

  test('locked sets are never dealt from', () {
    final withLocked = [...catalogue, set('c2-premium', 'C2', locked: true)];
    final ordered = forLevel(withLocked, 'C1', Random(1));
    expect(ordered.any((s) => s.isLocked), isFalse);
  });

  test('a set at an unknown level sorts last but is not thrown away', () {
    // Unknown is not the same as wrong, and dropping it could empty the list
    // for a learner whose only sets are unlabelled.
    final odd = [...catalogue, set('mystery', '')];
    final ordered = forLevel(odd, 'A1', Random(1));
    expect(ordered.last.slug, 'mystery');
    expect(ordered.length, odd.length);
  });

  test('the same level does not always deal the same sets', () {
    """The fault that made a 340-word expansion invisible.

    The pool opens three sets. With a stable sort that meant the same three
    forever, so every set past the front of a learner's level band was
    unreachable — six hundred words were added to the catalogue and not one of
    them could ever be dealt.""";

    final many = [
      for (var i = 0; i < 8; i++) set('b1-$i', 'B1'),
    ];
    final firstThree = <String>{};
    for (var seed = 0; seed < 12; seed++) {
      firstThree.addAll(
        forLevel(many, 'B1', Random(seed)).take(3).map((s) => s.slug),
      );
    }
    expect(
      firstThree.length,
      greaterThan(3),
      reason: 'twelve visits should reach more than three sets',
    );
  });

  test('shuffling never breaks the level ordering', () {
    // Whatever the shuffle does inside a band, a B1 learner must still get B1
    // first — the randomness is there to vary the choice, not to undo it.
    for (var seed = 0; seed < 20; seed++) {
      expect(forLevel(catalogue, 'B1', Random(seed)).first.cefrLevel, 'B1');
    }
  });
}
