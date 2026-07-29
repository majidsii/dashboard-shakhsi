#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "exception": Path(
        "lib/core/notifications/"
        "linux_systemd_user_unit_store_exception.dart"
    ),
    "fake": Path(
        "test/support/fake_linux_systemd_file_system.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_store_install_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.2.3 {label} file: {path}")
        sys.exit(1)

exception = paths["exception"].read_text(encoding="utf-8")
fake = paths["fake"].read_text(encoding="utf-8")
tests = paths["test"].read_text(encoding="utf-8")

required_exception = [
    "enum LinuxSystemdUserUnitStoreOperation",
    "final class LinuxSystemdRollbackFailure",
    "final class LinuxSystemdUserUnitStoreException",
    "List<LinuxSystemdRollbackFailure>.unmodifiable",
    "rollbackFailures: ${rollbackFailures.length}",
]
required_fake = [
    "final class FakeLinuxSystemdFileSystem",
    "implements LinuxSystemdFileSystem",
    "Queue<Object>",
    "void failNext(",
    "List<int>.from(bytes)",
    "rename:$sourcePath->$destinationPath",
    "LinuxSystemdUnsafeEntryException",
    "operations.add(operation)",
]

for label, text, required in (
    ("exception", exception, required_exception),
    ("fake", fake, required_fake),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(
            f"ERROR: Task 10.2.3 {label} implementation "
            f"is incomplete: {missing}"
        )
        sys.exit(1)

if tests.count("test(") != 13:
    print(
        "ERROR: expected exactly 13 focused harness tests, "
        f"found {tests.count('test(')}."
    )
    sys.exit(1)

for forbidden in (
    "dart:io",
    "Directory.systemTemp",
    "Platform.environment",
):
    if forbidden in fake:
        print(
            "ERROR: fake filesystem must not access the real "
            f"environment or filesystem: {forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.2.3 immutable store errors, failure-injectable "
    "fake filesystem, and 13 focused tests are present."
)
