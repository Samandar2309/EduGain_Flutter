import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Games make no sound. Hearing a word is something you ask for.
///
/// Every answer used to land a chime and then read the word aloud a third of a
/// second later. Nobody playing on a bus could stop it, and the pronunciation
/// arrived while the learner was already reading the next question — the moment
/// it teaches least.
///
/// Written as a source check rather than a widget test because the fault would
/// be a line somebody adds back, not a state a rendered screen can be put into:
/// audio in a widget test is a no-op plugin, so a game that chimed would pass
/// every other test in this suite.
void main() {
  final games = [
    'vocab_game_screen.dart',
    'vocab_duel_screen.dart',
    'spell_game_screen.dart',
  ];

  test('no game screen plays a sound', () {
    for (final name in games) {
      final source = File(
        'lib/features/vocabulary/presentation/$name',
      ).readAsStringSync();
      for (final noise in ['pronouncerProvider', 'vocabSfxProvider', 'sfx.']) {
        expect(
          source.contains(noise),
          isFalse,
          reason: '$name should not reach for $noise — games are silent',
        );
      }
    }
  });

  test('the word list is the one place that speaks, and only on a tap', () {
    final source = File(
      'lib/features/vocabulary/presentation/words_to_learn_screen.dart',
    ).readAsStringSync();

    expect(source.contains('pronouncerProvider'), isTrue);
    // Behind an onTap, never on a timer: the distinction between "the learner
    // asked" and "the app decided" is the whole point.
    expect(source.contains('onTap:'), isTrue);
    expect(
      source.contains('Future.delayed'),
      isFalse,
      reason: 'speaking on a delay is the app deciding, not the learner',
    );
  });

  test('the sound-effect assets are gone with the code that played them', () {
    expect(Directory('assets/sfx').existsSync(), isFalse);
    expect(
      File('pubspec.yaml').readAsStringSync().contains('assets/sfx'),
      isFalse,
      reason: 'a declared asset folder that does not exist fails the build',
    );
  });
}
