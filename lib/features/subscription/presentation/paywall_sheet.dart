import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../application/paywall_controller.dart';
import '../application/subscription_providers.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_repository.dart';

Future<bool> showPaywall(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PaywallSheet(),
  );
  return container.read(entitlementProvider).isPremium;
}

class PaywallSheet extends ConsumerWidget {
  const PaywallSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(subscriptionPlansProvider);
    final paywall = ref.watch(paywallControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    ref.listen(entitlementProvider, (previous, next) {
      if (next.isPremium && !(previous?.isPremium ?? false)) {
        Navigator.of(context).pop();
      }
    });

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.workspace_premium,
              size: 56,
              color: AppColors.gold,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.paywallTitle,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.paywallSubtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            const _PromoCountdown(),
            const SizedBox(height: 16),
            for (final benefit in AppStrings.paywallBenefits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(benefit)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            plans.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const _Message(AppStrings.storeUnavailable),
              data: (items) => items.isEmpty
                  ? const _Message(AppStrings.noPlans)
                  : Column(
                      children: [
                        for (final plan in items)
                          _PlanTile(
                            plan: plan,
                            isProcessing: paywall.processingPlanId == plan.id,
                            enabled: !paywall.isBusy,
                            onTap: () => _purchase(context, ref, plan),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⭐⭐⭐⭐⭐  ${AppStrings.socialProof}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            TextButton(
              onPressed: paywall.isBusy
                  ? null
                  : () async {
                      await ref
                          .read(paywallControllerProvider.notifier)
                          .restore();
                      if (context.mounted) {
                        _snack(context, AppStrings.restoreDone);
                      }
                    },
              child: paywall.isRestoring
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.restore),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref
        .read(paywallControllerProvider.notifier)
        .purchase(plan.id);
    final message = switch (outcome) {
      PurchaseOutcome.success => null,
      PurchaseOutcome.pending => AppStrings.purchasePending,
      PurchaseOutcome.cancelled => AppStrings.purchaseCancelled,
      PurchaseOutcome.failed => AppStrings.purchaseFailed,
      PurchaseOutcome.storeUnavailable => AppStrings.storeUnavailable,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _snack(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _PromoCountdown extends StatefulWidget {
  const _PromoCountdown();

  @override
  State<_PromoCountdown> createState() => _PromoCountdownState();
}

class _PromoCountdownState extends State<_PromoCountdown> {
  static const _start = Duration(minutes: 4, seconds: 59);
  Duration _remaining = _start;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining = _remaining.inSeconds <= 1
            ? _start
            : _remaining - const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          children: [
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: Colors.redAccent,
                ),
              ),
            ),
            const TextSpan(text: '${AppStrings.promoEndsIn} '),
            TextSpan(
              text: '$minutes:$seconds',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.isProcessing,
    required this.enabled,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool isProcessing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = plan.isHighlighted;
    final badge = plan.badge;
    final tile = Material(
      color: highlight
          ? AppColors.gold.withValues(alpha: 0.12)
          : Colors.white10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlight ? AppColors.gold : Colors.transparent,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isProcessing)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (plan.originalPrice case final original?)
                      Text(
                        original,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.muted,
                        ),
                      ),
                    Text(
                      plan.displayPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: badge != null ? 14 : 6, bottom: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          if (badge != null)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(text, textAlign: TextAlign.center),
  );
}
