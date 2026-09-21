import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../application/subscription_providers.dart';
import '../data/fake_subscription_repository.dart';

class PremiumBadge extends ConsumerWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(entitlementProvider.select((e) => e.isPremium));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: !isPremium
          ? const SizedBox.shrink()
          : GestureDetector(
              onLongPress: () => _resetDemo(context, ref),
              child: const Chip(
                avatar: Icon(
                  Icons.workspace_premium,
                  size: 18,
                  color: AppColors.background,
                ),
                label: Text(AppStrings.premium),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.background,
                ),
                backgroundColor: AppColors.gold,
                side: BorderSide(color: AppColors.gold),
              ),
            ),
    );
  }

  void _resetDemo(BuildContext context, WidgetRef ref) {
    final repository = ref.read(subscriptionRepositoryProvider);
    if (repository is! FakeSubscriptionRepository) return;
    repository.reset();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(AppStrings.demoReset)));
  }
}
