import 'package:edugain/features/speaking/data/device_tts.dart';
import 'package:edugain/features/speaking/data/voice_gender.dart';
import 'package:flutter_test/flutter_test.dart';

/// Naming a voice's gender from a string the engine never meant as one.
///
/// The Web Speech API does not report gender at all, so the app reads it off
/// the name — and the picker now shows men only, because the tutor has a boy's
/// face. That makes the guess load-bearing: a mislabelled voice is one the
/// learner is either wrongly offered or wrongly denied.
void main() {
  group("Apple's roster, which is what an iPhone actually offers", () {
    // The tutor sounded like a different product on iOS, and this is why: the
    // picker could not name Apple's voices, so it ranked them below ones it
    // could and settled on a novelty voice from the nineties.
    test('its male voices are recognised, not guessed at', () {
      for (final n in ['Evan', 'Rishi', 'Gordon', 'Reed', 'Rocko', 'Aaron']) {
        expect(guessGender(n), 'male', reason: n);
      }
    });

    test('its female voices are still recognised', () {
      for (final n in ['Samantha', 'Allison', 'Serena', 'Nicky', 'Moira']) {
        expect(guessGender(n), 'female', reason: n);
      }
    });

    test('the suffix does not confuse the name', () {
      expect(guessGender('Evan (Enhanced)'), 'male');
      expect(guessGender('Samantha (Premium)'), 'female');
    });
  });


  group('guessGender', () {
    test('reads the marker Android writes into the name', () {
      // `en-us-x-sfg#male_1-local` — the engine says it outright.
      expect(guessGender('en-us-x-sfg#male_1-local'), 'male');
      expect(guessGender('en-us-x-sfg#female_2-local'), 'female');
    });

    test('"female" is not a man, though it contains "male"', () {
      // The trap this function exists around. A naive substring test labels
      // every Microsoft female voice a man, and the picker — which now shows
      // men only — would offer exactly the voices it means to exclude.
      expect(guessGender('Microsoft Zira - English (United States) (Female)'),
          'female');
      expect(guessGender('Google UK English Female'), 'female');
    });

    test('a man is still a man', () {
      expect(guessGender('Microsoft David - English (United States)'), 'male');
      expect(guessGender('Google UK English Male'), 'male');
      expect(guessGender('Daniel'), 'male');
      expect(guessGender('Alex'), 'male');
    });

    test('a name that says nothing is left unlabelled, not guessed', () {
      // Plenty of handsets ship exactly this. Guessing here would either hide
      // a usable voice or promise a gender the learner does not hear.
      expect(guessGender('English (United States)'), '');
      expect(guessGender('default'), '');
    });
  });

  group('DeviceTtsPlatform on a build with no speech engine', () {
    test('reports itself unsupported and offers nothing', () {
      // The stub is what native builds compile against. Everything must be
      // safe to call and simply empty — never a crash on a platform that has
      // no browser.
      expect(DeviceTtsPlatform.supported, isFalse);
      expect(DeviceTtsPlatform.voices(), isEmpty);
      expect(DeviceTtsPlatform.voiceName, isEmpty);
      DeviceTtsPlatform.select('anything');
      DeviceTtsPlatform.stop();
    });

    test('speaking resolves rather than hanging the turn', () async {
      // The drain awaits this. A future that never completed would leave the
      // tutor "speaking" for ever and the microphone shut.
      await DeviceTtsPlatform.speak('Hello there.');
    });
  });
}
