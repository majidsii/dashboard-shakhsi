#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "store": Path(
        "lib/core/notifications/linux_systemd_user_unit_store.dart"
    ),
    "transaction": Path(
        "lib/core/notifications/linux_systemd_unit_transaction.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_install_transaction_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.2 {label}: {path}")
        sys.exit(1)

store = paths["store"].read_text(encoding="utf-8")
transaction = paths["transaction"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_store = [
    "Future<LinuxSystemdUnitInstallTransaction> beginInstall(",
    "final class _RetainedInstallTransaction",
    "implements LinuxSystemdUnitInstallTransaction",
    "LinuxSystemdUnitTransactionState.pending",
    "LinuxSystemdUnitTransactionState.applied",
    "LinuxSystemdUnitTransactionState.finalized",
    "LinuxSystemdUnitTransactionState.rolledBack",
    "await _fileSystem.createDirectory(_paths.directory)",
    "await _fileSystem.writeBytes(",
    "await _fileSystem.chmod(",
    "await _fileSystem.rename(",
    "await _fileSystem.deleteFile(",
    "step: 'delete-new-$label'",
    "step: 'restore-$label-backup'",
    "step: 'restore-$label-snapshot-write'",
    "step: 'restore-$label-snapshot-mode'",
    "step: 'delete-$label-backup-after-restore'",
    "step: 'delete-$label-temp'",
    "Future<void> install(LinuxSystemdRenderedUnits units) async",
    "final primary = _primaryFailure(error, stackTrace)",
]
required_test = [
    "returns a pending retained transaction without mutating files",
    "retains exact backups",
    "uses the deterministic retained-install operation order",
    "apply is idempotent after success",
    "deletes retained backups and becomes idempotent",
    "restores exact",
    "every apply failure can roll back a complete prior pair",
    "finalize failure remains rollback-capable through snapshots",
    "rollback reports ordered failures without stopping cleanup",
    "preserves the raw primary cause and rolls back on apply failure",
]
required_contract = [
    "abstract interface class LinuxSystemdUnitInstallTransaction",
    "Future<void> apply()",
    "Future<void> finalize()",
    "Future<void> rollback()",
]

for label, text, required in (
    ("retained install implementation", store, required_store),
    ("Gate tests", test, required_test),
    ("transaction contract", transaction, required_contract),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

for forbidden in (
    "Process.start",
    "Process.run",
    "systemctl",
    "dart:io",
    "UnimplementedError",
    "TODO",
):
    if forbidden in store:
        print(
            "ERROR: Task 10.5.2 contains process, direct IO, or "
            f"placeholder coupling: {forbidden}"
        )
        sys.exit(1)

begin_start = store.find(
    "Future<LinuxSystemdUnitInstallTransaction> beginInstall("
)
install_start = store.find(
    "Future<void> install(LinuxSystemdRenderedUnits units) async"
)
begin_body = store[begin_start:install_start]

for forbidden in (
    "createDirectory(",
    "writeBytes(",
    "chmod(",
    "rename(",
    "deleteFile(",
):
    if forbidden in begin_body:
        print(
            "ERROR: beginInstall mutates filesystem state before "
            f"returning the retained transaction: {forbidden}"
        )
        sys.exit(1)

apply_start = store.find("Future<void> apply() async")
finalize_start = store.find("Future<void> finalize() async")
rollback_start = store.find("Future<void> rollback() async")

if not (-1 < apply_start < finalize_start < rollback_start):
    print("ERROR: retained transaction lifecycle methods are missing.")
    sys.exit(1)

apply_body = store[apply_start:finalize_start]
service_write = apply_body.find("_paths.service.tempPath")
timer_write = apply_body.find("_paths.timer.tempPath")
service_backup = apply_body.find(
    "_paths.service.finalPath,\n          _paths.service.backupPath"
)
timer_backup = apply_body.find(
    "_paths.timer.finalPath,\n          _paths.timer.backupPath"
)
service_publish = apply_body.rfind(
    "_paths.service.tempPath,\n        _paths.service.finalPath"
)
timer_publish = apply_body.rfind(
    "_paths.timer.tempPath,\n        _paths.timer.finalPath"
)

if not (
    -1
    < service_write
    < timer_write
    < service_backup
    < timer_backup
    < service_publish
    < timer_publish
):
    print("ERROR: retained install apply ordering is incorrect.")
    sys.exit(1)

rollback_body = store[rollback_start:]
timer_delete = rollback_body.find("label: 'timer'")
service_delete = rollback_body.find("label: 'service'")
service_restore = rollback_body.find(
    "label: 'service'",
    service_delete + 1,
)
timer_restore = rollback_body.find(
    "label: 'timer'",
    service_restore + 1,
)

if not (
    -1
    < timer_delete
    < service_delete
    < service_restore
    < timer_restore
):
    print("ERROR: retained install rollback ordering is incorrect.")
    sys.exit(1)

if "_deleteRemainingBackup" in store:
    print(
        "ERROR: rollback must not delete unresolved backup recovery "
        "material after restoration failure."
    )
    sys.exit(1)

print(
    "OK: Task 10.5.2 GREEN adds a non-mutating retained beginInstall, "
    "exact missing/partial/complete snapshots, deterministic two-file apply, "
    "retained backups through applied state, idempotent apply/finalize/"
    "rollback completion, exact byte-and-mode restoration, safe fallback "
    "recovery, ordered rollback failures, and a compatible install wrapper "
    "that preserves the raw primary cause."
)
