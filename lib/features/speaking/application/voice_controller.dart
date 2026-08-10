import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The learner's chosen TTS voice, and whether we have finished looking for it.
///
/// The second half is the point. A plain `String?` cannot tell "preferences are
/// still loading" apart from "no voice was ever chosen" — both read as null.
/// The chat screen greets as soon as the voice *catalogue* arrives, which is
/// fast, while the saved choice is still coming off disk; with only a null to
/// go on it fell back to the first voice in the catalogue, so the opening line
/// was spoken by a stranger and only the second reply used the learner's own.
class VoiceSelection {
  const VoiceSelection._(this.id, this.isLoaded);

  /// Preferences have not answered yet — nothing may act on [id] in this state.
  const VoiceSelection.loading() : this._(null, false);

  /// Preferences answered: [id] is the saved voice, or null if none was saved.
  const VoiceSelection.resolved(String? id) : this._(id, true);

  /// The saved voice id, or null when none was chosen (or none loaded yet).
  final String? id;

  /// Whether persistence has answered. Callers that pick a default must wait
  /// for this, or they will pick one over a choice that was about to arrive.
  final bool isLoaded;
}

/// Persists the choice in `SharedPreferences`; `getInstance()` caches its
/// instance, so the repeated lookups here are cheap.
class VoiceController extends StateNotifier<VoiceSelection> {
  VoiceController() : super(const VoiceSelection.loading()) {
    _load();
  }

  static const String prefsKey = 'speaking.selected_voice';

  Future<void> _load() async {
    String? saved;
    try {
      saved = (await SharedPreferences.getInstance()).getString(prefsKey);
    } catch (_) {
      // Storage unavailable. Resolve anyway: holding the state at "loading"
      // would hold the opening line forever, which is worse than defaulting.
      saved = null;
    }
    if (!mounted) return;
    // Don't clobber a selection the learner made while prefs were loading —
    // but do mark the state resolved either way.
    state = VoiceSelection.resolved(state.id ?? saved);
  }

  /// Select [voiceId] and persist it.
  Future<void> select(String voiceId) async {
    state = VoiceSelection.resolved(voiceId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, voiceId);
  }
}
