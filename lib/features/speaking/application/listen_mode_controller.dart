import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the tutor's line is hidden while it speaks — "listening mode".
///
/// Reading the subtitle while listening is comfortable, and that is the
/// problem: the ear never has to do the work. Hiding the text turns every turn
/// into listening practice, while a tap still reveals the line for anyone who
/// genuinely missed it.
///
/// Persisted, because this is a lasting preference about how someone wants to
/// study — not a per-session toggle they should have to find again every time.
///
/// **On by default.** A feature that has to be discovered is a feature most
/// people never use: with the line on screen there is nothing to prompt anyone
/// to wonder whether it could be taken away, and the eye button reads as
/// decoration. Hidden, the reason for it is immediate — and the way back is
/// immediate too, because the placeholder says so and a tap reveals the line.
class ListenModeController extends StateNotifier<bool> {
  ListenModeController() : super(defaultHidden) {
    _load();
  }

  static const String prefsKey = 'speaking.listen_mode';

  /// What a learner who has never touched the toggle gets.
  static const bool defaultHidden = true;

  /// Whether the learner has already made a choice in this session. Tracked
  /// explicitly rather than inferred from the value: the old guard compared the
  /// state against `false` to detect "untouched", which silently stopped
  /// working the moment the default stopped being `false` — a learner who had
  /// saved "show the text" would have had their choice ignored for ever.
  bool _chosen = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(prefsKey);
    // Never clobber a choice the learner made before prefs finished loading.
    if (saved != null && !_chosen) state = saved;
  }

  Future<void> toggle() async {
    _chosen = true;
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, state);
  }
}
