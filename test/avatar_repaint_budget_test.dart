import 'package:edugain/features/speaking/presentation/avatar/avatar_state.dart';
import 'package:edugain/features/speaking/presentation/avatar/vector_hero_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// The avatar's frame budget. Painting the hero is a dozen full-screen image
/// draws, and it runs for the whole lesson — so the rule that decides how often
/// it repaints is worth pinning down.
void main() {
  group('heroRepaintBudget', () {
    test('spends every frame only while lip-syncing', () {
      // The mouth shape changes with the syllable; at half rate it reads as
      // dubbed. Nothing else on this hero is synchronised to anything.
      expect(heroRepaintBudget(AvatarState.talking), 0);
    });

    test('halves the cost of every state that is not lip-syncing', () {
      // This test previously asserted the opposite, on my claim that the
      // listening nod and thinking glance "break at half rate". That claim was
      // never tested, and learners were reporting the app freezing during
      // speaking — where the avatar spends most of the lesson NOT talking,
      // since the learner's own turn and the wait for a reply are both here.
      //
      // Fourteen blur passes a frame at 60fps, for the majority of a lesson,
      // bought smoothness nobody had asked for.
      for (final state in [
        AvatarState.listening,
        AvatarState.thinking,
        AvatarState.idle,
      ]) {
        expect(heroRepaintBudget(state), closeTo(1 / 30, 1e-9),
            reason: '$state has no lip-sync to protect');
      }
    });

    test('never freezes: the budget is always a finite, short interval', () {
      // A frozen avatar reads as a crashed app, so no state may return
      // something that would stop the idle breathing/blinking outright.
      for (final state in AvatarState.values) {
        final budget = heroRepaintBudget(state);
        expect(budget, greaterThanOrEqualTo(0));
        expect(budget, lessThanOrEqualTo(1 / 20),
            reason: 'idle motion must still read as alive');
      }
    });
  });
}
