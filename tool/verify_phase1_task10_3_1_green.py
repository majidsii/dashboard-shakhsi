#!/usr/bin/env python3
from pathlib import Path
import sys

production_dir = Path("lib/core/notifications")
required_files = {
    "linux_process_request.dart": [
        "final class LinuxProcessRequest",
        "Duration(seconds: 15)",
        "Duration(seconds: 2)",
        "256 * 1024",
        "List<String>.unmodifiable",
        "Map<String, String>.unmodifiable",
    ],
    "linux_bounded_output.dart": [
        "final class LinuxBoundedOutput",
        "final int totalBytes",
        "final bool malformedUtf8",
    ],
    "linux_process_result.dart": [
        "final class LinuxProcessResult",
        "LinuxBoundedOutput stdout",
        "LinuxBoundedOutput stderr",
    ],
    "linux_cancellation_token.dart": [
        "abstract interface class LinuxCancellationToken",
        "final class LinuxCancellationSource",
        "Completer<void>.sync()",
    ],
    "linux_process_exception.dart": [
        "abstract class LinuxProcessException",
        "LinuxProcessStartException",
        "LinuxProcessTimeoutException",
        "LinuxProcessCancellationException",
        "LinuxProcessStreamException",
        "LinuxProcessTerminationException",
    ],
    "linux_process_runner.dart": [
        "abstract interface class LinuxProcessRunner",
        "LinuxCancellationToken? cancellationToken",
    ],
}

missing_files = []
missing_tokens = []

for name, tokens in required_files.items():
    path = production_dir / name
    if not path.exists():
        missing_files.append(str(path))
        continue

    text = path.read_text(encoding="utf-8")
    for token in tokens:
        if token not in text:
            missing_tokens.append(f"{path}: {token}")

if missing_files:
    print(f"ERROR: missing GREEN production files: {missing_files}")
    sys.exit(1)

if missing_tokens:
    print(f"ERROR: incomplete GREEN implementation: {missing_tokens}")
    sys.exit(1)

combined = "\n".join(
    (production_dir / name).read_text(encoding="utf-8")
    for name in required_files
)

for forbidden in (
    "import 'dart:io'",
    "Process.start",
    "Process.run",
    "runInShell",
    "systemctl --user",
    "sh -c",
    "bash -c",
):
    if forbidden in combined:
        print(
            "ERROR: Gate 1 must not execute child processes; "
            f"found forbidden token: {forbidden}"
        )
        sys.exit(1)

test_path = Path(
    "test/core/notifications/linux_process_request_test.dart"
)
if not test_path.exists():
    print(f"ERROR: missing RED test: {test_path}")
    sys.exit(1)

plan_path = Path(
    "docs/superpowers/plans/"
    "2026-07-29-linux-systemctl-user-command-driver-implementation.md"
)
if not plan_path.exists():
    print(f"ERROR: missing corrected implementation plan: {plan_path}")
    sys.exit(1)

print(
    "OK: Task 10.3.1 GREEN structure is complete: immutable request, "
    "bounded-output value, result, cancellation, lifecycle exceptions, "
    "and injectable runner contract; no process execution was added."
)
