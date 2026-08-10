import 'package:edugain/features/speaking/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Walking back into an interrupted conversation.
///
/// A session lives on the server, so it outlives the app being killed — which
/// in a Telegram Mini App happens constantly. Nothing used to look for it, so
/// the next session silently abandoned the old one along with the speaking
/// minutes already spent on it.
void main() {
  Map<String, dynamic> homeJson({Object? active}) => {
        'cefr_level': 'B1',
        'active_session': active,
        'continue_lesson': null,
        'daily_mission': null,
        'recommended_track': 'daily',
        'recommended_lesson': null,
        'tracks': <dynamic>[],
        'progress_summary': {'lessons_done': 0, 'lessons_total': 10},
      };

  Map<String, dynamic> activeJson({int turns = 4}) => {
        'session': {
          'id': 'sess-1',
          'status': 'active',
          'turn_count': turns,
          'max_turns': 20,
          'cefr_level': 'B1',
        },
        'last_message': {
          'id': 'msg-9',
          'role': 'assistant',
          'content': 'So what did you do at the weekend?',
          'created_at': '2026-07-28T10:00:00Z',
        },
        'title': 'Weekend plans',
        'backdrop': 'university',
      };

  test('no open conversation means no card', () {
    final home = SpeakingHome.fromJson(homeJson());
    expect(home.activeSession, isNull);
  });

  test('an open conversation is parsed with the tutor line to resume on', () {
    final home = SpeakingHome.fromJson(homeJson(active: activeJson()));
    final resume = home.activeSession;

    expect(resume, isNotNull);
    expect(resume!.session.id, 'sess-1');
    expect(resume.session.turnCount, 4);
    expect(resume.title, 'Weekend plans');
    // The last thing the tutor said: without it the learner resumes into a
    // blank screen with no idea what they were answering.
    expect(resume.lastMessage.content, 'So what did you do at the weekend?');
  });

  test('resuming rebuilds exactly what the chat screen expects', () {
    final resume =
        SpeakingHome.fromJson(homeJson(active: activeJson())).activeSession!;
    final launch = resume.toLaunch();

    expect(launch.started.session.id, 'sess-1');
    // The screen speaks `firstMessage` on open — on a resume that is the line
    // the learner left hanging, which is what puts them back in context.
    expect(launch.started.firstMessage.content, resume.lastMessage.content);
    // And the scene comes back as it was, not as a default.
    expect(launch.backdropKey, 'university');
    expect(launch.title, 'Weekend plans');
  });

  test('a session with no theme resumes without inventing one', () {
    final json = activeJson()
      ..['backdrop'] = ''
      ..['title'] = '';
    final launch =
        SpeakingHome.fromJson(homeJson(active: json)).activeSession!.toLaunch();

    // Empty strings would theme the scene as a backdrop literally named "" —
    // null lets the screen fall back deliberately.
    expect(launch.backdropKey, isNull);
    expect(launch.title, isNull);
  });

  test('a free-topic conversation keeps its topic as the title', () {
    final json = activeJson()..['title'] = 'My trip to Samarkand';
    final resume = SpeakingHome.fromJson(homeJson(active: json)).activeSession!;
    expect(resume.toLaunch().title, 'My trip to Samarkand');
  });
}
