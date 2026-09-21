import '../domain/flashlight_repository.dart';

class FallbackFlashlightRepository implements FlashlightRepository {
  FallbackFlashlightRepository({required this.primary, required this.fallback});

  final FlashlightRepository primary;
  final FlashlightRepository fallback;

  FlashlightRepository? _active;

  bool get isUsingFallback => identical(_active, fallback);

  @override
  Future<bool> isAvailable() async {
    _active = await primary.isAvailable() ? primary : fallback;
    return _active!.isAvailable();
  }

  @override
  Future<void> turnOn() async => (_active ?? await _resolve()).turnOn();

  @override
  Future<void> turnOff() async => (_active ?? await _resolve()).turnOff();

  Future<FlashlightRepository> _resolve() async {
    await isAvailable();
    return _active!;
  }
}
