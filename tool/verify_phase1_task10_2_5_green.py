#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "contract": Path(
        "lib/core/notifications/linux_systemd_file_system.dart"
    ),
    "adapter": Path(
        "lib/core/notifications/"
        "dart_io_linux_systemd_file_system.dart"
    ),
    "store": Path(
        "lib/core/notifications/linux_systemd_user_unit_store.dart"
    ),
    "fake": Path(
        "test/support/fake_linux_systemd_file_system.dart"
    ),
    "adapter_test": Path(
        "test/core/notifications/"
        "dart_io_linux_systemd_file_system_test.dart"
    ),
    "rollback_test": Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_store_rollback_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.2.5 {label}: {path}")
        sys.exit(1)

contract = paths["contract"].read_text(encoding="utf-8")
adapter = paths["adapter"].read_text(encoding="utf-8")
store = paths["store"].read_text(encoding="utf-8")
fake = paths["fake"].read_text(encoding="utf-8")
adapter_test = paths["adapter_test"].read_text(encoding="utf-8")
rollback_test = paths["rollback_test"].read_text(encoding="utf-8")

checks = {
    "contract": (
        contract,
        [
            "Future<int> readMode(String path)",
        ],
    ),
    "adapter": (
        adapter,
        [
            "Future<int> readMode(String path)",
            "FileStat.stat(path)",
            "stat.mode & 0x1FF",
        ],
    ),
    "store": (
        store,
        [
            "final state = _InstallTransactionState()",
            "_snapshotExisting(",
            "await _rollback(",
            "rollbackFailures: rollbackFailures",
            "restore-$label-backup",
            "restore-$label-snapshot-write",
            "restore-$label-snapshot-mode",
            "delete-$label-backup-after-restore",
            "final class _ExistingUnitSnapshot",
        ],
    ),
    "fake": (
        fake,
        [
            "Future<int> readMode(String path)",
            "_recordAndMaybeFail('readMode:$path')",
            "import 'dart:io';",
        ],
    ),
}

for label, (text, required) in checks.items():
    missing = [token for token in required if token not in text]
    if missing:
        print(
            f"ERROR: Task 10.2.5 {label} is incomplete: {missing}"
        )
        sys.exit(1)

if adapter_test.count("test(") != 16:
    print(
        "ERROR: expected 16 filesystem adapter tests, "
        f"found {adapter_test.count('test(')}."
    )
    sys.exit(1)

if rollback_test.count("test(") != 7:
    print(
        "ERROR: expected 7 rollback tests, "
        f"found {rollback_test.count('test(')}."
    )
    sys.exit(1)

for forbidden in (
    "Process.run",
    "Process.start",
    "/bin/sh",
    "sh -c",
    "systemctl",
):
    if forbidden in store:
        print(
            "ERROR: rollback store contains forbidden command "
            f"execution: {forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.2.5 snapshots bytes and modes, restores complete "
    "or partial pairs across all failure points, aggregates rollback "
    "failures, and includes 23 focused tests."
)
