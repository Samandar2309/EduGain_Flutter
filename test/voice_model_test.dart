import 'package:edugain/features/speaking/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Voice.fromJson', () {
    test('maps all fields', () {
      final v = Voice.fromJson({
        'id': 'troy',
        'name': 'Troy',
        'gender': 'male',
        'accent': 'American',
      });
      expect(v.id, 'troy');
      expect(v.name, 'Troy');
      expect(v.gender, 'male');
      expect(v.accent, 'American');
    });

    test('falls back to id for a missing name and blanks for the rest', () {
      final v = Voice.fromJson({'id': 'x'});
      expect(v.name, 'x');
      expect(v.gender, '');
      expect(v.accent, '');
    });
  });
}
