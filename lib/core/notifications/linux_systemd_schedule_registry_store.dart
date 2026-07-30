import 'linux_systemd_schedule_registry.dart';

typedef LinuxSystemdRegistryTransactionIdFactory = String Function();

/// Persistent inventory boundary for app-owned Linux notification schedules.
///
/// Additional mutation and discovery methods are added in their own TDD Gates.
abstract interface class LinuxSystemdScheduleRegistryStore {
  Future<LinuxSystemdScheduleRegistry> load();
}
