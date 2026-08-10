import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/ui/error_handling.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// Start a track lesson and open the immersive chat. Shared by the Speaking home
/// (continue / mission / recommended) and the track detail page, so any lesson
/// is always one tap from speaking. Surfaces errors via a snackbar and toggles
/// [onBusy] around the network call so the caller can show a spinner.
Future<void> launchLesson(
  BuildContext context,
  WidgetRef ref, {
  required String backdropKey,
  required String title,
  // Null starts an OPEN conversation: no lesson, no subject, so the tutor's
  // first line asks what the learner would like to talk about. Answering that
  // is itself the first piece of speaking practice — which is why the app must
  // not demand a topic through a form before letting them in.
  String? lessonKey,
  void Function(bool busy)? onBusy,
}) async {
  onBusy?.call(true);
  try {
    final started = await ref
        .read(speakingRepositoryProvider)
        .startSession(lessonKey: lessonKey);
    if (context.mounted) {
      await context.push(
        '/speaking/chat',
        extra: SpeakingLaunch(
          started: started,
          backdropKey: backdropKey,
          title: title,
        ),
      );
      // Back from the session: progress and today's minutes both moved.
      // (context.mounted guards ref too — both die with the caller's State.)
      if (context.mounted) {
        ref.invalidate(speakingHomeProvider);
        ref.invalidate(speakingQuotaProvider);
      }
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.localized(AppLocalizations.of(context))),
        ),
      );
    }
  } finally {
    onBusy?.call(false);
  }
}
