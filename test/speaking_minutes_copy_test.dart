import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edugain/core/api/api_exception.dart';
import 'package:edugain/core/ui/error_handling.dart';
import 'package:edugain/l10n/app_localizations.dart';

/// The sentence a learner reads when the day's ten minutes are gone.
///
/// This is the one refusal they will actually meet, and the backend sends it in
/// English — the quota errors have no translation layer behind them. So the
/// client has to answer with its own copy, or a Russian or Uzbek learner gets
/// told "Today's conversation time is used up" at the exact moment they are
/// being turned away.
///
/// The link is `details.scope`, which `session_clock.tick` sets to
/// `daily_minutes`. That is the contract this test pins.
void main() {
  ApiException outOfMinutes() => const ApiException(
    code: 'QUOTA_EXCEEDED',
    message: "Today's conversation time is used up",
    details: {'scope': 'daily_minutes', 'resource': 'speaking_seconds'},
    statusCode: 402,
  );

  Future<AppLocalizations> load(String code) =>
      AppLocalizations.delegate.load(Locale(code));

  testWidgets('the day-is-spent message is shown in the learner language', (
    tester,
  ) async {
    for (final code in ['en', 'ru', 'uz']) {
      final l = await load(code);
      final shown = outOfMinutes().localized(l);
      expect(
        shown,
        l.quotaExhausted,
        reason: 'the $code learner must read our sentence, not the server\'s',
      );
      expect(
        shown,
        isNot(outOfMinutes().message),
        reason: 'the English fallback must not survive into $code',
      );
    }
  });

  testWidgets('a quota refusal we have no copy for keeps the server text', (
    tester,
  ) async {
    // The service-wide ceiling is a different situation with a different
    // answer ("come back tomorrow", no upgrade to sell), and it has no client
    // copy — so the server's wording must still come through rather than being
    // swallowed by a catch-all.
    const global = ApiException(
      code: 'QUOTA_EXCEEDED',
      message: "The service has reached today's conversation limit",
      details: {'scope': 'global'},
      statusCode: 402,
    );
    final l = await load('uz');
    expect(global.localized(l), global.message);
  });
}
