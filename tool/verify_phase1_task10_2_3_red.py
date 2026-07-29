#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path(
    "test/core/notifications/"
    "linux_systemd_user_unit_store_install_test.dart"
)
production_path = Path(
    "lib/core/notifications/"
    "linux_systemd_user_unit_store_exception.dart"
)
fake_path = Path(
    "test/support/fake_linux_systemd_file_system.dart"
)

if not test_path.exists():
    print(f"ERROR: missing Task 10.2.3 RED test: {test_path}")
    sys.exit(1)

unexpected = [
    str(path)
    for path in (production_path, fake_path)
    if path.exists()
]
if unexpected:
    print(
        "ERROR: RED expects Task 10.2.3 implementation files to be absent, "
        f"but found: {', '.join(unexpected)}"
    )
    sys.exit(1)

text = test_path.read_text(encoding="utf-8")
required = [
    "FakeLinuxSystemdFileSystem",
    "an injected operation failure happens exactly once",
    "supports multiple queued failures for one operation",
    "LinuxSystemdUserUnitStoreException",
    "copies rollback failures into an immutable list",
    "toString includes context but never unit contents",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.2.3 RED coverage is incomplete: {missing}")
    sys.exit(1)

if text.count("test(") != 13:
    print(
        "ERROR: expected exactly 13 Task 10.2.3 tests, "
        f"found {text.count('test(')}."
    )
    sys.exit(1)

print(
    "OK: Task 10.2.3 RED tests are installed and the fake filesystem "
    "and store error model are intentionally absent."
)
