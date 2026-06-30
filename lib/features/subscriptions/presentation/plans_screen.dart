import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../core/ui/error_handling.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

const _tierNames = {'entry': 'Entry', 'main': 'Main ⭐', 'pro': 'Pro'};

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  bool _busy = false;

  Future<void> _buy(Plan plan) async {
    final l = AppLocalizations.of(context);
    final provider = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.choosePayment),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded),
              title: const Text('Payme'),
              onTap: () => Navigator.pop(ctx, 'payme'),
            ),
            ListTile(
              leading: const Icon(Icons.payments_rounded),
              title: const Text('Click'),
              onTap: () => Navigator.pop(ctx, 'click'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (provider == null) return;
    await _checkout(plan, provider);
  }

  Future<void> _checkout(Plan plan, String provider) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final checkout = await ref
          .read(subscriptionsRepositoryProvider)
          .checkout(tier: plan.tier, period: plan.period, provider: provider);
      final launched = await launchUrl(
        Uri.parse(checkout.paymentUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (launched) {
        await _awaitPayment();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.paymentPageError)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _awaitPayment() {
    final l = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.finishPaymentTitle),
        content: Text(l.finishPaymentBody),
        actions: [
          FilledButton(
            onPressed: () {
              ref.invalidate(mySubscriptionProvider);
              Navigator.pop(ctx);
            },
            child: Text(l.check),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cancelSubscriptionTitle),
        content: Text(l.cancelSubscriptionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.yes),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(subscriptionsRepositoryProvider).cancel();
      ref.invalidate(mySubscriptionProvider);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider);
    final mine = ref.watch(mySubscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: Stack(
        children: [
          plans.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                Center(child: Text(AppLocalizations.of(context).loadFailed)),
            data: (list) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                mine.maybeWhen(
                  data: (sub) => _CurrentPlan(subscription: sub, onCancel: _cancel),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                ...list.map(
                  (p) => _PlanCard(
                    plan: p,
                    onBuy: _busy ? null : () => _buy(p),
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _CurrentPlan extends StatelessWidget {
  const _CurrentPlan({required this.subscription, required this.onCancel});

  final Subscription subscription;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.currentPlan, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    _tierNames[subscription.tier] ?? subscription.tier,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subscription.expiresAt != null)
                    Text(
                      l.validUntil(subscription.expiresAt!.split('T').first),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (subscription.isPaid && subscription.isActive)
              TextButton(onPressed: onCancel, child: Text(l.cancelAction)),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onBuy});

  final Plan plan;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tierNames[plan.tier] ?? plan.tier,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.pricePerMonth(formatUzs(plan.priceUzs)),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onBuy,
              child: Text(l.choosePlan),
            ),
          ],
        ),
      ),
    );
  }
}
