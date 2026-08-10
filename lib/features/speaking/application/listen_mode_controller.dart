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
class ListenModeController extends StateNotifier<bool> {
  ListenModeController() : super(false) {
    _load();
  }

  static const String prefsKey = 'speaking.listen_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(prefsKey);
    // Never clobber a choice the learner made before prefs finished loading.
    if (saved != null && state == false) state = saved;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, state);
  }
}
