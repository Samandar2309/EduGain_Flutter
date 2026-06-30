import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the learner's chosen TTS voice id, persisted across sessions in
/// `SharedPreferences`. `null` means "not chosen yet" — callers fall back to
/// the first voice in the catalogue. Loads lazily on construction;
/// `SharedPreferences.getInstance()` caches its instance, so the repeated
/// lookups here are cheap.
class VoiceController extends StateNotifier<String?> {
  VoiceController() : super(null) {
    _load();
  }

  static const String prefsKey = 'speaking.selected_voice';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefsKey);
    // Don't clobber a selection the user made before prefs finished loading.
    if (saved != null && state == null) state = saved;
  }

  /// Select [voiceId] and persist it.
  Future<void> select(String voiceId) async {
    state = voiceId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, voiceId);
  }
}
