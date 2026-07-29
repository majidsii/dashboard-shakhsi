#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path(
    "test/core/notifications/"
    "dart_io_linux_systemd_file_system_test.dart"
)
production_paths = [
    Path("lib/core/notifications/linux_systemd_file_system.dart"),
    Path(
        "lib/core/notifications/"
        "dart_io_linux_systemd_file_system.dart"
    ),
]

if not test_path.exists():
    print(f"ERROR: missing Task 10.2.2 RED test: {test_path}")
    sys.exit(1)

existing = [str(path) for path in production_paths if path.exists()]
if existing:
    print(
        "ERROR: RED expects Task 10.2.2 production files to be absent, "
        f"but found: {', '.join(existing)}"
    )
    sys.exit(1)

text = test_path.read_text(encoding="utf-8")
required = [
    "typeOf detects a symbolic link without following it",
    "writes and reads bytes exactly",
    "rename moves bytes to the destination",
    "deleteFile succeeds when the path is missing",
    "deleteFile rejects a symbolic link",
    "chmod applies exact 0644 permissions",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.2.2 RED coverage is incomplete: {missing}")
    sys.exit(1)

if text.count("test(") != 14:
    print(
        "ERROR: expected exactly 14 Task 10.2.2 tests, "
        f"found {text.count('test(')}."
    )
    sys.exit(1)

print(
    "OK: Task 10.2.2 RED tests are installed and the filesystem "
    "contract and Dart IO adapter are intentionally absent."
)
