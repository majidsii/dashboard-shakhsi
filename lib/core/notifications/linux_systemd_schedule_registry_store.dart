import 'linux_systemd_schedule_registry.dart';

typedef LinuxSystemdRegistryTransactionIdFactory = String Function();

/// Persistent inventory boundary for app-owned Linux notification schedules.
///
/// Quarantine and discovery methods are added in their own TDD Gate.
abstract interface class LinuxSystemdScheduleRegistryStore {
  Future<LinuxSystemdScheduleRegistry> load();

  Future<void> replace(LinuxSystemdScheduleRegistry next);
}
