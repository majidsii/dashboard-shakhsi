import 'linux_systemd_schedule_registry.dart';

typedef LinuxSystemdRegistryTransactionIdFactory = String Function();

/// Persistent inventory boundary for app-owned Linux notification schedules.
abstract interface class LinuxSystemdScheduleRegistryStore {
  Future<LinuxSystemdScheduleRegistry> load();

  Future<void> replace(LinuxSystemdScheduleRegistry next);

  Future<void> quarantineCorruptRegistry();

  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs();
}
