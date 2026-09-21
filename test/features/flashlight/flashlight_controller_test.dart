import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senter_premium/features/flashlight/application/flashlight_controller.dart';
import 'package:senter_premium/features/flashlight/data/fake_flashlight_repository.dart';
import 'package:senter_premium/features/subscription/application/subscription_providers.dart';
import 'package:senter_premium/features/subscription/data/fake_subscription_repository.dart';
import 'package:senter_premium/features/subscription/domain/entitlement.dart';

void main() {
  late FakeFlashlightRepository torch;
  late FakeSubscriptionRepository billing;

  ProviderContainer createContainer({Entitlement initial = Entitlement.free}) {
    torch = FakeFlashlightRepository();
    billing = FakeSubscriptionRepository(
      initial: initial,
      latency: Duration.zero,
    );
    final container = ProviderContainer(
      overrides: [
        flashlightRepositoryProvider.overrideWithValue(torch),
        subscriptionRepositoryProvider.overrideWithValue(billing),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<FlashlightController> ready(ProviderContainer container) async {
    container.read(flashlightControllerProvider);
    await Future<void>.delayed(Duration.zero);
    return container.read(flashlightControllerProvider.notifier);
  }

  test('menyalakan senter gratis', () async {
    final container = createContainer();
    final controller = await ready(container);

    expect(await controller.toggle(), ToggleResult.turnedOn);
    expect(torch.isOn, isTrue);
    expect(container.read(flashlightControllerProvider).isOn, isTrue);
  });

  test('mematikan senter tanpa langganan ditolak', () async {
    final container = createContainer();
    final controller = await ready(container);

    await controller.toggle();
    expect(await controller.toggle(), ToggleResult.premiumRequired);
    expect(torch.isOn, isTrue);
  });

  test('mematikan senter diizinkan untuk user Premium', () async {
    final container = createContainer(
      initial: const Entitlement.premium(productId: 'senter_premium_monthly'),
    );
    final controller = await ready(container);

    await controller.toggle();
    expect(await controller.toggle(), ToggleResult.turnedOff);
    expect(torch.isOn, isFalse);
  });

  test('setelah membeli langganan, senter bisa dimatikan', () async {
    final container = createContainer();
    final controller = await ready(container);
    container.read(entitlementProvider);

    await controller.toggle();
    expect(await controller.toggle(), ToggleResult.premiumRequired);

    await billing.purchase('senter_premium_weekly');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(entitlementProvider).isPremium, isTrue);
    expect(await controller.toggle(), ToggleResult.turnedOff);
  });

  test('perangkat tanpa senter berstatus unavailable', () async {
    final container = ProviderContainer(
      overrides: [
        flashlightRepositoryProvider.overrideWithValue(
          FakeFlashlightRepository(available: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = await ready(container);

    expect(
      container.read(flashlightControllerProvider).status,
      FlashlightStatus.unavailable,
    );
    expect(await controller.toggle(), ToggleResult.ignored);
  });
}
