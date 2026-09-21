import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shake_on_change.dart';
import '../../subscription/application/subscription_providers.dart';
import '../../subscription/domain/premium_feature.dart';
import '../../subscription/presentation/celebration_dialog.dart';
import '../../subscription/presentation/paywall_sheet.dart';
import '../../subscription/presentation/premium_badge.dart';
import '../application/flashlight_controller.dart';
import 'widgets/ambient_glow.dart';
import 'widgets/flashlight_3d_view.dart';
import 'widgets/power_button.dart';

class FlashlightPage extends ConsumerWidget {
  const FlashlightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashlight = ref.watch(flashlightControllerProvider);
    final canTurnOff = ref.watch(
      featureGateProvider.select(
        (g) => g.canUse(PremiumFeature.turnOffFlashlight),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: const [PremiumBadge(), SizedBox(width: 12)],
      ),
      body: AmbientGlow(
        isOn: flashlight.isOn,
        child: Center(
          child: switch (flashlight.status) {
            FlashlightStatus.checking => const _Status(
              icon: null,
              text: AppStrings.checkingTorch,
            ),
            FlashlightStatus.unavailable => const _Status(
              icon: Icons.no_flash,
              text: AppStrings.torchUnavailable,
            ),
            FlashlightStatus.on || FlashlightStatus.off => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShakeOnChange(
                  trigger: flashlight.deniedAttempts,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flashlight3DView(
                        isOn: flashlight.isOn,
                        onTap: flashlight.isBusy
                            ? null
                            : () => _onToggle(context, ref),
                      ),
                      const SizedBox(height: 8),
                      PowerButton(
                        size: 88,
                        isOn: flashlight.isOn,
                        isBusy: flashlight.isBusy,
                        isLocked:
                            flashlight.isOn &&
                            !canTurnOff &&
                            flashlight.deniedAttempts > 0,
                        onPressed: () => _onToggle(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 48,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _hint(flashlight, canTurnOff),
                      key: ValueKey(_hint(flashlight, canTurnOff)),
                      textAlign: TextAlign.center,
                      style: flashlight.isOn
                          ? const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 8),
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            )
                          : const TextStyle(
                              color: AppColors.muted,
                              fontSize: 15,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }

  String _hint(FlashlightState flashlight, bool canTurnOff) {
    if (!flashlight.isOn) return AppStrings.tapToTurnOn;
    if (canTurnOff || flashlight.deniedAttempts == 0) {
      return AppStrings.tapToTurnOff;
    }
    return AppStrings.deniedLine(flashlight.deniedAttempts - 1);
  }

  Future<void> _onToggle(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(flashlightControllerProvider.notifier);
    final result = await controller.toggle();
    if (!context.mounted) return;

    switch (result) {
      case ToggleResult.premiumRequired:
        HapticFeedback.heavyImpact();
        final isPremium = await showPaywall(context);
        if (!isPremium || !context.mounted) return;
        await showCelebration(context);
        await controller.toggle();
      case ToggleResult.turnedOn || ToggleResult.turnedOff:
        HapticFeedback.lightImpact();
      case ToggleResult.failed:
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(AppStrings.torchError)));
      case ToggleResult.ignored:
        break;
    }
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon == null)
        const CircularProgressIndicator()
      else
        Icon(icon, size: 64, color: AppColors.muted),
      const SizedBox(height: 16),
      Text(text, style: const TextStyle(color: AppColors.muted)),
    ],
  );
}
