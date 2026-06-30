import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SentenceChunker', () {
    test('emits a sentence only once it is terminated', () {
      final c = SentenceChunker();
      expect(c.add('Hello'), isEmpty); // no terminator yet
      expect(c.add(' there.'), ['Hello there.']); // completes on '.'
    });

    test('splits multiple sentences in one delta', () {
      final c = SentenceChunker();
      expect(c.add('Hi! How are you? '), ['Hi!', 'How are you?']);
    });

    test('keeps the trailing partial until finish()', () {
      final c = SentenceChunker();
      expect(c.add('Great. And you'), ['Great.']);
      expect(c.add(''), isEmpty);
      expect(c.finish(), ['And you']); // flushed without a terminator
    });

    test('treats newlines as boundaries', () {
      final c = SentenceChunker();
      expect(c.add('Line one\nLine two\n'), ['Line one', 'Line two']);
    });

    test('finish on an empty buffer yields nothing', () {
      expect(SentenceChunker().finish(), isEmpty);
    });
  });
}
