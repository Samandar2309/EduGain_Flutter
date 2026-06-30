import 'package:edugain/features/speaking/data/sse.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSseEvent', () {
    test('parses a chunk event', () {
      final event = parseSseEvent('event: chunk\ndata: {"text": "Hello"}');
      expect(event, isA<ChunkEvent>());
      expect((event! as ChunkEvent).text, 'Hello');
    });

    test('parses a done event with the session', () {
      final event = parseSseEvent(
        'event: done\n'
        'data: {"session": {"id": "s1", "status": "active", '
        '"turn_count": 3, "max_turns": 6, "quota_remaining": 0}, '
        '"usage": {"input_tokens": 1, "output_tokens": 2}}',
      );
      expect(event, isA<DoneEvent>());
      final session = (event! as DoneEvent).session;
      expect(session.id, 's1');
      expect(session.turnCount, 3);
      expect(session.turnsLeft, 3);
    });

    test('parses a coaching event', () {
      final event = parseSseEvent(
        'event: coaching\n'
        'data: {"coaching": {"understood": "I understood you.", '
        '"has_errors": true, "correction": "I went to the market yesterday.", '
        '"natural_version": "", "grammar_point": "Past Simple", '
        '"vocabulary": ["groceries", "cashier"], "pronunciation": ["yesterday"], '
        '"error_tags": ["past_simple"], "emotion": "encouraging"}}',
      );
      expect(event, isA<CoachingEvent>());
      final c = (event! as CoachingEvent).coaching;
      expect(c.correction, 'I went to the market yesterday.');
      expect(c.grammarPoint, 'Past Simple');
      expect(c.vocabulary, ['groceries', 'cashier']);
      expect(c.errorTags, ['past_simple']);
      expect(c.emotion, 'encouraging');
      expect(c.hasErrors, isTrue);
    });

    test('parses a transcript event (audio turn)', () {
      final event = parseSseEvent(
        'event: transcript\ndata: {"text": "table for two"}',
      );
      expect(event, isA<TranscriptEvent>());
      expect((event! as TranscriptEvent).text, 'table for two');
    });

    test('parses an error event', () {
      final event = parseSseEvent(
        'event: error\ndata: {"code": "AI_UNAVAILABLE", "message": "down"}',
      );
      expect(event, isA<StreamErrorEvent>());
      expect((event! as StreamErrorEvent).code, 'AI_UNAVAILABLE');
    });

    test('returns null for unknown or malformed blocks', () {
      expect(parseSseEvent('event: heartbeat\ndata: {}'), isNull);
      expect(parseSseEvent(': comment only'), isNull);
      expect(parseSseEvent('event: chunk\ndata: not-json'), isNull);
    });
  });
}
