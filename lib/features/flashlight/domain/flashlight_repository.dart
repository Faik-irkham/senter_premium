abstract interface class FlashlightRepository {
  Future<bool> isAvailable();

  Future<void> turnOn();

  Future<void> turnOff();
}

class FlashlightException implements Exception {
  const FlashlightException(this.message);

  final String message;

  @override
  String toString() => 'FlashlightException: $message';
}
