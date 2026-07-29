#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path(
    "test/core/notifications/"
    "linux_systemd_user_unit_store_remove_test.dart"
)
store_path = Path(
    "lib/core/notifications/linux_systemd_user_unit_store.dart"
)

if not test_path.exists():
    print(f"ERROR: missing Task 10.2.6 RED test: {test_path}")
    sys.exit(1)

if not store_path.exists():
    print(f"ERROR: Task 10.2.5 store is missing: {store_path}")
    sys.exit(1)

tests = test_path.read_text(encoding="utf-8")
store = store_path.read_text(encoding="utf-8")

required = [
    "removes timer before service",
    "succeeds when both files are missing",
    "rejects a timer symlink before deleting service",
    "rejects a service symlink before deleting timer",
    "timer deletion failure prevents service deletion",
    "service deletion failure is wrapped as remove error",
]
missing = [token for token in required if token not in tests]
if missing:
    print(f"ERROR: Task 10.2.6 RED coverage is incomplete: {missing}")
    sys.exit(1)

if tests.count("test(") != 10:
    print(
        "ERROR: expected exactly 10 removal tests, "
        f"found {tests.count('test(')}."
    )
    sys.exit(1)

if "Unit removal is implemented by Task 10.2.6." not in store:
    print(
        "ERROR: RED expects the Task 10.2.5 remove placeholder."
    )
    sys.exit(1)

print(
    "OK: Task 10.2.6 RED removal tests are installed and remove() "
    "still contains the expected unsupported placeholder."
)
