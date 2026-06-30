import 'package:edugain/features/speaking/presentation/scenario_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('backdropFor', () {
    test('themes known scenarios by keyword', () {
      expect(backdropFor(slug: 'airport-checkin').icon,
          Icons.flight_takeoff_rounded);
      expect(backdropFor(title: 'At the Coffee Shop').icon,
          Icons.local_cafe_rounded);
      expect(backdropFor(category: 'job interview').icon, Icons.work_rounded);
      expect(backdropFor(freeTopic: 'IELTS speaking part 1').icon,
          Icons.school_rounded);
    });

    test('matches case-insensitively across any field', () {
      expect(backdropFor(title: 'HOTEL Reception').icon, Icons.hotel_rounded);
    });

    test('falls back to the default theme when nothing matches', () {
      final b = backdropFor(freeTopic: 'quantum physics');
      expect(b.accent, const Color(0xFF6366F1));
      expect(b.icon, Icons.auto_awesome_rounded);
    });

    test('empty input yields the default', () {
      expect(backdropFor().icon, Icons.auto_awesome_rounded);
    });
  });
}
