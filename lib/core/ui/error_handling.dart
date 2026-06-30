import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_exception.dart';

/// Maps an [ApiException] to UX: a paywall dialog for 402, a snackbar otherwise.
void showApiError(BuildContext context, ApiException e) {
  final l = AppLocalizations.of(context);
  if (e.statusCode == 402) {
    final cta = (e.paywall?['cta'] as String?) ?? l.paywallCtaDefault;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.premiumContent),
        content: Text(cta),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.close),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/subscriptions');
            },
            child: Text(l.premiumButton),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message)));
  }
}
