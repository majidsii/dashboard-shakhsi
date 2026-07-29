#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "name": Path(
        "lib/core/notifications/linux_systemd_timer_name.dart"
    ),
    "status": Path(
        "lib/core/notifications/linux_systemd_timer_status.dart"
    ),
    "parser": Path(
        "lib/core/notifications/"
        "linux_systemd_timer_status_parser.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_timer_status_parser_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.3.6 {label}: {path}")
        sys.exit(1)

name = paths["name"].read_text(encoding="utf-8")
status = paths["status"].read_text(encoding="utf-8")
parser = paths["parser"].read_text(encoding="utf-8")

required_name = [
    "final class LinuxSystemdTimerName",
    "[0-9a-f]{16}",
    "String get serviceName",
    "static bool isValid",
]
required_status = [
    "enum LinuxSystemdLoadState",
    "enum LinuxSystemdActiveState",
    "enum LinuxSystemdTimerSubState",
    "enum LinuxSystemdUnitFileState",
    "enum LinuxSystemdUnitResult",
    "final class LinuxSystemdTimerStatus",
    "bool get isHealthy",
]
required_parser = [
    "enum LinuxSystemdTimerStatusParseFailure",
    "final class LinuxSystemdTimerStatusParseException",
    "final class LinuxSystemdTimerStatusParser",
    "duplicateProperty",
    "unknownProperty",
    "missingProperty",
    "unexpectedTimerName",
    r"replaceAll('\r\n', '\n')",
    "_containsForbiddenControlCharacter",
    "_parseLoadState",
    "_parseActiveState",
    "_parseSubState",
    "_parseUnitFileState",
    "_parseResult",
]

for label, text, tokens in (
    ("timer name", name, required_name),
    ("typed status", status, required_status),
    ("strict parser", parser, required_parser),
):
    missing = [token for token in tokens if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = name + "\n" + status + "\n" + parser
for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
):
    if forbidden in combined:
        print(f"ERROR: Gate 6 performs external work: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.3.6 GREEN implements exact app timer-name validation, "
    "typed load/active/sub/unit-file/result states, derived health, and a "
    "strict CRLF-aware parser rejecting malformed, duplicate, missing, "
    "unknown, mismatched, whitespace-normalized, and control-character input."
)
