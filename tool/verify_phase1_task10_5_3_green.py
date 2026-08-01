#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "store": Path(
        "lib/core/notifications/linux_systemd_user_unit_store.dart"
    ),
    "transaction_test": Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_remove_transaction_test.dart"
    ),
    "legacy_test": Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_store_remove_test.dart"
    ),
    "contract": Path(
        "lib/core/notifications/linux_systemd_unit_transaction.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.3 {label}: {path}")
        sys.exit(1)

store = paths["store"].read_text(encoding="utf-8")
transaction_test = paths["transaction_test"].read_text(encoding="utf-8")
legacy_test = paths["legacy_test"].read_text(encoding="utf-8")
contract = paths["contract"].read_text(encoding="utf-8")

required_store = [
    "implements LinuxSystemdUnitStore",
    "Future<LinuxSystemdUnitRemoveTransaction> beginRemove(",
    "final class _RetainedRemoveTransaction",
    "implements LinuxSystemdUnitRemoveTransaction",
    "await _fileSystem.deleteFile(timerPath)",
    "await _fileSystem.deleteFile(servicePath)",
    "step: 'restore-$label-snapshot-write'",
    "step: 'restore-$label-snapshot-mode'",
    "LinuxSystemdUserUnitStoreOperation.applyRemove",
    "LinuxSystemdUserUnitStoreOperation.finalizeRemove",
    "LinuxSystemdUserUnitStoreOperation.rollbackRemove",
    "Future<void> remove(LinuxSystemdUnitNames names) async",
    "transaction = await beginRemove(names)",
    "await transaction.apply()",
    "await transaction.finalize()",
    "await transaction.rollback()",
]
required_transaction_test = [
    "snapshots",
    "without deleting either unit",
    "deletes timer before service",
    "service deletion failure remains rollback-capable",
    "releases rollback state and becomes idempotent",
    "restores service before timer",
    "records snapshot write failure and continues with timer",
    "records mode restoration failure without hiding primary",
    "aggregates rollback failures in encounter order",
    "rolls back timer after service deletion failure",
    "keeps primary delete failure and attaches rollback failure",
]
required_legacy = [
    "service deletion failure restores the removed timer",
    "expect(fileSystem.containsPath(_timerPath(names)), isTrue)",
    "expect(fileSystem.bytesOf(_timerPath(names)), utf8.encode('timer'))",
]
required_contract = [
    "abstract interface class LinuxSystemdUnitRemoveTransaction",
    "Future<LinuxSystemdUnitRemoveTransaction> beginRemove(",
]

for label, text, required in (
    ("retained remove implementation", store, required_store),
    ("Gate tests", transaction_test, required_transaction_test),
    ("legacy regression update", legacy_test, required_legacy),
    ("transaction contract", contract, required_contract),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

# Task 10.5.3 constructor compatibility
constructor_contracts = [
    (
        "install filesystem",
        "required LinuxSystemdFileSystem fileSystem",
        "fileSystem: _fileSystem",
    ),
    (
        "install paths",
        "required _InstallPaths paths",
        "paths: paths",
    ),
    (
        "install mutation state",
        "required _InstallMutationState mutationState",
        "mutationState: state",
    ),
    (
        "remove filesystem",
        "required LinuxSystemdFileSystem fileSystem",
        "fileSystem: _fileSystem",
    ),
    (
        "remove service snapshot",
        "required _ExistingUnitSnapshot? serviceSnapshot",
        "serviceSnapshot: serviceSnapshot",
    ),
    (
        "remove timer snapshot",
        "required _ExistingUnitSnapshot? timerSnapshot",
        "timerSnapshot: timerSnapshot",
    ),
]

for label, constructor_token, call_token in constructor_contracts:
    if constructor_token not in store:
        print(
            f"ERROR: missing constructor parameter for {label}: "
            f"{constructor_token}"
        )
        sys.exit(1)

    if call_token not in store:
        print(
            f"ERROR: call site does not match {label}: "
            f"{call_token}"
        )
        sys.exit(1)

for accidental_argument in (
    "__fileSystem:",
    "__paths:",
    "__mutationState:",
    "__serviceSnapshot:",
    "__timerSnapshot:",
):
    if accidental_argument in store:
        print(
            "ERROR: accidental double-underscore argument remains: "
            f"{accidental_argument}"
        )
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
            "ERROR: Task 10.5.3 contains process, direct IO, or "
            f"placeholder coupling: {forbidden}"
        )
        sys.exit(1)

begin_start = store.find(
    "Future<LinuxSystemdUnitRemoveTransaction> beginRemove("
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
            "ERROR: beginRemove mutates filesystem state before "
            f"returning the retained transaction: {forbidden}"
        )
        sys.exit(1)

remove_class_start = store.find(
    "final class _RetainedRemoveTransaction"
)
install_class_start = store.find(
    "final class _RetainedInstallTransaction"
)
remove_body = store[remove_class_start:install_class_start]

timer_delete = remove_body.find(
    "await _fileSystem.deleteFile(timerPath)"
)
service_delete = remove_body.find(
    "await _fileSystem.deleteFile(servicePath)"
)
service_restore = remove_body.find(
    "label: 'service'"
)
timer_restore = remove_body.find(
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
    print("ERROR: retained remove apply/rollback ordering is incorrect.")
    sys.exit(1)

if remove_body.count("LinuxSystemdUnitTransactionState.finalized") < 3:
    print("ERROR: finalize lifecycle and invalid rollback state are incomplete.")
    sys.exit(1)

if "_serviceSnapshot = null" not in remove_body:
    print("ERROR: finalize/rollback must release service snapshot memory.")
    sys.exit(1)

if "_timerSnapshot = null" not in remove_body:
    print("ERROR: finalize/rollback must release timer snapshot memory.")
    sys.exit(1)

wrapper_start = store.find(
    "Future<void> remove(LinuxSystemdUnitNames names) async"
)
snapshot_start = store.find(
    "Future<_ExistingUnitSnapshot?> _snapshotExisting("
)
wrapper_body = store[wrapper_start:snapshot_start]

for token in (
    "beginRemove(names)",
    "transaction.apply()",
    "transaction.finalize()",
    "transaction.rollback()",
    "final primary = _primaryFailure(error, stackTrace)",
):
    if token not in wrapper_body:
        print(f"ERROR: remove wrapper missing transaction step: {token}")
        sys.exit(1)

print(
    "OK: Task 10.5.3 GREEN makes the concrete store implement the full "
    "unit-store contract, adds non-mutating exact remove snapshots, timer-"
    "first apply, idempotent apply/finalize/rollback completion, snapshot "
    "memory release, exact service-then-timer byte-and-mode restoration, "
    "ordered rollback aggregation, primary-cause-preserving wrapper rollback, "
    "and updates the legacy removal regression to require restored state."
)
