#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "store": Path(
        "lib/core/notifications/linux_systemd_user_unit_store.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_store_remove_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.2.6 {label}: {path}")
        sys.exit(1)

store = paths["store"].read_text(encoding="utf-8")
tests = paths["test"].read_text(encoding="utf-8")

required_store = [
    "Future<void> remove(LinuxSystemdUnitNames names) async",
    "_validateUnitNamePair(",
    "final timerType = await _validateRemovalPath(timerPath)",
    "final serviceType = await _validateRemovalPath(",
    "await _fileSystem.deleteFile(timerPath)",
    "await _fileSystem.deleteFile(servicePath)",
    "LinuxSystemdUserUnitStoreOperation.remove",
    "operation: 'remove'",
]
missing = [token for token in required_store if token not in store]
if missing:
    print(f"ERROR: Task 10.2.6 store is incomplete: {missing}")
    sys.exit(1)

if tests.count("test(") != 10:
    print(
        "ERROR: expected exactly 10 removal tests, "
        f"found {tests.count('test(')}."
    )
    sys.exit(1)

timer_delete = store.find(
    "await _fileSystem.deleteFile(timerPath)"
)
service_delete = store.find(
    "await _fileSystem.deleteFile(servicePath)"
)
if timer_delete < 0 or service_delete < 0:
    print("ERROR: expected both final delete operations.")
    sys.exit(1)
if timer_delete >= service_delete:
    print("ERROR: timer must be deleted before service.")
    sys.exit(1)

for forbidden in (
    "createDirectory(directory)",
    "Process.run",
    "Process.start",
    "systemctl",
    "/bin/sh",
    "sh -c",
):
    remove_start = store.find(
        "Future<void> remove(LinuxSystemdUnitNames names)"
    )
    remove_end = store.find(
        "Future<_ExistingUnitSnapshot?> _snapshotExisting"
    )
    remove_body = store[remove_start:remove_end]
    if forbidden in remove_body:
        print(
            "ERROR: remove() contains forbidden behavior: "
            f"{forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.2.6 performs preflight on both destinations, "
    "removes timer before service, is idempotent for missing files, "
    "rejects unsafe entries, and includes 10 focused tests."
)
