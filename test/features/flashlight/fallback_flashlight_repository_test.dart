import 'package:flutter_test/flutter_test.dart';
import 'package:senter_premium/features/flashlight/data/fake_flashlight_repository.dart';
import 'package:senter_premium/features/flashlight/data/fallback_flashlight_repository.dart';

void main() {
  test('tanpa flash (simulator) memakai senter virtual', () async {
    final hardware = FakeFlashlightRepository(available: false);
    final virtual = FakeFlashlightRepository();
    final repository = FallbackFlashlightRepository(
      primary: hardware,
      fallback: virtual,
    );

    expect(await repository.isAvailable(), isTrue);
    expect(repository.isUsingFallback, isTrue);

    await repository.turnOn();
    expect(virtual.isOn, isTrue);
    expect(hardware.isOn, isFalse);
  });

  test('dengan flash memakai hardware', () async {
    final hardware = FakeFlashlightRepository();
    final virtual = FakeFlashlightRepository();
    final repository = FallbackFlashlightRepository(
      primary: hardware,
      fallback: virtual,
    );

    expect(await repository.isAvailable(), isTrue);
    expect(repository.isUsingFallback, isFalse);

    await repository.turnOn();
    expect(hardware.isOn, isTrue);
    expect(virtual.isOn, isFalse);
  });
}
