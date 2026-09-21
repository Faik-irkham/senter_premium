import '../domain/flashlight_repository.dart';

class FakeFlashlightRepository implements FlashlightRepository {
  FakeFlashlightRepository({this.available = true});

  final bool available;
  bool isOn = false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> turnOn() async => isOn = true;

  @override
  Future<void> turnOff() async => isOn = false;
}
