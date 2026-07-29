#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path(
    "test/core/notifications/"
    "linux_systemd_user_unit_store_rollback_test.dart"
)
store_path = Path(
    "lib/core/notifications/linux_systemd_user_unit_store.dart"
)

if not test_path.exists():
    print(f"ERROR: missing Task 10.2.5 RED test: {test_path}")
    sys.exit(1)

if not store_path.exists():
    print(f"ERROR: Task 10.2.4 store is missing: {store_path}")
    sys.exit(1)

test_text = test_path.read_text(encoding="utf-8")
store_text = store_path.read_text(encoding="utf-8")

required = [
    "prepare failures preserve every previous pair state",
    "every commit failure restores a complete previous pair",
    "second backup cleanup failure reconstructs the deleted first backup",
    "rollback failure never replaces the original cause",
    "multiple rollback failures are retained in execution order",
    "rollback never changes unrelated files",
]
missing = [token for token in required if token not in test_text]
if missing:
    print(f"ERROR: Task 10.2.5 RED coverage is incomplete: {missing}")
    sys.exit(1)

if test_text.count("test(") != 7:
    print(
        "ERROR: expected exactly 7 rollback test groups, "
        f"found {test_text.count('test(')}."
    )
    sys.exit(1)

if "rollbackFailures: rollbackFailures" in store_text:
    print(
        "ERROR: RED expects full rollback aggregation to be absent."
    )
    sys.exit(1)

print(
    "OK: Task 10.2.5 RED rollback matrix is installed and the "
    "current store does not yet aggregate rollback failures."
)
