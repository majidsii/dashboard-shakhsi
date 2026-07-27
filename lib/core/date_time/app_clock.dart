abstract interface class AppClock {
  DateTime nowUtc();

  DateTime nowLocal();
}

final class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  DateTime nowLocal() => DateTime.now();
}

final class FixedAppClock implements AppClock {
  const FixedAppClock({required this.utcValue, required this.localValue});

  final DateTime utcValue;
  final DateTime localValue;

  @override
  DateTime nowUtc() => utcValue;

  @override
  DateTime nowLocal() => localValue;
}
