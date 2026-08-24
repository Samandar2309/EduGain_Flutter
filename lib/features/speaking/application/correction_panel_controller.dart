import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the correction panel shows only the fix, or the reasoning too.
///
/// The panel carries three things: what the learner should have said, why, and
/// how a fluent speaker would have put it. All three are worth having and all
/// three at once are four lines of text — which, on a phone, sits on top of the
/// tutor's face. The avatar is most of what makes this feel like talking to
/// somebody, so a panel that buries it costs more than it looks like it does.
///
/// Collapsed is therefore not "hidden": the **correction itself stays on
/// screen**, on one line. What folds away is the explanation, which is the part
/// a learner reads once and then stops needing. A tap brings it back.
///
/// **Collapsed by default**, for the same reason [ListenModeController] hides
/// the tutor's line by default: the learner still sees the fix, so nothing of
/// value is hidden behind a discovery, and the way to the rest of it is one tap
/// on something already in front of them.
///
/// Persisted, because this is a lasting preference about how someone wants to
/// study, not a per-turn decision they should have to make again on every
/// mistake they make.
class CorrectionPanelController extends StateNotifier<bool> {
  CorrectionPanelController() : super(defaultCollapsed) {
    _load();
  }

  static const String prefsKey = 'speaking.corrections_collapsed';

  /// What a learner who has never touched the toggle gets.
  static const bool defaultCollapsed = true;

  /// Whether the learner has already chosen in this session.
  ///
  /// Tracked explicitly rather than inferred from the value: comparing the
  /// state against the default to detect "untouched" silently stops working the
  /// moment the default changes, and would then ignore a saved choice for ever.
  bool _chosen = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(prefsKey);
    // Never clobber a choice made before prefs finished loading.
    if (saved != null && !_chosen) state = saved;
  }

  Future<void> toggle() async {
    _chosen = true;
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, state);
  }
}
