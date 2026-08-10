import 'package:edugain/features/speaking/application/voice_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which voice the tutor speaks in, and — just as important — when we are
/// allowed to decide.
///
/// The bug this guards: the chat screen picks a default the moment it knows
/// which voices exist, but the learner's saved choice arrives separately, off
/// disk. With only a nullable id to go on it could not tell "still loading"
/// from "never chosen", so the opening line was spoken by the catalogue's first
/// voice and the learner's own only took over from the second reply.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceController', () {
    test('is not loaded until preferences answer', () {
      SharedPreferences.setMockInitialValues({});
      final c = VoiceController();
      // Synchronously after construction: nothing may default the voice yet.
      expect(c.state.isLoaded, isFalse);
      expect(c.state.id, isNull);
    });

    test('resolves with no voice when nothing is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final c = VoiceController();
      await pumpEventQueue();
      expect(c.state.isLoaded, isTrue, reason: 'the caller may now default');
      expect(c.state.id, isNull);
    });

    test('loads a persisted voice on construction', () async {
      SharedPreferences.setMockInitialValues({
        VoiceController.prefsKey: 'hannah',
      });
      final c = VoiceController();
      await pumpEventQueue();
      expect(c.state.isLoaded, isTrue);
      expect(c.state.id, 'hannah');
    });

    test('select updates state and persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final c = VoiceController();
      await c.select('troy');
      expect(c.state.id, 'troy');
      expect(c.state.isLoaded, isTrue);

      // A fresh controller (next app launch) reads the persisted value back.
      final c2 = VoiceController();
      await pumpEventQueue();
      expect(c2.state.id, 'troy');
    });

    test('a choice made while loading is not overwritten by the old one',
        () async {
      // The learner opens the picker before prefs have answered. The value
      // coming off disk is stale by then and must lose.
      SharedPreferences.setMockInitialValues({
        VoiceController.prefsKey: 'hannah',
      });
      final c = VoiceController();
      await c.select('troy');
      await pumpEventQueue();

      expect(c.state.id, 'troy');
      expect(c.state.isLoaded, isTrue);
    });
  });
}
