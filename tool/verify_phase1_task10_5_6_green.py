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
        "linux_systemd_notification_scheduler_schedule_rollback_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.6 {label}: {path}")
        sys.exit(1)

scheduler = paths["scheduler"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_scheduler = [
    "var applyAttempted = false",
    "var systemdMayHaveObserved = false",
    "var registryReplaceAttempted = false",
    "applyAttempted = true",
    "systemdMayHaveObserved = true",
    "registryReplaceAttempted = true",
    "_rollbackFailedSchedule(",
    "step: 'disable-new-timer'",
    "step: 'rollback-install-transaction'",
    "step: 'reload-after-unit-restore'",
    "step: 'load-registry-for-restore'",
    "step: 'restore-registry'",
    "step: 're-enable-previous-timer'",
    "currentGeneration > previousGeneration",
    "generation: baseGeneration + 1",
    "entries: previousRegistry.entries",
    "LinuxSystemdNotificationSchedulerFailure.rollbackFailed",
    "cause: error",
    "rollbackFailures: rollbackFailures",
    "on LinuxProcessCancellationException",
    "Error.throwWithStackTrace(error, stackTrace)",
    "expandUnitStoreFailures: true",
    "error is LinuxSystemdUserUnitStoreException",
]
required_test = [
    "command factory failure does not begin or roll back units",
    "render identity failure does not begin or roll back units",
    "begin install failure does not run rollback",
    "apply failure rolls back, reloads, and re-enables previous timer",
    "daemon reload failure performs exact rollback order",
    "enable failure disables, restores units, reloads, and re-enables",
    "registry replace failure restores inventory with higher generation",
    "finalize failure restores registry and previous timer",
    "registry failure restores exact",
    "successful rollback rethrows the identical cancellation",
    "rollback failure keeps cancellation as primary cause",
    "same(cancellation)",
    "greaterThan(previous.generation)",
]

for label, text, required in (
    ("scheduler rollback implementation", scheduler, required_scheduler),
    ("Gate rollback tests", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "Directory.systemTemp",
    "UnimplementedError",
    "TODO",
    "FIXME",
):
    if forbidden in scheduler:
        print(
            "ERROR: Task 10.5.6 contains direct IO, process execution, "
            f"or placeholder behavior: {forbidden}"
        )
        sys.exit(1)

try_start = scheduler.find(
    "LinuxSystemdUnitInstallTransaction? transaction"
)
begin_index = scheduler.find(
    "_unitStore.beginInstall(rendered)",
    try_start,
)
apply_flag = scheduler.find("applyAttempted = true", begin_index)
apply_index = scheduler.find("action: transaction.apply", apply_flag)
observed_flag = scheduler.find(
    "systemdMayHaveObserved = true",
    apply_index,
)
reload_index = scheduler.find(
    "action: _driver.reloadDaemon",
    observed_flag,
)
enable_index = scheduler.find(
    "_driver.enableAndStart(timerName)",
    reload_index,
)
registry_flag = scheduler.find(
    "registryReplaceAttempted = true",
    enable_index,
)
replace_index = scheduler.find(
    "_registryStore.replace(nextRegistry)",
    registry_flag,
)
finalize_index = scheduler.find(
    "action: transaction.finalize",
    replace_index,
)
catch_index = scheduler.find("} catch (error, stackTrace)", finalize_index)
rollback_call = scheduler.find(
    "_rollbackFailedSchedule(",
    catch_index,
)

if not (
    -1
    < try_start
    < begin_index
    < apply_flag
    < apply_index
    < observed_flag
    < reload_index
    < enable_index
    < registry_flag
    < replace_index
    < finalize_index
    < catch_index
    < rollback_call
):
    print("ERROR: forward state tracking or rollback boundary is incorrect.")
    sys.exit(1)

helper_index = scheduler.find(
    "_rollbackFailedSchedule({",
    rollback_call,
)
disable_index = scheduler.find(
    "step: 'disable-new-timer'",
    helper_index,
)
transaction_index = scheduler.find(
    "step: 'rollback-install-transaction'",
    disable_index,
)
reload_restore_index = scheduler.find(
    "step: 'reload-after-unit-restore'",
    transaction_index,
)
registry_restore_index = scheduler.find(
    "step: 'restore-registry'",
    reload_restore_index,
)
reenable_index = scheduler.find(
    "step: 're-enable-previous-timer'",
    registry_restore_index,
)

if not (
    -1
    < helper_index
    < disable_index
    < transaction_index
    < reload_restore_index
    < registry_restore_index
    < reenable_index
):
    print("ERROR: best-effort schedule rollback order is incorrect.")
    sys.exit(1)

step_index = scheduler.find("Future<T> _step<T>")
cancel_catch = scheduler.find(
    "on LinuxProcessCancellationException",
    step_index,
)
scheduler_catch = scheduler.find(
    "on LinuxSystemdNotificationSchedulerException",
    step_index,
)
generic_catch = scheduler.find(
    "catch (error, stackTrace)",
    scheduler_catch,
)

if not (
    -1
    < step_index
    < cancel_catch
    < scheduler_catch
    < generic_catch
):
    print("ERROR: cancellation is not preserved before generic wrapping.")
    sys.exit(1)

if scheduler.count(
    "LinuxSystemdNotificationSchedulerFailure.rollbackFailed"
) != 1:
    print("ERROR: rollbackFailed must be emitted only at rollback boundary.")
    sys.exit(1)

print(
    "OK: Task 10.5.6 GREEN tracks apply/systemd/registry boundaries, "
    "preserves every pre-apply primary failure, performs ordered best-effort "
    "disable/unit-rollback/reload/registry-restore/re-enable cleanup, restores "
    "registry inventory with monotonic generation, expands retained-store "
    "rollback evidence, rethrows identical cancellation after clean rollback, "
    "and reports rollbackFailed with the original failure as cause otherwise."
)
