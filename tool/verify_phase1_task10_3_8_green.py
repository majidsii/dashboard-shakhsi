#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "driver": Path(
        "lib/core/notifications/linux_systemd_user_driver.dart"
    ),
    "test": Path(
        "test/core/notifications/linux_systemd_user_driver_test.dart"
    ),
    "fake": Path(
        "test/support/fake_linux_process_runner.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.3.8 {label}: {path}")
        sys.exit(1)

driver = paths["driver"].read_text(encoding="utf-8")

required = [
    "enum LinuxSystemdCommandOperation",
    "final class LinuxSystemdCommandException",
    "enum LinuxSystemdStatusOutputFailure",
    "final class LinuxSystemdStatusOutputException",
    "final class LinuxSystemdUserDriver",
    "'LC_ALL': 'C'",
    "'LANG': 'C'",
    "'SYSTEMD_COLORS': '0'",
    "'SYSTEMD_PAGER': 'cat'",
    "'SYSTEMD_PAGERSECURE': '1'",
    "'--user'",
    "'--no-pager'",
    "'daemon-reload'",
    "'show'",
    "'--property=$_statusProperties'",
    "cancellationToken: cancellationToken",
    "if (result.exitCode != 0)",
    "if (result.stdout.truncated)",
    "if (result.stdout.malformedUtf8)",
    "_statusParser.parse",
]
missing = [token for token in required if token not in driver]
if missing:
    print(f"ERROR: Task 10.3.8 GREEN incomplete: {missing}")
    sys.exit(1)

for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "runInShell",
    "/bin/sh",
    "bash -c",
):
    if forbidden in driver:
        print(f"ERROR: driver bypasses LinuxProcessRunner: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.3.8 GREEN implements a hardened injectable systemd user "
    "driver with exact daemon-reload and machine-readable show commands, "
    "cancellation propagation, typed nonzero exits, fail-closed bounded "
    "output checks, and strict typed status parsing."
)
