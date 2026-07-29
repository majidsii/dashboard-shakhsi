#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path(
    "test/core/notifications/"
    "linux_systemd_user_unit_store_install_test.dart"
)
store_path = Path(
    "lib/core/notifications/linux_systemd_user_unit_store.dart"
)

if not test_path.exists():
    print(f"ERROR: missing Task 10.2.4 RED test: {test_path}")
    sys.exit(1)

if store_path.exists():
    print(
        "ERROR: RED expects the transactional store to be absent: "
        f"{store_path}"
    )
    sys.exit(1)

text = test_path.read_text(encoding="utf-8")
required = [
    "installs a new service and timer with mode 0644",
    "prepares both temporary files before replacing finals",
    "replaces an existing complete pair",
    "replaces an existing service-only pair",
    "leaves no transaction artifacts after success",
    "rejects a destination symbolic link",
    "rejects pre-existing transaction artifacts",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.2.4 RED coverage is incomplete: {missing}")
    sys.exit(1)

if text.count("test(") != 29:
    print(
        "ERROR: expected 29 combined harness and installation tests, "
        f"found {text.count('test(')}."
    )
    sys.exit(1)

print(
    "OK: Task 10.2.4 RED installation tests are present and the "
    "transactional store is intentionally absent."
)
