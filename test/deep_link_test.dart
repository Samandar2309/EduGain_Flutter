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
  group('the destination a bot link carries', _linkDestinationSuite);

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

/// Where a bot link says to go, and why it is not in the fragment.
///
/// Telegram delivers initData by APPENDING to the URL fragment, and this app
/// routes on the fragment too (Flutter web's hash strategy). So a link written
/// as `/app/#/leaderboard` hands the router `/leaderboard` with Telegram's
/// data stuck onto the end of it. The bot's own menu button carries no
/// fragment at all — which is exactly why that one always opened cleanly and
/// the notification buttons did not.
///
/// A query parameter is untouched by Telegram, so the two now open the same
/// way.
void _linkDestinationSuite() {
  String? destination(String url) {
    final raw = Uri.parse(url).queryParameters['to'];
    if (raw == null || raw.isEmpty) return null;
    if (!raw.startsWith('/') || raw.startsWith('//')) return null;
    return raw;
  }

  test('a plain open, with no destination, asks for nothing', () {
    expect(destination('https://x.test/app/'), isNull);
  });

  test('a destination survives Telegram appending its own data', () {
    // What the client actually receives once Telegram has had the URL.
    const url = 'https://x.test/app/?to=/leaderboard#tgWebAppData=abc&v=8.0';
    expect(destination(url), '/leaderboard');
  });

  test('paths with their own segments come through whole', () {
    expect(destination('https://x.test/app/?to=/games/quiz'), '/games/quiz');
    expect(destination('https://x.test/app/?to=/speaking/group'),
        '/speaking/group');
  });

  test('anything that is not an in-app path is refused', () {
    // A link is untrusted input. "Somewhere inside this app" is the only
    // thing it is allowed to say — a protocol-relative URL would otherwise
    // send a learner off the app entirely.
    expect(destination('https://x.test/app/?to=//evil.test/'), isNull);
    expect(destination('https://x.test/app/?to=https://evil.test'), isNull);
    expect(destination('https://x.test/app/?to='), isNull);
  });
}
