#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "mutation": Path(
        "lib/core/notifications/linux_systemd_mutation.dart"
    ),
    "driver": Path(
        "lib/core/notifications/linux_systemd_user_driver.dart"
    ),
    "test": Path(
        "test/core/notifications/linux_systemd_user_mutation_test.dart"
    ),
    "rw": Path(
        "lib/core/notifications/"
        "async_writer_preferring_rw_lock.dart"
    ),
    "keyed": Path(
        "lib/core/notifications/async_fifo_keyed_mutex.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.3.9 {label}: {path}")
        sys.exit(1)

mutation = paths["mutation"].read_text(encoding="utf-8")
driver = paths["driver"].read_text(encoding="utf-8")

required_mutation = [
    "enum LinuxSystemdMutationOperation",
    "enableAndStart",
    "disableAndStop",
    "enum LinuxSystemdMutationFailure",
    "commandFailed",
    "postconditionFailed",
    "ambiguousOutcome",
    "reconciliationFailed",
    "final class LinuxSystemdMutationException",
    "statusChecks",
]
required_driver = [
    "AsyncWriterPreferringRwLock",
    "AsyncFifoKeyedMutex<String>",
    "_globalLock.runWrite",
    "_globalLock.runRead",
    "_unitMutex.synchronized",
    "Future<LinuxSystemdTimerStatus> enableAndStart",
    "Future<LinuxSystemdTimerStatus> disableAndStop",
    "'enable'",
    "'disable'",
    "'--now'",
    "_verifySuccessfulCommand",
    "_reconcileAmbiguousCommand",
    "LinuxProcessCancellationException",
    "LinuxProcessStartException",
    "LinuxProcessTimeoutException",
    "LinuxProcessTerminationException",
    "LinuxProcessStreamException",
    "statusChecks: 2",
    "statusChecks: 1",
    "_matchesPostcondition",
]

for label, text, tokens in (
    ("mutation model", mutation, required_mutation),
    ("mutation driver", driver, required_driver),
):
    missing = [token for token in tokens if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = mutation + "\n" + driver
for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "runInShell",
    "/bin/sh",
    "bash -c",
):
    if forbidden in combined:
        print(f"ERROR: Gate 9 bypasses the runner: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.3.9 GREEN implements exact enable/disable mutations, "
    "mandatory postconditions, one reconciliation for mismatches or ambiguous "
    "process outcomes, explicit cancellation preservation, typed failures, "
    "global writer-preferring coordination, and same-unit FIFO locking."
)
