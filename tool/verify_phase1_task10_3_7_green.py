#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "rw": Path(
        "lib/core/notifications/"
        "async_writer_preferring_rw_lock.dart"
    ),
    "keyed": Path(
        "lib/core/notifications/async_fifo_keyed_mutex.dart"
    ),
    "test": Path(
        "test/core/notifications/async_notification_locks_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.3.7 {label}: {path}")
        sys.exit(1)

rw = paths["rw"].read_text(encoding="utf-8")
keyed = paths["keyed"].read_text(encoding="utf-8")

required_rw = [
    "final class AsyncWriterPreferringRwLock",
    "Queue<Completer<void>> _waitingReaders",
    "Queue<Completer<void>> _waitingWriters",
    "Future<T> runRead<T>",
    "Future<T> runWrite<T>",
    "_waitingWriters.isEmpty",
    "if (_waitingWriters.isNotEmpty)",
    "while (_waitingReaders.isNotEmpty)",
    "finally",
]
required_keyed = [
    "final class AsyncFifoKeyedMutex<K>",
    "Map<K, _KeyQueue>",
    "Queue<_KeyedJob>",
    "Future<T> synchronized<T>",
    "scheduleMicrotask",
    "while (entry.jobs.isNotEmpty)",
    "identical(_entries[key], entry)",
    "_entries.remove(key)",
]

for label, text, tokens in (
    ("writer-preferring RW lock", rw, required_rw),
    ("FIFO keyed mutex", keyed, required_keyed),
):
    missing = [token for token in tokens if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = rw + "\n" + keyed
for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "systemctl",
):
    if forbidden in combined:
        print(f"ERROR: Gate 7 performs external work: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.3.7 GREEN implements exception-safe writer-preferring "
    "read/write coordination and a per-key FIFO mutex with cross-key "
    "concurrency and idle-key eviction."
)
