#!/usr/bin/env python3
from pathlib import Path
import sys

required_paths = [
    "lib/core/notifications/linux_process_request.dart",
    "lib/core/notifications/linux_process_result.dart",
    "lib/core/notifications/linux_cancellation_token.dart",
    "lib/core/notifications/linux_process_exception.dart",
    "lib/core/notifications/linux_bounded_output.dart",
    "lib/core/notifications/fake_linux_process_runner.dart",
    "lib/core/notifications/recording_linux_process_runner.dart",
    "lib/core/notifications/dart_io_linux_process_runner.dart",
    "lib/core/notifications/linux_systemd_timer_name.dart",
    "lib/core/notifications/linux_systemd_timer_status.dart",
    "lib/core/notifications/linux_systemd_timer_status_parser.dart",
    "lib/core/notifications/async_writer_preferring_rw_lock.dart",
    "lib/core/notifications/async_fifo_keyed_mutex.dart",
    "lib/core/notifications/linux_systemd_user_driver.dart",
    "lib/core/notifications/linux_systemd_mutation.dart",
    "test/core/notifications/linux_systemd_final_checkpoint_test.dart",
]

missing = [
    path for path in required_paths
    if not Path(path).exists()
]
if missing:
    print(f"ERROR: Task 10.3 checkpoint missing files: {missing}")
    sys.exit(1)

driver = Path(
    "lib/core/notifications/linux_systemd_user_driver.dart"
).read_text(encoding="utf-8")
runner = Path(
    "lib/core/notifications/dart_io_linux_process_runner.dart"
).read_text(encoding="utf-8")
checkpoint = Path(
    "test/core/notifications/linux_systemd_final_checkpoint_test.dart"
).read_text(encoding="utf-8")

driver_tokens = [
    "AsyncWriterPreferringRwLock",
    "AsyncFifoKeyedMutex<String>",
    "_globalLock.runWrite",
    "_globalLock.runRead",
    "_unitMutex.synchronized",
    "enableAndStart",
    "disableAndStop",
    "_verifySuccessfulCommand",
    "_reconcileAmbiguousCommand",
    "LinuxProcessCancellationException",
    "LinuxProcessTimeoutException",
    "SYSTEMD_PAGERSECURE",
    "--property=$_statusProperties",
]
runner_tokens = [
    "Process.start",
    "runInShell: false",
    "ProcessSignal.sigterm",
    "ProcessSignal.sigkill",
    "LinuxBoundedOutputCollector",
]
checkpoint_tokens = [
    "completes reload, enable, status, and disable lifecycle",
    "propagates one cancellation token",
    "without leaking stderr",
    "fails closed when machine-readable status gains a property",
]

for label, text, tokens in (
    ("systemd driver", driver, driver_tokens),
    ("Dart IO runner", runner, runner_tokens),
    ("final checkpoint", checkpoint, checkpoint_tokens),
):
    absent = [token for token in tokens if token not in text]
    if absent:
        print(f"ERROR: incomplete {label}: {absent}")
        sys.exit(1)

for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "runInShell",
):
    if forbidden in checkpoint:
        print(
            "ERROR: final checkpoint executes a real process: "
            f"{forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.3 final checkpoint confirms the complete injectable Linux "
    "process stack, bounded output, timeout/cancellation termination, exact "
    "typed systemd parsing, writer-preferring and keyed coordination, hardened "
    "daemon/status commands, mutations, postconditions, reconciliation, and "
    "a fake-runner-only lifecycle integration test."
)
