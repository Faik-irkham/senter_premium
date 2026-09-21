import 'package:torch_light/torch_light.dart';

import '../domain/flashlight_repository.dart';

class TorchLightFlashlightRepository implements FlashlightRepository {
  const TorchLightFlashlightRepository();

  @override
  Future<bool> isAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> turnOn() async {
    try {
      await TorchLight.enableTorch();
    } catch (e) {
      throw FlashlightException(e.toString());
    }
  }

  @override
  Future<void> turnOff() async {
    try {
      await TorchLight.disableTorch();
    } catch (e) {
      throw FlashlightException(e.toString());
    }
  }
}
