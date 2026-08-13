import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/microphone_service.dart';
import '../../../core/providers.dart';
import '../../../core/telegram_webapp.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Open the microphone before a live call is allowed to start.
///
/// Every way into a peer call goes through here, and it must be called from
/// the tap itself — the whole reason this exists is that the microphone can
/// only be opened while the learner's gesture is still live. Asking later, once
/// a partner has been found, is what used to happen and is what did not work.
///
/// Returns true when there is a live microphone to publish. Returns false when
/// there is not, having already told the learner why — the caller's job is
/// simply to not proceed.
Future<bool> ensureMicrophoneReady(BuildContext context, WidgetRef ref) async {
  final mic = ref.read(microphoneServiceProvider);

  // Already holding a live microphone — a second call in the same visit asks
  // nothing and shows nothing.
  if (mic.hasLiveStream) return true;

  // What the platform WOULD do if we asked. Safe to await here, ahead of any
  // request: the real `getUserMedia` is fired by the primer's own button
  // below, which is a fresh gesture of its own.
  final permission = await mic.checkPermission();
  if (!context.mounted) return false;

  // Asking now would show no dialog and fail. Go straight to how to undo it.
  if (permission == MicPermission.denied) {
    await showMicProblem(context, MicFailure.blocked);
    return false;
  }

  // The system dialog is about to appear — in the phone's language, quoting a
  // hostname nobody recognises. Learners were meeting it cold and dismissing
  // it, and a dismissal is close to permanent because the browser then stops
  // asking. So it is explained first, in the language they chose, with the
  // button they need named.
  //
  // Skipped when permission is already granted: no dialog will appear, so
  // there is nothing to explain.
  if (permission != MicPermission.granted) {
    final go = await showMicPrimer(context);
    if (go != true || !context.mounted) return false;
  }

  while (true) {
    try {
      await mic.prepare();
      return true;
    } on MicException catch (e) {
      if (!context.mounted) return false;
      final retry = await showMicProblem(context, e.failure);
      if (!retry || !context.mounted) return false;
      // Round again. A learner who has just reopened the app should not have
      // to hunt for the button a second time.
    }
  }
}

/// The sheet shown immediately before the system permission dialog.
///
/// Its button is what triggers `getUserMedia`, so the request still originates
/// in a live user gesture — the priming makes the flow legible WITHOUT costing
/// the activation. That is the whole reason it is a sheet with a button rather
/// than a screen with a delay.
///
/// Public for the same reason as [showMicProblem]: the golden shots render the
/// real sheet, not a copy of it.
Future<bool?> showMicPrimer(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xl, AppSpace.md, AppSpace.xl, AppSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.speaking.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded,
                    color: AppColors.speaking, size: 30),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              l.micPrimerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              l.micPrimerBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            // A miniature of the dialog they are about to meet, with the right
            // button picked out. Nobody reads instructions about a thing they
            // have not seen — they recognise a shape.
            _DialogHint(
              allow: l.micPrimerAllowWord,
              block: l.micPrimerBlockWord,
            ),
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.speaking,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                l.micPrimerContinue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A miniature of the system dialog's buttons, with the right one lit.
class _DialogHint extends StatelessWidget {
  const _DialogHint({required this.allow, required this.block});

  final String allow;
  final String block;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          block,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.inkFaint,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.speaking,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: AppShadow.glow(AppColors.speaking),
          ),
          child: Text(
            allow,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        const Icon(Icons.arrow_back_rounded,
            size: 16, color: AppColors.speaking),
      ],
    ),
  );
}

/// What went wrong, in words, with a way forward.
///
/// Returns true when the learner wants another go. Public so the golden shots
/// render the real dialog rather than a copy of it — a screenshot of a
/// reimplementation proves nothing about what ships.
Future<bool> showMicProblem(BuildContext context, MicFailure failure) async {
  final l = AppLocalizations.of(context);
  // No exception names, no error codes. Each of these is an instruction the
  // learner can actually act on, which is the only reason the failures are
  // told apart at all.
  final body = switch (failure) {
    MicFailure.denied => l.micDeniedBody,
    // Two different worlds, two different instructions.
    //
    // Inside Telegram there is NO site-settings screen to send anyone to —
    // pointing at "browser settings" is advice that cannot be followed. But
    // Telegram does not persist the decision either: closing the app and
    // reopening genuinely brings the prompt back, which is the only recovery
    // that exists there and happens to be the easy one.
    MicFailure.blocked => TelegramWebApp.isTelegram
        ? l.micBlockedTelegramBody
        : l.micBlockedBrowserBody,
    MicFailure.notFound => l.micNotFoundBody,
    MicFailure.busy => l.micBusyBody,
    MicFailure.insecureContext => l.micInsecureBody,
    MicFailure.constraints => l.micConstraintsBody,
    MicFailure.unknown => l.micUnknownBody,
  };
  // Retry is offered only where pressing it can actually change the outcome.
  //
  // Inside Telegram a "blocked" microphone IS retryable — the decision is not
  // remembered across app launches, so reopening brings the prompt back. In a
  // real browser it is not: the origin is blocked until the learner changes it
  // in site settings, and a button that cannot work is worse than no button.
  final canRetry = switch (failure) {
    MicFailure.insecureContext => false,
    MicFailure.blocked => TelegramWebApp.isTelegram,
    _ => true,
  };

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: const Icon(Icons.mic_off_rounded, color: AppColors.danger, size: 30),
      title: Text(
        l.micNeededTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: Text(
        body,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.4,
          color: AppColors.inkSoft,
        ),
      ),
      // One stacked column rather than two loose actions. An `OverflowBar`
      // lays its children out side by side and only wraps when they do not
      // fit — so a full-width primary button pushed "close" onto its own row,
      // right-aligned under a centred dialog. Stacking both at full width is
      // the same shape the rest of the app uses for a primary/secondary pair.
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpace.xl, 0, AppSpace.xl, AppSpace.lg,
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRetry) ...[
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.speaking,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  l.micRetry,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
            ],
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.close),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}
