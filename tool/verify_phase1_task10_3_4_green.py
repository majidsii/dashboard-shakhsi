#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "started": Path(
        "lib/core/notifications/linux_started_process.dart"
    ),
    "starter": Path(
        "lib/core/notifications/linux_process_starter.dart"
    ),
    "runner": Path(
        "lib/core/notifications/dart_io_linux_process_runner.dart"
    ),
    "test": Path(
        "test/core/notifications/dart_io_linux_process_runner_test.dart"
    ),
    "support": Path(
        "test/support/fake_linux_started_process.dart"
    ),
}

for name, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.3.4 {name} file: {path}")
        sys.exit(1)

started = paths["started"].read_text(encoding="utf-8")
starter = paths["starter"].read_text(encoding="utf-8")
runner = paths["runner"].read_text(encoding="utf-8")

required_started = [
    "enum LinuxProcessSignal",
    "sigterm",
    "sigkill",
    "abstract interface class LinuxStartedProcess",
    "Stream<List<int>> get stdout",
    "Stream<List<int>> get stderr",
    "Future<int> get exitCode",
    "bool kill(LinuxProcessSignal signal)",
]
required_starter = [
    "abstract interface class LinuxProcessStarter",
    "final class DartIoLinuxProcessStarter",
    "Process.start",
    "runInShell: false",
    "includeParentEnvironment: request.includeParentEnvironment",
    "ProcessStartMode.normal",
]
required_runner = [
    "final class DartIoLinuxProcessRunner",
    "Future.wait<_CapturedLinuxProcessStream>",
    "LinuxBoundedOutputCollector",
    "LinuxProcessStreamKind.stdout",
    "LinuxProcessStreamKind.stderr",
    "LinuxProcessStartException",
    "LinuxProcessStreamException",
    "cancelOnError: false",
]

for label, text, tokens in (
    ("started process", started, required_started),
    ("process starter", starter, required_starter),
    ("process runner", runner, required_runner),
):
    missing = [token for token in tokens if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = starter + "\n" + runner
for forbidden in (
    "Process.run",
    "runInShell: true",
    "/bin/sh",
    "bash -c",
    "sh -c",
):
    if forbidden in combined:
        print(f"ERROR: unsafe process execution token: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.3.4 GREEN structure is complete: injectable starter, "
    "typed started-process abstraction, shell-free Process.start, "
    "concurrent bounded stdout/stderr draining, safe start failures, "
    "and stream failure mapping."
)
