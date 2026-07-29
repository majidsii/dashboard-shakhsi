#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "store": Path(
        "lib/core/notifications/linux_systemd_user_unit_store.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_store_install_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.2.4 {label} file: {path}")
        sys.exit(1)

store = paths["store"].read_text(encoding="utf-8")
tests = paths["test"].read_text(encoding="utf-8")

required_store = [
    "final class LinuxSystemdUserUnitStore",
    "Future<void> install(LinuxSystemdRenderedUnits units)",
    "r'^(dashboard-shakhsi-notification-[0-9a-f]{16})",
    "r'^[A-Za-z0-9_-]{1,64}$'",
    "await _fileSystem.writeBytes(",
    "await _fileSystem.chmod(",
    "paths.serviceBackup",
    "paths.timerBackup",
    "LinuxSystemdUnsafeEntryException(",
    "LinuxSystemdUserUnitStoreException(",
]
missing = [token for token in required_store if token not in store]
if missing:
    print(f"ERROR: Task 10.2.4 store is incomplete: {missing}")
    sys.exit(1)

if tests.count("test(") != 29:
    print(
        "ERROR: expected 29 focused tests, "
        f"found {tests.count('test(')}."
    )
    sys.exit(1)

for forbidden in (
    "Process.run",
    "Process.start",
    "systemctl",
    "/bin/sh",
    "sh -c",
):
    if forbidden in store:
        print(
            "ERROR: successful install store contains forbidden "
            f"command execution: {forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.2.4 safe name validation, two-file preparation, "
    "successful replacement, cleanup, and 29 focused tests are present."
)
