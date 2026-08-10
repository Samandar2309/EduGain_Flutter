import 'package:edugain/features/speaking/presentation/scenario_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `backdropFor` picks the artwork behind a free-talk session from keywords in
/// the topic the learner typed. It takes only `freeTopic` now — the older
/// slug/title/category parameters are gone with the scenario list they came
/// from, and track lessons carry a `backdropForKey` instead.
void main() {
  group('backdropFor', () {
    test('themes a free topic by keyword', () {
      expect(backdropFor(freeTopic: 'airport check-in').icon,
          Icons.flight_takeoff_rounded);
      expect(backdropFor(freeTopic: 'ordering coffee').icon,
          Icons.local_cafe_rounded);
      expect(backdropFor(freeTopic: 'job interview').icon, Icons.work_rounded);
    });

    test('matches case-insensitively', () {
      expect(
          backdropFor(freeTopic: 'HOTEL reception').icon, Icons.hotel_rounded);
    });

    test('falls back to the default theme when nothing matches', () {
      expect(backdropFor(freeTopic: 'quantum physics').icon,
          Icons.auto_awesome_rounded);
    });

    test('an empty topic is the default, not a crash', () {
      expect(backdropFor().icon, Icons.auto_awesome_rounded);
      expect(backdropFor(freeTopic: '').icon, Icons.auto_awesome_rounded);
    });
  });
}
