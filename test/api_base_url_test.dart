import 'package:edugain/core/config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the app decides the backend lives.
///
/// This is worth pinning because getting it wrong is invisible from the server
/// side: every request goes to an unreachable host, so nothing appears in any
/// access log and the app just reports "network error". A Telegram Mini App
/// built without `--dart-define=API_BASE_URL` once shipped that way, pointing
/// real users at the Android emulator's loopback address.
void main() {
  test('the default is never an emulator or loopback address', () {
    // Tests run on the VM, so this exercises the non-web branch. The web branch
    // is relative by construction and asserted below.
    const forbidden = ['10.0.2.2', 'localhost', '127.0.0.1'];
    final base = AppConfig.apiBaseUrl;

    if (base.startsWith('/')) {
      // Relative — correct on any origin, nothing to check.
      return;
    }
    // A host-specific default is only acceptable for local native development;
    // if that ever becomes the WEB default again, the check above stops
    // short-circuiting and this fails.
    expect(
      forbidden.any(base.contains),
      isTrue,
      reason: 'the native dev default is expected to be a local address; '
          'anything else means the platform defaults were rewired',
    );
  });

  test('a relative base survives being parsed for the WebSocket URL', () {
    // The signaling clients do `Uri.parse(apiBaseUrl)` and then swap the scheme
    // to ws/wss. A relative base has no scheme, which is exactly the case they
    // resolve against the page origin — if parsing threw, live calls would die
    // at connect time rather than anywhere obvious.
    final uri = Uri.parse('/api/v1');
    expect(uri.hasScheme, isFalse);
    expect(uri.path, '/api/v1');

    final resolved = Uri.parse('https://example.test/app/').resolveUri(uri);
    expect(resolved.scheme, 'https');
    expect(resolved.host, 'example.test');
    expect(resolved.path, '/api/v1');
  });
}
