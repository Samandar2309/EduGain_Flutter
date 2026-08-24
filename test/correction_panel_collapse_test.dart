import 'package:edugain/features/speaking/application/correction_panel_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giving the tutor's face back, without giving up the correction.
///
/// The correction panel carries three things — the fix, why, and how a fluent
/// speaker would say it. All three at once is four lines of text, and on a
/// phone it sat squarely over the avatar, which is most of what makes this feel
/// like talking to somebody rather than filling in a form.
///
/// So it folds. Folded is deliberately NOT hidden: the correction itself stays
/// on screen and only the explanation folds away — the part a learner reads
/// once and then stops needing. These tests hold that distinction, and hold the
/// choice to being remembered, because a preference you have to set again after
/// every mistake is not a preference.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('it starts folded, so the avatar is visible from the first mistake', () {
    expect(CorrectionPanelController().state, isTrue);
    expect(CorrectionPanelController.defaultCollapsed, isTrue);
  });

  test('a tap unfolds it, and another folds it back', () async {
    final c = CorrectionPanelController();
    await c.toggle();
    expect(c.state, isFalse, reason: 'the explanation never opened');
    await c.toggle();
    expect(c.state, isTrue);
  });

  test('the choice outlives the session', () async {
    final first = CorrectionPanelController();
    await first.toggle(); // the learner wants the explanation

    // A new session, a new controller — the same learner.
    final next = CorrectionPanelController();
    await Future<void>.delayed(Duration.zero); // let the prefs read land
    expect(
      next.state,
      isFalse,
      reason: 'they asked for the explanation and were folded back up again',
    );
  });

  test('a choice made before prefs load is not overwritten by the old one', ()
      async {
    // The saved value says folded; the learner unfolds it while the read is
    // still in flight. Losing that would look like the tap did nothing.
    SharedPreferences.setMockInitialValues({
      CorrectionPanelController.prefsKey: true,
    });
    final c = CorrectionPanelController();
    await c.toggle();
    await Future<void>.delayed(Duration.zero);
    expect(c.state, isFalse, reason: 'the load clobbered a deliberate choice');
  });
}
