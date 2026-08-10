import 'package:edugain/core/api/api_client.dart';
import 'package:edugain/core/api/token_storage.dart';
import 'package:edugain/features/questions/data/question_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading the question bank off the wire.
///
/// This exists because of a live bug: the repository reached for `data['data']`
/// even though `ApiClient` already unwraps that envelope. The server answered
/// 200, the cast threw, and the learner was told "could not load the
/// questions" — an error that points squarely at the server for a fault that
/// was entirely on this side. Nothing in the type system objects, and nothing
/// in the server's own tests can catch it.
class _FakeApi extends ApiClient {
  _FakeApi(this.payload) : super(tokens: TokenStorage());

  /// What `ApiClient.get` really hands back: the CONTENTS of `data`, already
  /// unwrapped. Anything that shapes this differently is not testing the
  /// client we ship.
  final Map<String, dynamic> payload;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async => payload;
}

Map<String, dynamic> _serverShape() => {
  'parts': [
    {
      'id': 'part1',
      'title': 'Part 1',
      'subtitle': 'Short questions about you',
      'topics': [
        {
          'id': 'p1.work_study',
          'title': 'Work and studies',
          'question_count': 2,
          'is_new': false,
          'questions': ['Do you work, or are you a student?', 'And you?'],
          'cue_card': null,
          'follows': null,
          'follows_title': null,
          'worked': {
            'question': 'Do you work, or are you a student?',
            'weak': 'I am a student.',
            'strong': 'I am a student, in my second year.',
            'moves': ['Kept going'],
          },
          'has_worked': true,
        },
      ],
    },
    {
      'id': 'part2',
      'title': 'Part 2',
      'subtitle': 'Speak for two minutes from a card',
      'topics': [
        {
          'id': 'p2.gift_you_gave',
          'title': 'A gift you gave someone',
          'question_count': 0,
          'is_new': false,
          'questions': <String>[],
          'cue_card': {
            'prompt': 'Describe a gift you gave to someone.',
            'bullets': ['what the gift was', 'who you gave it to', 'why'],
            'closing': 'and explain how they reacted.',
            'prep_seconds': 60,
            'talk_seconds': 120,
          },
          'follows': null,
          'follows_title': null,
          'worked': null,
          'has_worked': false,
        },
      ],
    },
  ],
};

void main() {
  test('reads the bank from the shape the client actually receives', () async {
    final bank = await QuestionRepository(_FakeApi(_serverShape())).bank();

    expect(bank.length, 2);
    expect(bank[0].id, 'part1');
    expect(bank[0].topics.single.questions.length, 2);
  });

  test('carries the worked answer and its moves', () async {
    final bank = await QuestionRepository(_FakeApi(_serverShape())).bank();
    final topic = bank[0].topics.single;

    expect(topic.hasWorked, isTrue);
    expect(topic.worked, isNotNull);
    expect(topic.worked!.weak, 'I am a student.');
    expect(topic.worked!.moves, ['Kept going']);
  });

  test('a locked breakdown is still announced', () async {
    // The paid layer is advertised while unreadable: `worked` is null for a
    // free learner but `has_worked` stays true, so the row can say one exists.
    final payload = _serverShape();
    final topic = (payload['parts'] as List)[0]['topics'][0]
        as Map<String, dynamic>;
    topic['worked'] = null;

    final bank = await QuestionRepository(_FakeApi(payload)).bank();
    expect(bank[0].topics.single.worked, isNull);
    expect(bank[0].topics.single.hasWorked, isTrue);
  });

  test('reads a cue card as a card, not as questions', () async {
    final bank = await QuestionRepository(_FakeApi(_serverShape())).bank();
    final topic = bank[1].topics.single;

    expect(topic.isCueCard, isTrue);
    expect(topic.questions, isEmpty);
    expect(topic.cueCard!.bullets.length, 3);
    expect(topic.cueCard!.talkSeconds, 120);
  });

  test('an empty or unexpected payload yields nothing, never an exception', () async {
    // A learner mid-call must get an empty sheet at worst, never a crash.
    expect(await QuestionRepository(_FakeApi({})).bank(), isEmpty);
    expect(await QuestionRepository(_FakeApi({'parts': []})).bank(), isEmpty);
  });
}
