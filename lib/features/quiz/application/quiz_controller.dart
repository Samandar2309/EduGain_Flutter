import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../data/quiz_repository.dart';
import '../domain/models.dart';

/// Drives one player's view of the shared quiz.
///
/// The pacing is the interesting part. The server is asked once per phase, not
/// once per second: its answer carries the seconds left, and the countdown on
/// screen is interpolated locally from that. So a three-minute match costs
/// about a dozen requests per player instead of a hundred and eighty, and the
/// timer still moves smoothly.
///
/// In the lobby there is no phase to count down, so it polls on a short fixed
/// beat instead — a lobby that took twenty seconds to notice the second player
/// had arrived would feel broken to both of them.
class QuizState$ {
  const QuizState$({
    this.live,
    this.secondsLeft = 0,
    this.chosen,
    this.verdict,
    this.loading = true,
    this.busy = false,
    this.error,
  });

  final QuizState? live;

  /// Interpolated locally between polls.
  final double secondsLeft;

  /// Which option this player tapped, held so the UI can keep it highlighted
  /// through the reveal.
  final int? chosen;
  final QuizVerdict? verdict;
  final bool loading;

  /// A start/ready request is in flight — the button should not be tappable
  /// twice.
  final bool busy;
  final String? error;

  bool get answered => chosen != null;

  QuizState$ copyWith({
    QuizState? live,
    double? secondsLeft,
    int? chosen,
    QuizVerdict? verdict,
    bool? loading,
    bool? busy,
    String? error,
    bool clearAnswer = false,
    bool clearError = false,
  }) => QuizState$(
    live: live ?? this.live,
    secondsLeft: secondsLeft ?? this.secondsLeft,
    chosen: clearAnswer ? null : (chosen ?? this.chosen),
    verdict: clearAnswer ? null : (verdict ?? this.verdict),
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
  );
}

class QuizController extends StateNotifier<QuizState$> {
  QuizController(this._repo) : super(const QuizState$()) {
    _refresh();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  final QuizRepository _repo;
  Timer? _ticker;
  bool _fetching = false;

  /// The question the held answer belongs to. When the server moves on, the
  /// highlight has to go with it — otherwise option two stays lit into a
  /// question where option two is something else entirely.
  (int, int)? _answeredRound;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final left = state.secondsLeft - 0.2;
    if (left > 0) {
      state = state.copyWith(secondsLeft: left);
      return;
    }
    state = state.copyWith(secondsLeft: 0);
    _refresh();
  }

  /// How long to wait before asking again.
  ///
  /// While a match runs the server tells us exactly — the phase boundary. In
  /// the lobby there is nothing to count down, and the thing being waited for
  /// is another person arriving, so it asks often enough that they appear
  /// promptly.
  double _nextPollDelay(QuizState live) =>
      live.isPlaying ? live.remaining : 3.0;

  Future<void> _refresh() async {
    if (_fetching || !mounted) return;
    _fetching = true;
    try {
      final live = await _repo.state();
      if (!mounted) return;
      final round = (live.match, live.index);
      final movedOn = _answeredRound != null && _answeredRound != round;
      state = state.copyWith(
        live: live,
        secondsLeft: _nextPollDelay(live),
        loading: false,
        clearError: true,
        clearAnswer: movedOn,
      );
      if (movedOn) _answeredRound = null;
    } on ApiException catch (e) {
      if (!mounted) return;
      // Back off rather than hammer a server that is already unhappy.
      state = state.copyWith(
        loading: false,
        error: e.message,
        secondsLeft: 5,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loading: false, secondsLeft: 5);
    } finally {
      _fetching = false;
    }
  }

  /// Open a game. Everybody else gets a nudge — but only for the call that
  /// actually opened it, which the server decides.
  Future<void> start() => _act(() => _repo.start());

  /// "I'm ready."
  Future<void> ready() => _act(() => _repo.ready());

  Future<void> leave() => _act(() => _repo.ready(leave: true));

  Future<void> _act(Future<void> Function() action) async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) state = state.copyWith(error: e.message);
    } catch (_) {
      // Nothing useful to say; the next poll shows the truth either way.
    } finally {
      if (mounted) state = state.copyWith(busy: false);
      await _refresh();
    }
  }

  Future<void> choose(int option) async {
    final live = state.live;
    if (live == null || state.answered || live.phase != QuizPhase.answer) return;

    // Held immediately so the tap feels instant; the server's verdict lands a
    // moment later and only adds to it.
    _answeredRound = (live.match, live.index);
    state = state.copyWith(chosen: option);
    try {
      final verdict = await _repo.answer(
        match: live.match,
        index: live.index,
        choice: option,
      );
      if (!mounted) return;
      state = state.copyWith(verdict: verdict);
    } catch (_) {
      // A refused answer — the round closed under them, or a duplicate. The
      // reveal is seconds away and will show what was right, so there is
      // nothing useful to say here.
    }
  }
}

final quizRepositoryProvider = Provider(
  (ref) => QuizRepository(ref.read(apiClientProvider)),
);

/// What the hub card shows. Refetched each time the hub opens rather than
/// polled — a menu does not need a live number, only a true one.
final quizLiveProvider = FutureProvider.autoDispose(
  (ref) => ref.read(quizRepositoryProvider).live(),
);

final quizControllerProvider =
    StateNotifierProvider.autoDispose<QuizController, QuizState$>(
      (ref) => QuizController(ref.read(quizRepositoryProvider)),
    );
