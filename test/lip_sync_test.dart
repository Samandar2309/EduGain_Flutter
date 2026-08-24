import 'package:edugain/features/speaking/data/lip_sync.dart';
import 'package:flutter_test/flutter_test.dart';

/// Putting the tutor's mouth on the words.
///
/// A device voice hands over no audio — the browser speaks it — so there is no
/// loudness envelope to follow, only the word boundaries the engine reports.
/// What was shipping instead was an oscillation driven by elapsed time alone:
/// it flapped at a steady rate whatever was being said, which is why it read as
/// a mouth moving *while* a voice played rather than a mouth saying the words.
///
/// The property that carries the whole effect is the SEAM: the mouth has to
/// close between words. A shape that never returns to zero is a flap however
/// well it is tuned.
void main() {
  group('the shape of one word', () {
    test('starts and ends closed, so words are separated', () {
      expect(lipLevelInWord(0, 5), closeTo(0, 0.001));
      expect(lipLevelInWord(1, 5), closeTo(0, 0.001));
    });

    test('opens in the middle', () {
      expect(lipLevelInWord(0.5, 5), greaterThan(0.5));
    });

    test('never leaves the range the avatar can draw', () {
      for (var chars = 1; chars <= 20; chars++) {
        for (var i = 0; i <= 40; i++) {
          final v = lipLevelInWord(i / 40, chars);
          expect(v, inInclusiveRange(0.0, 1.0), reason: '$chars chars at $i');
        }
      }
    });

    test('a long word moves more than once', () {
      // One arch over "extraordinary" would be a single slow gape. Counting the
      // times the opening changes direction is how "more than one movement"
      // can be asserted without pinning the exact curve.
      var turns = 0;
      var previous = lipLevelInWord(0, 13);
      var rising = true;
      for (var i = 1; i <= 100; i++) {
        final v = lipLevelInWord(i / 100, 13);
        final nowRising = v > previous;
        if (nowRising != rising) turns++;
        rising = nowRising;
        previous = v;
      }
      expect(turns, greaterThan(2));
    });

    test('progress outside the word is clamped, not wrapped', () {
      // A boundary that arrives late must not send the mouth back through the
      // arch — that would open it again in the silence after the word.
      expect(lipLevelInWord(1.7, 5), closeTo(0, 0.001));
      expect(lipLevelInWord(-0.4, 5), closeTo(0, 0.001));
    });
  });

  group('how long a word lasts', () {
    test('a longer word lasts longer', () {
      expect(
        wordDuration(12) > wordDuration(4),
        isTrue,
      );
    });

    test('speaking faster shortens it', () {
      expect(wordDuration(6, rate: 1.5) < wordDuration(6, rate: 1.0), isTrue);
    });

    test('an ordinary word lands in the right ballpark', () {
      // Six characters at rate 1.0 is a bit under half a second. Wrong by a
      // factor of two would be visible; wrong by 20% would not.
      final ms = wordDuration(6).inMilliseconds;
      expect(ms, inInclusiveRange(300, 500));
    });

    test('nonsense input cannot stop the clock', () {
      // A zero-length span would divide by zero in the ticker.
      expect(wordDuration(0).inMicroseconds, greaterThan(0));
      expect(wordDuration(-3).inMicroseconds, greaterThan(0));
      expect(wordDuration(5, rate: 0).inMicroseconds, greaterThan(0));
      expect(wordDuration(5, rate: -2).inMicroseconds, greaterThan(0));
    });
  });

  group('finding the word the engine is on', () {
    const line = 'Hello there, how are you today?';

    test('measures from the text, not from the event', () {
      // `charLength` is in the spec and missing from several engines. Measuring
      // it here is the difference between always right and sometimes right.
      expect(wordLengthAt(line, 0), 5); // Hello
      expect(wordLengthAt(line, 6), 6); // there,
      expect(wordLengthAt(line, 13), 3); // how
    });

    test('the last word has no trailing space to find', () {
      expect(wordLengthAt(line, 25), 6); // today?
    });

    test('an index off the end falls back rather than throwing', () {
      expect(wordLengthAt(line, 9999), greaterThan(0));
      expect(wordLengthAt(line, -1), greaterThan(0));
      expect(wordLengthAt('', 0), greaterThan(0));
    });

    test('a newline separates words as surely as a space', () {
      expect(wordLengthAt('one\ntwo', 0), 3);
    });
  });
}
