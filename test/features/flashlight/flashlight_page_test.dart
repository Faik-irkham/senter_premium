import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senter_premium/app/app.dart';
import 'package:senter_premium/core/l10n/app_strings.dart';
import 'package:senter_premium/core/three_d/mesh_builder.dart';
import 'package:senter_premium/core/three_d/vec3.dart';
import 'package:senter_premium/features/flashlight/application/flashlight_controller.dart';
import 'package:senter_premium/features/flashlight/application/flashlight_model_provider.dart';
import 'package:senter_premium/features/flashlight/data/fake_flashlight_repository.dart';
import 'package:senter_premium/features/subscription/application/subscription_providers.dart';
import 'package:senter_premium/features/subscription/data/fake_subscription_repository.dart';
import 'package:senter_premium/features/subscription/presentation/paywall_sheet.dart';

void main() {
  late FakeFlashlightRepository torch;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    torch = FakeFlashlightRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flashlightRepositoryProvider.overrideWithValue(torch),
          flashlightModelProvider.overrideWith(
            (ref) =>
                (MeshBuilder()
                      ..box(
                        const Vec3(-1, -0.2, -0.2),
                        const Vec3(1, 0.2, 0.2),
                        'body',
                      )
                      ..box(
                        const Vec3(0.9, -0.2, -0.2),
                        const Vec3(1, 0.2, 0.2),
                        'lens',
                      ))
                    .build(),
          ),
          subscriptionRepositoryProvider.overrideWithValue(
            FakeSubscriptionRepository(latency: Duration.zero),
          ),
        ],
        child: const SenterPremiumApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapPower(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.power_settings_new));
    await tester.pumpAndSettle();
  }

  Future<void> closeSheet(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(PaywallSheet))).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('nyalakan gratis, matikan -> paywall -> perayaan -> mati', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text(AppStrings.tapToTurnOn), findsOneWidget);
    expect(
      find.textContaining(RegExp('gratis', caseSensitive: false)),
      findsNothing,
    );
    expect(find.text(AppStrings.premium), findsNothing);

    await tapPower(tester);
    expect(torch.isOn, isTrue);
    expect(find.text(AppStrings.tapToTurnOff), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNothing);

    await tapPower(tester);
    expect(find.text(AppStrings.paywallSubtitle), findsOneWidget);
    expect(torch.isOn, isTrue);

    await tester.tap(find.text('Sultan Kegelapan'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.paywallSubtitle), findsNothing);
    expect(find.text(AppStrings.celebrationTitle), findsOneWidget);
    expect(torch.isOn, isTrue);

    await tester.tap(find.text(AppStrings.celebrationAction));
    await tester.pumpAndSettle();
    expect(torch.isOn, isFalse);
    expect(find.text(AppStrings.premium), findsOneWidget);

    await tester.longPress(find.text(AppStrings.premium));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.premium), findsNothing);
    expect(find.text(AppStrings.demoReset), findsOneWidget);
  });

  testWidgets('reaksi makin dramatis setiap kali paywall ditutup', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapPower(tester);

    await tapPower(tester);
    await closeSheet(tester);
    expect(find.text(AppStrings.deniedLine(0)), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);

    await tapPower(tester);
    await closeSheet(tester);
    expect(find.text(AppStrings.deniedLine(1)), findsOneWidget);
    expect(torch.isOn, isTrue);
  });
}
