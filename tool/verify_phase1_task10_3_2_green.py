#!/usr/bin/env python3
from pathlib import Path
import sys

production_path = Path(
    "lib/core/notifications/linux_bounded_output.dart"
)
test_path = Path(
    "test/core/notifications/linux_bounded_output_test.dart"
)

if not production_path.exists():
    print(f"ERROR: missing GREEN production file: {production_path}")
    sys.exit(1)

if not test_path.exists():
    print(f"ERROR: missing RED test: {test_path}")
    sys.exit(1)

text = production_path.read_text(encoding="utf-8")

required = [
    "final class LinuxBoundedOutputCollector",
    "required this.limitBytes",
    "_prefixLimitBytes = limitBytes ~/ 2",
    "_suffixLimitBytes = limitBytes - (limitBytes ~/ 2)",
    "List<int>.filled",
    "_suffixWriteIndex",
    "_totalBytes",
    "allowMalformed: false",
    "allowMalformed: true",
    "Cannot add bytes after bounded output has been finished.",
    "must be in the inclusive range 0..255",
    "_finishedOutput = output",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: GREEN collector is incomplete: {missing}")
    sys.exit(1)

for forbidden in (
    "import 'dart:io'",
    "Process.start",
    "Process.run",
    "systemctl",
    "List<int> _allBytes",
    "_allBytes.addAll",
):
    if forbidden in text:
        print(
            "ERROR: Gate 2 collector contains forbidden or unbounded "
            f"implementation token: {forbidden}"
        )
        sys.exit(1)

if text.count("final class LinuxBoundedOutputCollector") != 1:
    print("ERROR: expected exactly one collector implementation.")
    sys.exit(1)

print(
    "OK: Task 10.3.2 GREEN structure is complete: bounded prefix/suffix "
    "retention, circular suffix storage, strict UTF-8 detection, "
    "idempotent finish, and no process execution."
)
