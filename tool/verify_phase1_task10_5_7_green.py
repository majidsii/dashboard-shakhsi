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
        "linux_systemd_notification_scheduler_cancel_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.7 {label}: {path}")
        sys.exit(1)

scheduler = paths["scheduler"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_scheduler = [
    "LinuxSystemdUnitRemoveTransaction? transaction",
    "var registryReplaceAttempted = false",
    "_unitStore.beginRemove(names)",
    "_driver.disableAndStop(timerName)",
    "action: transaction.apply",
    "action: _driver.reloadDaemon",
    "if (existing != null)",
    "registryReplaceAttempted = true",
    "_registryStore.replace(nextRegistry)",
    "action: transaction.finalize",
    "_rollbackFailedCancel(",
    "step: 'rollback-remove-transaction'",
    "step: 'reload-after-remove-restore'",
    "step: 'load-registry-for-cancel-restore'",
    "step: 'restore-registry-after-cancel'",
    "step: 're-enable-canceled-timer'",
    "currentGeneration > previousGeneration",
    "generation: baseGeneration + 1",
    "entries: previousRegistry.entries",
    "expandUnitStoreFailures: true",
    "LinuxSystemdNotificationSchedulerFailure.rollbackFailed",
    "Error.throwWithStackTrace(error, stackTrace)",
]
required_test = [
    "complete happy path uses the exact successful operation order",
    "completely missing state is an idempotent typed cleanup",
    "registry-only state removes the logical entry",
    "unit-only state removes orphan files without writing registry",
    "already-disabled status is accepted as typed success",
    "begin remove failure performs no rollback or driver mutation",
    "raw nonzero disable is not ignored and previous timer is restored",
    "apply failure restores files, reloads, and re-enables timer",
    "daemon reload failure performs ordered remove rollback",
    "registry failure restores prior inventory monotonically",
    "finalize failure restores registry and previous timer",
    "registry failure restores exact",
    "clean rollback rethrows the identical cancellation",
    "same(cancellation)",
    "greaterThan(previous.generation)",
]

for label, text, required in (
    ("cancel implementation", scheduler, required_scheduler),
    ("cancel tests", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

for forbidden in (
    "Process.start",
    "Process.run",
    "Directory.systemTemp",
    "UnimplementedError",
    "TODO",
    "FIXME",
):
    if forbidden in scheduler:
        print(
            "ERROR: Task 10.5.7 contains direct process execution or "
            f"placeholder behavior: {forbidden}"
        )
        sys.exit(1)

cancel_start = scheduler.find("Future<void> _cancelUnlocked(")
rollback_start = scheduler.find(
    "_rollbackFailedCancel({",
    cancel_start,
)
step_start = scheduler.find("Future<T> _step<T>", rollback_start)

if not (-1 < cancel_start < rollback_start < step_start):
    print("ERROR: cancel and rollback helper boundaries are invalid.")
    sys.exit(1)

cancel_body = scheduler[cancel_start:rollback_start]
rollback_body = scheduler[rollback_start:step_start]

if "if (existing == null)" in cancel_body:
    print(
        "ERROR: cancel still returns early when registry inventory is "
        "missing, leaving orphan units behind."
    )
    sys.exit(1)

load_index = cancel_body.find("action: _registryStore.load")
begin_index = cancel_body.find("_unitStore.beginRemove(names)")
disable_index = cancel_body.find("_driver.disableAndStop(timerName)")
apply_index = cancel_body.find("action: transaction.apply")
reload_index = cancel_body.find("action: _driver.reloadDaemon")
existing_index = cancel_body.find("if (existing != null)")
replace_index = cancel_body.find(
    "_registryStore.replace(nextRegistry)",
    existing_index,
)
finalize_index = cancel_body.find("action: transaction.finalize")

if not (
    -1
    < load_index
    < begin_index
    < disable_index
    < apply_index
    < reload_index
    < existing_index
    < replace_index
    < finalize_index
):
    print("ERROR: successful cancel operation order is incorrect.")
    sys.exit(1)

rollback_transaction_index = rollback_body.find(
    "step: 'rollback-remove-transaction'"
)
rollback_reload_index = rollback_body.find(
    "step: 'reload-after-remove-restore'"
)
restore_registry_index = rollback_body.find(
    "step: 'restore-registry-after-cancel'"
)
reenable_index = rollback_body.find(
    "step: 're-enable-canceled-timer'"
)

if not (
    -1
    < rollback_transaction_index
    < rollback_reload_index
    < restore_registry_index
    < reenable_index
):
    print("ERROR: cancel rollback order is incorrect.")
    sys.exit(1)

if cancel_body.find("registryReplaceAttempted = true") > replace_index:
    print(
        "ERROR: registry replace attempt is not tracked before mutation."
    )
    sys.exit(1)

if "on LinuxProcessCancellationException" not in scheduler[step_start:]:
    print("ERROR: cancellation is not preserved by the scheduler step wrapper.")
    sys.exit(1)

for pair in ("serviceOnly", "timerOnly", "complete"):
    if pair not in test:
        print(f"ERROR: exact retained-file test missing: {pair}")
        sys.exit(1)

print(
    "OK: Task 10.5.7 GREEN cancels missing, registry-only, unit-only, "
    "complete, and already-disabled schedules; enforces typed disable "
    "evidence; removes orphan units without unnecessary registry writes; "
    "performs ordered retained-remove rollback, daemon reload, monotonic "
    "registry restoration, and evidence-based timer re-enable; expands "
    "unit-store rollback failures; and preserves the identical cancellation "
    "when cleanup succeeds."
)
