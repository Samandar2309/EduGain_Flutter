import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/telegram_webapp.dart';
import '../domain/models.dart';

/// Sends what learners tell us to the server.
class FeedbackRepository {
  FeedbackRepository(this._api);

  final ApiClient _api;

  /// Anything a learner writes us — one box, whatever it is about.
  Future<void> report({required String message, required String locale}) =>
      _api.post(
        '/feedback',
        body: {
          'kind': FeedbackKind.message.code,
          'message': message,
          'context': diagnostics(locale),
        },
      );

  /// One tap at the end of a session: [stars] is 1–5, [comment] optional.
  ///
  /// Called twice in the common case — once the instant a star is tapped, and
  /// again if a comment follows. The server upserts on (learner, session), so
  /// the second call updates the first vote rather than adding one.
  Future<void> rateSession({
    required String sessionId,
    required int stars,
    required String locale,
    String comment = '',
  }) => _api.post(
    '/feedback',
    body: {
      'kind': FeedbackKind.session.code,
      'session_id': sessionId,
      'rating': stars,
      'message': comment,
      'context': diagnostics(locale),
    },
  );

  /// What triage would otherwise cost a round-trip to ask for.
  ///
  /// Nothing identifying beyond what the server already knows from the token —
  /// the point is to answer "which build, where, in what language" before
  /// anyone has to go and ask.
  static Map<String, dynamic> diagnostics(String locale) => {
    'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    'locale': locale,
    'telegram': TelegramWebApp.isTelegram,
  };
}
