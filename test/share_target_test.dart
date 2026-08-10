import 'package:edugain/core/share.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The invite link's shape, and the promise that tapping "invite" always does
/// *something*. The routing decision (Telegram's native sheet vs an external
/// launch) is verified on the device — but the URL it hands over is pure, and
/// getting it wrong silently sends an empty or broken invite.
void main() {
  group('telegram share link', () {
    Uri build(String text) => Uri.parse(
          'https://t.me/share/url?url=&text=${Uri.encodeComponent(text)}',
        );

    test('carries the invite text intact', () {
      final uri = build('Join me on EduGain! Code: ABC123');
      expect(uri.host, 't.me');
      expect(uri.path, '/share/url');
      expect(uri.queryParameters['text'], 'Join me on EduGain! Code: ABC123');
    });

    test('survives the punctuation real invites contain', () {
      // Uzbek apostrophes, an arrow and quotes all appear in the live strings;
      // an unencoded one would truncate the message at the first `&` or `#`.
      const text = 'EduGain’da qo‘shiling! Speaking → Guruh — “kod”: A1&B2#7';
      final uri = build(text);
      expect(uri.queryParameters['text'], text);
    });

    test('leaves the url parameter empty so the text is the whole message', () {
      // t.me/share renders `url` first; a stray value there would push the
      // invite text below a blank link.
      expect(build('hi').queryParameters['url'], '');
    });
  });

  group('shareInvite outcome', () {
    late List<String> clipboard;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      clipboard = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    // Off-web there is no Telegram bridge and no url_launcher plugin, so every
    // route out fails — exactly the state the button was stuck in. It must
    // still leave the learner holding the invite instead of doing nothing.
    test('falls back to the clipboard when nothing can be opened', () async {
      const text = 'Join me on EduGain! Code: ABC123';
      expect(await shareInvite(text), ShareOutcome.copied);
      expect(clipboard, [text]);
    });

    test('does not ask the server to prepare a share it cannot use', () async {
      // Outside a Mini App `shareMessage` does not exist, so spending a round
      // trip on `/invite/prepare` would be pure latency before the fallback.
      var prepared = false;
      await shareInvite('hi', prepare: () async {
        prepared = true;
        return 'prep-1';
      });
      expect(prepared, isFalse);
    });
  });
}
