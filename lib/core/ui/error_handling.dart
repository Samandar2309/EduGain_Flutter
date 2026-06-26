import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/api_exception.dart';

/// Maps an [ApiException] to UX: a paywall dialog for 402, a snackbar otherwise.
void showApiError(BuildContext context, ApiException e) {
  if (e.statusCode == 402) {
    final cta = (e.paywall?['cta'] as String?) ?? 'Premium bilan davom eting';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Premium kontent'),
        content: Text(cta),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Yopish'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/subscriptions');
            },
            child: const Text('Premium'),
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
