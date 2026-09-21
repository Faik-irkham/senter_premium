import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../subscription/application/subscription_providers.dart';
import '../../subscription/domain/premium_feature.dart';
import '../data/fake_flashlight_repository.dart';
import '../data/fallback_flashlight_repository.dart';
import '../data/torch_light_flashlight_repository.dart';
import '../domain/flashlight_repository.dart';

final flashlightRepositoryProvider = Provider<FlashlightRepository>((ref) {
  const hardware = TorchLightFlashlightRepository();
  if (!AppConfig.virtualTorchFallback) return hardware;
  return FallbackFlashlightRepository(
    primary: hardware,
    fallback: FakeFlashlightRepository(),
  );
});

enum FlashlightStatus { checking, unavailable, off, on }

class FlashlightState {
  const FlashlightState({
    required this.status,
    this.isBusy = false,
    this.deniedAttempts = 0,
  });

  final FlashlightStatus status;
  final bool isBusy;

  final int deniedAttempts;

  bool get isOn => status == FlashlightStatus.on;
  bool get isReady =>
      status == FlashlightStatus.on || status == FlashlightStatus.off;

  FlashlightState copyWith({
    FlashlightStatus? status,
    bool? isBusy,
    int? deniedAttempts,
  }) => FlashlightState(
    status: status ?? this.status,
    isBusy: isBusy ?? this.isBusy,
    deniedAttempts: deniedAttempts ?? this.deniedAttempts,
  );
}

enum ToggleResult { turnedOn, turnedOff, premiumRequired, failed, ignored }

final flashlightControllerProvider =
    NotifierProvider<FlashlightController, FlashlightState>(
      FlashlightController.new,
    );

class FlashlightController extends Notifier<FlashlightState> {
  FlashlightRepository get _repository =>
      ref.read(flashlightRepositoryProvider);

  @override
  FlashlightState build() {
    Future.microtask(_checkAvailability);
    return const FlashlightState(status: FlashlightStatus.checking);
  }

  Future<void> _checkAvailability() async {
    final available = await _repository.isAvailable();
    if (!ref.mounted) return;
    state = FlashlightState(
      status: available ? FlashlightStatus.off : FlashlightStatus.unavailable,
    );
  }

  Future<ToggleResult> toggle() async {
    if (!state.isReady || state.isBusy) return ToggleResult.ignored;

    if (!state.isOn) {
      return _run(
        _repository.turnOn,
        FlashlightStatus.on,
        ToggleResult.turnedOn,
      );
    }

    final gate = ref.read(featureGateProvider);
    if (!gate.canUse(PremiumFeature.turnOffFlashlight)) {
      state = state.copyWith(deniedAttempts: state.deniedAttempts + 1);
      return ToggleResult.premiumRequired;
    }
    return _run(
      _repository.turnOff,
      FlashlightStatus.off,
      ToggleResult.turnedOff,
    );
  }

  Future<ToggleResult> _run(
    Future<void> Function() action,
    FlashlightStatus target,
    ToggleResult onSuccess,
  ) async {
    state = state.copyWith(isBusy: true);
    try {
      await action();
      if (ref.mounted) state = FlashlightState(status: target);
      return onSuccess;
    } on FlashlightException {
      if (ref.mounted) state = state.copyWith(isBusy: false);
      return ToggleResult.failed;
    }
  }
}
