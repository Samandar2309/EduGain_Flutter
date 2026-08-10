import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/models.dart';
import 'providers.dart';

/// The words this learner is working on right now.
///
/// One question asked in one place, because two screens ask it: the list of
/// words to memorise, and the deck a game is dealt from. They must not disagree
/// — practising one set of words and being shown another is the kind of thing
/// that makes an app feel like it is not paying attention.
///
/// Order of preference:
///
/// 1. **Due for review.** Spaced repetition already decided these are the words
///    on the edge of being forgotten, which makes them exactly the ones worth
///    seeing and playing with.
/// 2. **Topped up from sets at the learner's own level** when review is thin —
///    which it always is for somebody who started today, and they are the
///    learner most likely to open a game first.
///
/// The top-up is bounded to a few sets. The catalogue holds forty-seven now,
/// and fetching all of them to fill a deck of twenty-four words would be
/// forty-seven requests to answer a question that three can.
const _wanted = 24;
const _minToPlay = 8;
const _maxSetsToOpen = 3;

/// Levels ordered so "near mine" can mean something.
const _ladder = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

/// Sets worth opening for this learner: nearest their level, in a different
/// order every time.
///
/// Two faults, and the second hid behind the first.
///
/// Ordering by level came first, because without it a B2 learner was dealt A1
/// words — not a game, just a waste of an evening.
///
/// But the top-up only ever opens three sets, and a stable sort meant the
/// SAME three, forever. Six hundred words were added to the catalogue and not
/// one of them reached a learner whose level already had three sets in front
/// of them: the pool could not see past the front of the queue. Shuffling
/// within each level band is what makes the rest of the catalogue reachable —
/// every visit deals from a different corner of it.
///
/// Random rather than a rotation counter: nothing here is stored per learner,
/// and "different from last time" is all this needs to be.
List<VocabSet> _forLevel(List<VocabSet> sets, String? level, Random rng) {
  final open = sets.where((s) => !s.isLocked).toList()..shuffle(rng);
  final mine = _ladder.indexOf((level ?? '').toUpperCase());
  if (mine < 0) return open; // never placed — any set is as good a guess
  int distance(VocabSet s) {
    final at = _ladder.indexOf(s.cefrLevel.toUpperCase());
    // A set we cannot place sorts last without being excluded: unknown is not
    // the same as wrong, and dropping it could empty the list.
    return at < 0 ? 99 : (at - mine).abs();
  }

  // Stable sort over an already-shuffled list: the level bands stay in order,
  // and the sets inside each band do not.
  open.sort((a, b) => distance(a).compareTo(distance(b)));
  return open;
}

final learningWordsProvider = FutureProvider.autoDispose<List<VocabItem>>((
  ref,
) async {
  final repo = ref.read(vocabularyRepositoryProvider);
  final level = ref.watch(authControllerProvider).user?.cefrLevel;

  final due = await repo.fetchReview();
  if (due.length >= _wanted) return due.take(_wanted).toList();

  // Not enough to work with. Open a few sets near their level and take the rest.
  final pool = <String, VocabItem>{for (final item in due) item.id: item};
  try {
    final sets = _forLevel(await repo.listSets(), level, Random());
    for (final set in sets.take(_maxSetsToOpen)) {
      if (pool.length >= _wanted) break;
      final detail = await repo.getSet(set.id);
      for (final item in detail.items) {
        pool.putIfAbsent(item.id, () => item);
      }
    }
  } on Object {
    // Whatever review gave us is still worth showing. A failed top-up must not
    // empty a list that had something in it.
  }
  return pool.values.take(_wanted).toList();
});

/// Whether there are enough words to deal a game from.
bool canPlay(List<VocabItem> words) => words.length >= _minToPlay;

/// Every word the learner can study, in themed groups — what the "words to
/// memorise" screen shows.
///
/// Deliberately NOT `learningWordsProvider`. That one deals a game: twenty-four
/// words, a round's worth, shuffled so play stays fresh. Pointing the list at
/// it meant six hundred words were added to the catalogue and the list still
/// showed twenty-four — which is what a reader reasonably calls "you did not
/// add them".
///
/// A list and a deck are different questions. They only looked like the same
/// one because a deck was the first thing that existed.
final wordGroupsProvider = FutureProvider.autoDispose<List<VocabGroup>>((ref) {
  final level = ref.watch(authControllerProvider).user?.cefrLevel;
  return ref.read(vocabularyRepositoryProvider).listWordGroups(level: level);
});
