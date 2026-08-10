import 'package:edugain/features/group/data/group_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GroupTopic parses id/title/prompt with defaults', () {
    final t = GroupTopic.fromJson({'id': 'travel', 'title': 'Sayohat'});
    expect(t.id, 'travel');
    expect(t.title, 'Sayohat');
    expect(t.prompt, ''); // missing → empty
  });

  test('GroupRoom parses full/public flags and count/max', () {
    final room = GroupRoom.fromJson({
      'code': 'ABCDEF',
      'title': '',
      'topic': {'id': 'free', 'title': 'Erkin suhbat', 'prompt': ''},
      'level': 'B1',
      'host_name': 'Ali',
      'visibility': 'public',
      'count': 5,
      'max': 5,
      'status': 'live',
    });
    expect(room.code, 'ABCDEF');
    expect(room.isPublic, isTrue);
    expect(room.isFull, isTrue); // 5/5
    // empty title falls back to the topic title
    expect(room.title, 'Erkin suhbat');
  });

  test('GroupRoom private + not full', () {
    final room = GroupRoom.fromJson({
      'code': 'XYZ123',
      'title': 'Mening xonam',
      'topic': {'id': 'work', 'title': 'Ish'},
      'visibility': 'private',
      'count': 2,
      'max': 6,
    });
    expect(room.isPublic, isFalse);
    expect(room.isFull, isFalse);
    expect(room.title, 'Mening xonam'); // explicit title kept
  });
}
