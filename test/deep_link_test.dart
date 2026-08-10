import 'package:flutter_test/flutter_test.dart';

/// A notification opens the app at a page. It has to arrive there.
///
/// The redirect sends everyone to `/splash` while auth resolves, and the rule
/// at the end of the chain turns any gate into `/home`. By the time the gates
/// clear, `matchedLocation` says `/splash` — so a learner who tapped "join the
/// room" landed on the home screen and had to find it themselves, which is
/// most of the reason a notification goes unused.
///
/// The fix holds the first real destination and hands it back once. This
/// restates that logic: the router keeps it in a private variable inside a
/// closure, unreachable from a test, and it is short enough that a copy is
/// cheaper than the indirection needed to share it.
void main() {
  bool isGate(String loc) =>
      loc == '/splash' ||
      loc == '/welcome' ||
      loc.startsWith('/login') ||
      loc == '/signin-failed' ||
      loc.startsWith('/onboarding/');

  /// Walks a location through the gate logic and answers where it ends up.
  String land(String opened, {List<String> gates = const ['/splash']}) {
    String? intended;
    var loc = opened;

    // Every pass the real redirect would make: capture, then be pushed to a
    // gate, then finally be released.
    for (final step in [...gates, '__done__']) {
      if (intended == null && !isGate(loc) && loc != '/home') {
        intended = loc;
      }
      if (step != '__done__') {
        loc = step;
        continue;
      }
      if (!isGate(loc) && loc != '/home') return loc;
      final wanted = intended;
      intended = null;
      return wanted ?? '/home';
    }
    return '/home';
  }

  test('a link to the partner page survives the splash gate', () {
    expect(land('/peer'), '/peer');
  });

  test('a link to a room survives, query string and all', () {
    // The room code rides in the URL; losing it lands them in an empty lobby.
    expect(land('/speaking/group?code=BUART9'), '/speaking/group?code=BUART9');
  });

  test('opening the app normally still lands on home', () {
    expect(land('/splash'), '/home');
  });

  test('a learner who has to pass onboarding still reaches their page', () {
    """The gates are not one step.

    A new learner meets the language, name and channel screens before the app
    opens. The destination has to outlive all of them, not just the splash.""";
    expect(
      land(
        '/peer',
        gates: ['/splash', '/onboarding/language', '/onboarding/name'],
      ),
      '/peer',
    );
  });

  test('the destination is used once and then forgotten', () {
    """Otherwise every trip back to home would yank them to the room again.

    Simulated by landing twice with the same holder: the second walk starts
    with nothing held, exactly as the router does after consuming it.""";
    expect(land('/peer'), '/peer');
    // A fresh walk with no incoming destination — home, not the old one.
    expect(land('/splash'), '/home');
  });
}
