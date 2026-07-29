#!/usr/bin/env python3
from pathlib import Path
import re
import sys

paths = {
    "contract": Path(
        "lib/core/notifications/linux_systemd_file_system.dart"
    ),
    "adapter": Path(
        "lib/core/notifications/"
        "dart_io_linux_systemd_file_system.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "dart_io_linux_systemd_file_system_test.dart"
    ),
    "pubspec": Path("pubspec.yaml"),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.2.2 {label} file: {path}")
        sys.exit(1)

contract = paths["contract"].read_text(encoding="utf-8")
adapter = paths["adapter"].read_text(encoding="utf-8")
tests = paths["test"].read_text(encoding="utf-8")
pubspec = paths["pubspec"].read_text(encoding="utf-8")

required_contract = [
    "enum LinuxSystemdEntryType",
    "final class LinuxSystemdUnsafeEntryException",
    "abstract interface class LinuxSystemdFileSystem",
    "Future<void> createDirectory",
    "Future<LinuxSystemdEntryType> typeOf",
    "Future<List<int>> readBytes",
    "Future<void> writeBytes",
    "Future<void> rename",
    "Future<void> deleteFile",
    "Future<void> chmod",
]
required_adapter = [
    "final class DartIoLinuxSystemdFileSystem",
    "FileSystemEntity.type(",
    "followLinks: false",
    "writeAsBytes(",
    "flush: true",
    "LinuxSystemdUnsafeEntryException(",
    "posix.chmodWithMode(path, mode)",
    "Platform.isLinux",
]

for label, text, required in (
    ("contract", contract, required_contract),
    ("adapter", adapter, required_adapter),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(
            f"ERROR: Task 10.2.2 {label} implementation "
            f"is incomplete: {missing}"
        )
        sys.exit(1)

if not re.search(r"(?m)^\s*posix:\s*\^?6\.5\.0\s*$", pubspec):
    print(
        "ERROR: pubspec.yaml must contain dependency posix: ^6.5.0. "
        "Run: flutter pub add posix:^6.5.0"
    )
    sys.exit(1)

if tests.count("test(") != 14:
    print(
        "ERROR: expected exactly 14 focused filesystem tests, "
        f"found {tests.count('test(')}."
    )
    sys.exit(1)

for forbidden in (
    "Process.run",
    "Process.start",
    "/bin/sh",
    "sh -c",
    "systemctl",
):
    if forbidden in adapter:
        print(
            "ERROR: Task 10.2.2 adapter contains forbidden "
            f"command execution: {forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.2.2 link-aware filesystem contract, Dart IO "
    "adapter, POSIX FFI chmod, and 14 focused tests are present."
)
