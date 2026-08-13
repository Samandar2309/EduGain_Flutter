import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every door into a peer call must pass the microphone gate.
///
/// This exists because of a real fault, and a costly one. The gate was added to
/// the peer hub's three entry points and looked complete — but the busiest door
/// of all is the "live conversation" card on the HOME screen, and it pushed the
/// call route directly. Two learners met in a room where NEITHER had ever been
/// asked for a microphone: both negotiated receive-only, both told the other
/// "my microphone is off", and both concluded the app was broken.
///
/// It was reported as an iPhone-versus-Android connection fault. It was
/// neither: the Android side had no microphone either, because nothing had
/// asked for one. A platform theory cost hours; the actual cause was one
/// unguarded `context.push`.
///
/// A widget test cannot catch this — it can only prove the doors it knows
/// about. So this reads the source instead: any file that navigates to the
/// call route must also call `ensureMicrophoneReady`. Add a fourth door
/// tomorrow and forget the gate, and this fails before anybody ships it.
void main() {
  _deepLinkGuard();
  _redirectGuard();

  test('every file that opens a peer call also opens the microphone', () {
    const route = "'/peer/call'";
    // The call, not the name. Checking for the bare identifier passed while
    // the gate was deleted, because the comment explaining the gate mentions
    // it — a guard that its own documentation satisfies is not a guard. This
    // was caught by deleting the call and watching the test still go green.
    const gate = 'ensureMicrophoneReady(';

    final offenders = <String>[];
    var doorsFound = 0;

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = _withoutComments(entity.readAsStringSync());
      if (!source.contains(route)) continue;
      doorsFound++;
      if (!source.contains(gate)) {
        offenders.add(entity.path.replaceAll(r'\', '/'));
      }
    }

    // A guard that silently matches nothing is not a guard. If the route is
    // ever renamed, this fails loudly rather than passing forever.
    expect(
      doorsFound,
      greaterThan(0),
      reason: 'no file navigates to $route any more — has the route changed? '
          'If so, update this test, because it is now protecting nothing.',
    );

    expect(
      offenders,
      isEmpty,
      reason:
          'These files start a peer call without calling $gate first.\n'
          'A learner who reaches a call this way is never asked for a '
          'microphone: the handshake falls back to receive-only, the partner '
          'hears silence, and neither side is told why.\n'
          'Gate the tap — see peer_hub_screen.dart or home_screen.dart.',
    );
  });
}

/// The other way in, and the one the Dart scan above cannot see.
///
/// The bot's "Join the conversation" button is a URL built in Django, and it
/// pointed at `/peer/call`. Tapping it opened the Mini App directly in a live
/// search — no widget tap, therefore no gesture, therefore no microphone. The
/// guard above passed the whole time, because the offending string was Python.
///
/// A deep link can never satisfy the gate: the page has only just loaded and
/// has no activation to spend on a permission prompt. So no server-composed
/// link may aim at the call route at all.
void _deepLinkGuard() {
  test('no notification deep-links straight into a peer call', () {
    final live = File('../django_app/apps/notifications/live.py');
    if (!live.existsSync()) {
      markTestSkipped('django_app not present beside flutter_app');
      return;
    }
    final source = live
        .readAsStringSync()
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('#'))
        .join('\n');

    expect(
      source.contains('_deep_link("/peer/call")') ||
          source.contains("_deep_link('/peer/call')"),
      isFalse,
      reason:
          'A notification button links straight into a peer call. Opening the '
          'app from a URL gives the page no user gesture, so the microphone '
          'can never be requested and the learner arrives unable to speak.\n'
          'Link to "/peer" instead — the hub button is a real tap and it opens '
          'the microphone first.',
    );
  });
}

/// Source with comments removed, so prose about the gate cannot stand in for
/// the gate. Doc comments in this codebase are long and frequently name the
/// very identifiers being searched for.
String _withoutComments(String source) {
  // Block comments first: they can span the line-comment stripping below.
  final withoutBlocks = source.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );
  return withoutBlocks
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

/// The router's own refusal, exercised rather than assumed.
///
/// `state.extra` is the proof that a tap — and therefore the microphone gate —
/// came first. A URL cannot carry one, so a deep link must land on the hub
/// instead of in a live search.
void _redirectGuard() {
  // Where each live-call route must send an arrival that carries no `extra`.
  const cases = {
    "path: 'call'": '/peer',
    "path: 'call/:code'": '/speaking/group',
  };

  cases.forEach((marker, destination) {
    test('$marker refuses to open without proof of a tap', () {
      final router = File('lib/core/router.dart').readAsStringSync();
      final start = router.indexOf(marker);
      expect(start, greaterThan(-1), reason: 'route $marker is gone');
      // A slice long enough to hold the route's own body. The exact end
      // matters less than the redirect being inside it.
      final end = (start + 1600).clamp(0, router.length);
      final slice = router.substring(start, end);
      expect(
        slice.contains('redirect:') && slice.contains(destination),
        isTrue,
        reason:
            'This route no longer redirects to $destination when `extra` is '
            'null. A notification URL, or a browser reload, would drop the '
            'learner into a live call with no microphone.',
      );
    });
  });
}
