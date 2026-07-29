#!/usr/bin/env python3
from pathlib import Path
import sys

fake_path = Path("test/support/fake_linux_process_runner.dart")
recording_path = Path(
    "test/support/recording_linux_process_runner.dart"
)
test_path = Path(
    "test/core/notifications/linux_process_test_doubles_test.dart"
)

for path in (fake_path, recording_path, test_path):
    if not path.exists():
        print(f"ERROR: missing Task 10.3.3 file: {path}")
        sys.exit(1)

fake = fake_path.read_text(encoding="utf-8")
recording = recording_path.read_text(encoding="utf-8")

fake_required = [
    "final class FakeLinuxProcessRunner implements LinuxProcessRunner",
    "Queue<_FakeLinuxProcessResponse>",
    "void enqueueResult",
    "void enqueueFailure",
    "ControlledLinuxProcessCall enqueueControlled",
    "int get pendingResponseCount",
    "No fake Linux process response is queued",
    "final class ControlledLinuxProcessInvocation",
    "Future<ControlledLinuxProcessInvocation> get invocation",
    "Future<void> get whenCancellationObserved",
    "bool complete(LinuxProcessResult result)",
    "bool fail(Object error, StackTrace stackTrace)",
    "Error.throwWithStackTrace",
]
missing_fake = [token for token in fake_required if token not in fake]
if missing_fake:
    print(f"ERROR: fake runner is incomplete: {missing_fake}")
    sys.exit(1)

recording_required = [
    "final class RecordedLinuxProcessCall",
    "final class RecordingLinuxProcessRunner implements LinuxProcessRunner",
    "List<RecordedLinuxProcessCall>.unmodifiable",
    "final snapshot = LinuxProcessRequest",
    "sequence: _nextSequence++",
    "return _delegate.run",
]
missing_recording = [
    token for token in recording_required if token not in recording
]
if missing_recording:
    print(f"ERROR: recording runner is incomplete: {missing_recording}")
    sys.exit(1)

combined = fake + "\n" + recording
for forbidden in (
    "import 'dart:io'",
    "Process.start",
    "Process.run",
    "runInShell",
    "systemctl --user",
):
    if forbidden in combined:
        print(
            "ERROR: Task 10.3.3 test doubles must not execute processes; "
            f"found: {forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.3.3 GREEN structure is complete: FIFO scripted "
    "responses, controlled completion and failure, cancellation "
    "observation, immutable recording, and no real process execution."
)
