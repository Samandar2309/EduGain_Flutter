import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

// Product tier names (the pricing table): entry=Beginner, main=Standart, pro=Pro.
const _tierNames = {'entry': 'Beginner', 'main': 'Standart', 'pro': 'Pro'};
const _popularTier = 'main';

/// The Premium paywall: a brand hero that sells the outcome, then the three
/// plans as clean cards — the popular one visually committed to (accent
/// border, badge, filled CTA), the others quieter.
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            0,
            AppSpace.lg,
            AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.choosePayment,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              _PaymentOption(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Payme',
                color: const Color(0xFF00CCCC),
                onTap: () => Navigator.pop(ctx, 'payme'),
              ),
              const SizedBox(height: AppSpace.md),
              _PaymentOption(
                icon: Icons.payments_rounded,
                label: 'Click',
                color: const Color(0xFF0073FF),
                onTap: () => Navigator.pop(ctx, 'click'),
              ),
            ],
          ),
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
    final l = AppLocalizations.of(context);
    final plans = ref.watch(plansProvider);
    final mine = ref.watch(mySubscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: AppColors.canvas,
      ),
      body: Stack(
        children: [
          plans.when(
            loading: () => const AppLoader(),
            error: (_, _) => Center(child: Text(l.loadFailed)),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
                AppSpace.xxl,
              ),
              children: [
                const _PremiumHero(),
                const SizedBox(height: AppSpace.lg),
                mine.maybeWhen(
                  data: (sub) => sub.isPaid
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.lg),
                          child: _CurrentPlan(
                            subscription: sub,
                            onCancel: _cancel,
                          ),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
                ...list.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.lg),
                    child: _PlanCard(
                      plan: p,
                      isPopular: p.tier == _popularTier,
                      onBuy: _busy ? null : () => _buy(p),
                    ),
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

/// The paywall hero: sells the outcome, not the feature list.
class _PremiumHero extends StatelessWidget {
  const _PremiumHero();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadow.glow(AppColors.brand),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.premiumHeroTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.premiumHeroBody,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
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
    final l = AppLocalizations.of(context);
    return AppCard(
      color: AppColors.brandTint,
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.brandDeep),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.currentPlan,
                  style: const TextStyle(
                    color: AppColors.brandDeep,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _tierNames[subscription.tier] ?? subscription.tier,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (subscription.expiresAt != null)
                  Text(
                    l.validUntil(subscription.expiresAt!.split('T').first),
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (subscription.isPaid && subscription.isActive)
            TextButton(onPressed: onCancel, child: Text(l.cancelAction)),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isPopular,
    required this.onBuy,
  });

  final Plan plan;
  final bool isPopular;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.xl),
          border: isPopular
              ? Border.all(color: AppColors.brand, width: 1.6)
              : Border.all(color: AppColors.line),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tierNames[plan.tier] ?? plan.tier,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.pricePerMonth(formatUzs(plan.priceUzs)),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.brandDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              ...plan.features.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(fontSize: 13.5, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                width: double.infinity,
                child: isPopular
                    ? FilledButton(
                        onPressed: onBuy,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        child: Text(l.choosePlan),
                      )
                    : OutlinedButton(
                        onPressed: onBuy,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          foregroundColor: AppColors.brandDark,
                          side: const BorderSide(color: AppColors.brand),
                        ),
                        child: Text(l.choosePlan),
                      ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -11,
            right: AppSpace.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppShadow.glow(AppColors.brand),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l.planPopular,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      onTap: onTap,
      border: Border.all(color: AppColors.line),
      child: Row(
        children: [
          IconChip(icon: icon, color: color, size: 40, iconSize: 20),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
