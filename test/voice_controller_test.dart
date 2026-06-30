import 'package:edugain/features/speaking/application/voice_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceController', () {
    test('starts null when nothing is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final c = VoiceController();
      await pumpEventQueue();
      expect(c.state, isNull);
    });

    test('loads a persisted voice on construction', () async {
      SharedPreferences.setMockInitialValues({
        VoiceController.prefsKey: 'hannah',
      });
      final c = VoiceController();
      await pumpEventQueue();
      expect(c.state, 'hannah');
    });

    test('select updates state and persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final c = VoiceController();
      await c.select('troy');
      expect(c.state, 'troy');

      // A fresh controller (next app launch) reads the persisted value back.
      final c2 = VoiceController();
      await pumpEventQueue();
      expect(c2.state, 'troy');
    });
  });
}
