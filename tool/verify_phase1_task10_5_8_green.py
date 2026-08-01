#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "scheduler": Path(
        "lib/core/notifications/"
        "linux_systemd_notification_scheduler.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_concurrency_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.8 {label}: {path}")
        sys.exit(1)

scheduler = paths["scheduler"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_scheduler = [
    "return _globalLock.runWrite(",
    "() => _cancelByOwnerUnlocked(owner)",
    "Future<void> _cancelByOwnerUnlocked(",
    "entry.owner == owner",
    ".map((entry) => entry.scheduleId)",
    "..sort()",
    "for (final scheduleId in scheduleIds)",
    "registrySnapshot: workingRegistry",
    "completedScheduleIds.add(scheduleId)",
    "partialOwnerCancellation",
    "scheduleId: scheduleId",
    "completedScheduleIds: completedScheduleIds",
    "LinuxSystemdScheduleRegistry? registrySnapshot",
    "registrySnapshot ??",
]
required_test = [
    "same schedule ID operations are FIFO and never overlap",
    "different schedule IDs overlap under the global read lock",
    "cancelByOwner waits for an active read operation",
    "new reads wait behind an already queued writer",
    "matches owners exactly and cancels sorted schedule IDs",
    "no exact owner matches is idempotent",
    "first failed schedule stops the sorted batch",
    "partial exception has failing ID and immutable completed IDs",
    "throwsUnsupportedError",
]

for label, text, required in (
    ("owner-cancellation implementation", scheduler, required_scheduler),
    ("controlled concurrency tests", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

for forbidden in (
    "Process.start",
    "Process.run",
    "Directory.systemTemp",
    "systemctl --user",
    "Future.delayed(const Duration(milliseconds:",
    "UnimplementedError",
    "TODO",
    "FIXME",
):
    if forbidden in f"{scheduler}\n{test}":
        print(
            "ERROR: Task 10.5.8 contains external, timing-based, or "
            f"placeholder behavior: {forbidden}"
        )
        sys.exit(1)

public_start = scheduler.find(
    "Future<void> cancelByOwner(NotificationOwner owner)"
)
helper_start = scheduler.find(
    "Future<void> _cancelByOwnerUnlocked(",
    public_start,
)
reconcile_start = scheduler.find(
    "Future<void> reconcile(",
    helper_start,
)
if not (-1 < public_start < helper_start < reconcile_start):
    print("ERROR: owner-cancellation method boundaries are invalid.")
    sys.exit(1)

public_body = scheduler[public_start:helper_start]
helper_body = scheduler[helper_start:reconcile_start]

if "_globalLock.runWrite" not in public_body:
    print("ERROR: cancelByOwner does not hold the global write lock.")
    sys.exit(1)

for forbidden_lock in (
    "_globalLock.runRead",
    "_globalLock.runWrite",
    "_scheduleMutex.synchronized",
):
    if forbidden_lock in helper_body:
        print(
            "ERROR: owner batch reacquires scheduler locks: "
            f"{forbidden_lock}"
        )
        sys.exit(1)

if helper_body.count("_registryStore.load") != 1:
    print(
        "ERROR: cancelByOwner must load the registry exactly once; "
        f"found {helper_body.count('_registryStore.load')} loads."
    )
    sys.exit(1)

load_index = helper_body.find("_registryStore.load")
match_index = helper_body.find("entry.owner == owner", load_index)
sort_index = helper_body.find("..sort()", match_index)
loop_index = helper_body.find(
    "for (final scheduleId in scheduleIds)",
    sort_index,
)
cancel_index = helper_body.find(
    "await _cancelUnlocked(",
    loop_index,
)
snapshot_index = helper_body.find(
    "registrySnapshot: workingRegistry",
    cancel_index,
)
completed_index = helper_body.find(
    "completedScheduleIds.add(scheduleId)",
    snapshot_index,
)

if not (
    -1
    < load_index
    < match_index
    < sort_index
    < loop_index
    < cancel_index
    < snapshot_index
    < completed_index
):
    print(
        "ERROR: owner batch does not load, filter, sort, cancel, and "
        "record completion in the required order."
    )
    sys.exit(1)

catch_index = helper_body.find("catch (error, stackTrace)", loop_index)
partial_index = helper_body.find(
    "partialOwnerCancellation",
    catch_index,
)
failing_id_index = helper_body.find(
    "scheduleId: scheduleId",
    partial_index,
)
completed_evidence_index = helper_body.find(
    "completedScheduleIds: completedScheduleIds",
    failing_id_index,
)

if not (
    -1
    < catch_index
    < partial_index
    < failing_id_index
    < completed_evidence_index
):
    print("ERROR: partial owner-cancellation evidence is incomplete.")
    sys.exit(1)

cancel_start = scheduler.find("Future<void> _cancelUnlocked(")
cancel_end = scheduler.find(
    "Future<List<LinuxSystemdSchedulerRollbackFailure>>",
    cancel_start,
)
cancel_body = scheduler[cancel_start:cancel_end]

if "LinuxSystemdScheduleRegistry? registrySnapshot" not in cancel_body:
    print("ERROR: unlocked cancel cannot consume the batch snapshot.")
    sys.exit(1)

snapshot_load = cancel_body.find("registrySnapshot ??")
store_load = cancel_body.find("_registryStore.load", snapshot_load)
if not (-1 < snapshot_load < store_load):
    print(
        "ERROR: unlocked cancel does not prefer the supplied registry "
        "snapshot before loading."
    )
    sys.exit(1)

print(
    "OK: Task 10.5.8 GREEN preserves keyed FIFO read operations, uses the "
    "writer-preferring global lock for owner batches, loads registry inventory "
    "once, filters exact owner values, sorts schedule IDs deterministically, "
    "calls unlocked cancellation without lock reacquisition, advances the "
    "working snapshot after each success, stops at the first failure, and "
    "reports immutable completed-ID evidence with the failing schedule."
)
