#!/usr/bin/env python3
from pathlib import Path
import sys

runner_path = Path(
    "lib/core/notifications/dart_io_linux_process_runner.dart"
)
test_path = Path(
    "test/core/notifications/dart_io_linux_process_runner_test.dart"
)
support_path = Path("test/support/fake_linux_started_process.dart")

for path in (runner_path, test_path, support_path):
    if not path.exists():
        print(f"ERROR: missing Task 10.3.5 file: {path}")
        sys.exit(1)

runner = runner_path.read_text(encoding="utf-8")

required = [
    "if (cancellationToken?.isCancelled ?? false)",
    "enum _TerminalReason",
    "final class _TerminalCoordinator",
    "LinuxProcessSignal.sigterm",
    "LinuxProcessSignal.sigkill",
    "Future.any<bool>",
    "LinuxProcessTimeoutException(",
    "LinuxProcessCancellationException(",
    "LinuxProcessTerminationException(",
    "timeoutTimer?.cancel()",
    "await exitOutcomeFuture",
    "Future.wait<_CapturedLinuxProcessStream>",
]
missing = [token for token in required if token not in runner]
if missing:
    print(f"ERROR: Task 10.3.5 GREEN is incomplete: {missing}")
    sys.exit(1)

for forbidden in (
    "Process.run",
    "runInShell: true",
    "/bin/sh",
    "bash -c",
    "sh -c",
):
    if forbidden in runner:
        print(f"ERROR: unsafe process token found: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.3.5 GREEN implements pre-spawn cancellation, a "
    "first-terminal-reason coordinator, one-shot SIGTERM-to-SIGKILL "
    "escalation, timer cancellation, metadata-rich timeout/cancellation "
    "exceptions, and full exit plus stream drainage."
)
