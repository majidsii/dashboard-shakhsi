import 'linux_systemd_notification_unit.dart';
import 'linux_systemd_unit_renderer.dart';

/// Lifecycle of one retained systemd user-unit mutation transaction.
enum LinuxSystemdUnitTransactionState {
  pending,
  applied,
  finalized,
  rolledBack,
}

/// Retained installation whose prior unit state remains rollback-capable.
abstract interface class LinuxSystemdUnitInstallTransaction {
  LinuxSystemdUnitNames get names;

  LinuxSystemdUnitTransactionState get state;

  Future<void> apply();

  Future<void> finalize();

  Future<void> rollback();
}

/// Retained removal whose exact prior unit state remains rollback-capable.
abstract interface class LinuxSystemdUnitRemoveTransaction {
  LinuxSystemdUnitNames get names;

  LinuxSystemdUnitTransactionState get state;

  Future<void> apply();

  Future<void> finalize();

  Future<void> rollback();
}

/// Injectable systemd user-unit persistence boundary.
abstract interface class LinuxSystemdUnitStore {
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  );

  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  );

  Future<void> install(LinuxSystemdRenderedUnits units);

  Future<void> remove(LinuxSystemdUnitNames names);
}
