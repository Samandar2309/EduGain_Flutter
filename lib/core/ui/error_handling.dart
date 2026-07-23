import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_exception.dart';
import 'tokens.dart';

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
    ).showSnackBar(SnackBar(content: Text(e.message)));
  }
}
