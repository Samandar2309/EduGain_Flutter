import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../data/question_repository.dart';
import '../domain/models.dart';

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(ref.read(apiClientProvider)),
);

/// The bank, fetched once and kept for the session.
///
/// `keepAlive` because it never changes while the app is open and a learner
/// moves between the part list, a topic and back constantly — refetching on
/// every pop would put a spinner in the middle of browsing.
final questionBankProvider = FutureProvider<List<QuestionPart>>((ref) async {
  ref.keepAlive();
  return ref.read(questionRepositoryProvider).bank();
});

/// Questions the learner saved.
///
/// Stored on the device rather than the server: a bookmark is a private note
/// to self, worth nothing to anyone else, and keeping it local means the list
/// works with no network and no extra endpoint. If it ever needs to follow
/// them across devices, this is the seam to move.
class BookmarkController extends StateNotifier<Set<String>> {
  BookmarkController() : super(const {}) {
    _load();
  }

  static const prefsKey = 'question_bookmarks';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = (prefs.getStringList(prefsKey) ?? const []).toSet();
    } on Object {
      // An unreadable store means no bookmarks, never a broken screen.
    }
  }

  bool contains(String question) => state.contains(question);

  Future<void> toggle(String question) async {
    final next = {...state};
    if (!next.remove(question)) next.add(question);
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(prefsKey, next.toList());
    } on Object {
      // The in-memory set already updated, so the tap still did something
      // visible; only persistence across launches is lost.
    }
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarkController, Set<String>>(
      (ref) => BookmarkController(),
    );

/// One question, and which part it came from.
class DrawnQuestion {
  const DrawnQuestion({required this.text, required this.partTitle});

  final String text;

  /// Shown with the question: "Part 2" changes how you are meant to answer it
  /// as much as the words do.
  final String partTitle;
}

/// Questions already drawn, so the same one never comes up twice.
///
/// Persisted, not session-scoped: a learner who practises for twenty minutes,
/// closes the app and comes back in the evening has not forgotten the question
/// they answered, and being handed it again reads as the app being broken.
///
/// Stored as the question text rather than an id because the bank has no
/// per-question ids — topics do, questions are plain strings inside them.
class SeenQuestions extends StateNotifier<Set<String>> {
  SeenQuestions() : super(const {}) {
    _load();
  }

  static const prefsKey = 'questions_drawn';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = (prefs.getStringList(prefsKey) ?? const []).toSet();
    } on Object {
      // An unreadable store means everything is unseen, never a dead button.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(prefsKey, state.toList());
    } on Object {
      // The in-memory set already updated, so this session still behaves.
    }
  }

  /// Draw an unseen question, or null when the bank is empty.
  ///
  /// Exhausting the bank starts it over rather than dead-ending: a button that
  /// stops working is worse than one that repeats itself after a hundred
  /// questions, and the caller is told so it can say as much.
  DrawnQuestion? draw(List<QuestionPart> parts, {required bool Function() onWrap}) {
    final pool = <DrawnQuestion>[];
    for (final part in parts) {
      for (final topic in part.topics) {
        for (final q in topic.questions) {
          pool.add(DrawnQuestion(text: q, partTitle: part.title));
        }
        // A cue card's prompt is a question too — and Part 2 would otherwise
        // never appear in a draw at all.
        final card = topic.cueCard;
        if (card != null && card.prompt.isNotEmpty) {
          pool.add(DrawnQuestion(text: card.prompt, partTitle: part.title));
        }
      }
    }
    if (pool.isEmpty) return null;

    var fresh = pool.where((q) => !state.contains(q.text)).toList();
    if (fresh.isEmpty) {
      onWrap();
      state = const {};
      unawaited(_save());
      fresh = pool;
    }

    final picked = fresh[Random().nextInt(fresh.length)];
    state = {...state, picked.text};
    unawaited(_save());
    return picked;
  }

  Future<void> reset() async {
    state = const {};
    await _save();
  }
}

final seenQuestionsProvider =
    StateNotifierProvider<SeenQuestions, Set<String>>((ref) => SeenQuestions());
