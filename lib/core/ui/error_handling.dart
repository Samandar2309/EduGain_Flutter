import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_exception.dart';
import 'tokens.dart';

extension ApiExceptionText on ApiException {
  /// What to show the learner.
  ///
  /// Codes the client raises itself have no server-provided text, so they are
  /// translated here. Everything else keeps the backend's message, which is
  /// already written in the learner's language (it answers `Accept-Language`).
  String localized(AppLocalizations l) => switch (code) {
    'NETWORK_ERROR' => l.networkError,
    // Running out of the day's speaking minutes is the one refusal a learner
    // meets often, and the server sends it in English — the quota messages have
    // no translation layer behind them. We already have this sentence in all
    // three languages, so use ours rather than showing a Russian or Uzbek
    // learner an English one at the exact moment they are being told no.
    'QUOTA_EXCEEDED' when details['scope'] == 'daily_minutes' => l.quotaExhausted,
    _ => message,
  };
}

/// Maps an [ApiException] to UX: a premium paywall sheet for 402, a snackbar
/// otherwise.
void showApiError(BuildContext context, ApiException e) {
  final l = AppLocalizations.of(context);
  if (e.statusCode == 402) {
    final cta = (e.paywall?['cta'] as String?) ?? l.paywallCtaDefault;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxl,
            0,
            AppSpace.xxl,
            AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  shape: BoxShape.circle,
                  boxShadow: AppShadow.glow(AppColors.brand),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                l.premiumContent,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                cta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/subscriptions');
                  },
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(l.premiumButton),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.close),
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.localized(l))));
  }
}
