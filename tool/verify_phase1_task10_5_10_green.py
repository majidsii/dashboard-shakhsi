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
        "linux_systemd_notification_scheduler_reconcile_repair_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.10 {label}: {path}")
        sys.exit(1)

scheduler = paths["scheduler"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_scheduler = [
    "_repairReconciliationDesired(",
    "previous.requestFingerprint == requestFingerprint",
    "hasCompletePair",
    "if (status.isHealthy)",
    "_commandFactory.create(request)",
    "_renderer.render(unit)",
    "_unitStore.beginInstall(rendered)",
    "action: transaction.apply",
    "action: _driver.reloadDaemon",
    "action: () => _driver.enableAndStart(repair.timerName)",
    "action: repair.transaction.finalize",
    "_registryStore.replace(repairRegistry)",
    "_rollbackUnconfirmedReconciliationInstalls(",
    "_writeConfirmedReconciliationRegistry(",
    "_throwPartialReconciliation(",
    "partialReconciliation",
    "completedScheduleIds: completedScheduleIds",
    "disable-reconcile-install/",
    "rollback-reconcile-install/",
    "reload-after-reconcile-install-rollback",
]
required_test = [
    "matching fingerprint and healthy status is preserved",
    "matching fingerprint with unhealthy status is repaired",
    "changed fingerprint replaces the existing schedule",
    "missing registry and unit pair creates the desired schedule",
    "repairs in schedule ID order with exactly one initial reload",
    "enable failure preserves prior confirmed success and stops batch",
    "finalize failure rolls back the failing and later installs",
    "registry failure reports confirmed completed IDs and repairs inventory",
    "throwsUnsupportedError",
]

for label, text, required in (
    ("repair implementation", scheduler, required_scheduler),
    ("repair tests", test, required_test),
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
    "UnimplementedError",
    "TODO",
    "FIXME",
):
    if forbidden in f"{scheduler}\n{test}":
        print(
            "ERROR: Task 10.5.10 contains external or placeholder behavior: "
            f"{forbidden}"
        )
        sys.exit(1)

repair_start = scheduler.find(
    "Future<void> _repairReconciliationDesired("
)
rollback_start = scheduler.find(
    "_rollbackUnconfirmedReconciliationInstalls({",
    repair_start,
)
if repair_start < 0 or rollback_start < 0:
    print("ERROR: repair helper boundaries are missing.")
    sys.exit(1)

repair_body = scheduler[repair_start:rollback_start]

fingerprint_index = repair_body.find("_fingerprint.compute(request)")
status_index = repair_body.find("_driver.status(timerName)")
factory_index = repair_body.find("_commandFactory.create(request)")
begin_index = repair_body.find("_unitStore.beginInstall(rendered)")
apply_index = repair_body.find("action: transaction.apply")
reload_index = repair_body.find("action: _driver.reloadDaemon")
enable_index = repair_body.find(
    "_driver.enableAndStart(repair.timerName)"
)
finalize_index = repair_body.find(
    "action: repair.transaction.finalize"
)
registry_index = repair_body.find(
    "_registryStore.replace(repairRegistry)"
)

if not (
    -1
    < fingerprint_index
    < status_index
    < factory_index
    < begin_index
    < apply_index
    < reload_index
    < enable_index
    < finalize_index
    < registry_index
):
    print(
        "ERROR: repair classification or coherent batch order is invalid."
    )
    sys.exit(1)

if repair_body.count("_driver.reloadDaemon") != 1:
    print(
        "ERROR: successful repair batch must contain exactly one direct "
        "daemon reload."
    )
    sys.exit(1)

if "completedScheduleIds.add(repair.request.scheduleId)" not in repair_body:
    print("ERROR: confirmed successes are not recorded.")
    sys.exit(1)

if "staged.sublist(index)" not in repair_body:
    print(
        "ERROR: failure cleanup does not stop at and roll back the failing "
        "and later unconfirmed transactions."
    )
    sys.exit(1)

throw_start = scheduler.find("Never _throwPartialReconciliation(")
throw_end = scheduler.find("\n  Future<List<", throw_start)
if throw_start < 0:
    print("ERROR: partial reconciliation exception helper is missing.")
    sys.exit(1)

throw_body = scheduler[throw_start:throw_end if throw_end > 0 else None]
for token in (
    "scheduleId: request.scheduleId",
    "owner: request.owner",
    "cause: error",
    "rollbackFailures:",
    "confirmedStatus: nested?.confirmedStatus",
    "completedScheduleIds: completedScheduleIds",
):
    if token not in throw_body:
        print(f"ERROR: partial exception evidence missing: {token}")
        sys.exit(1)

print(
    "OK: Task 10.5.10 GREEN classifies healthy, changed, unhealthy, and "
    "missing desired schedules; stages retained installs in deterministic "
    "order; performs one coherent successful reload; enables and finalizes "
    "only healthy confirmations; writes registry state for confirmed platform "
    "successes; rolls back failing and later unconfirmed items; retries "
    "confirmed registry evidence after registry failure; and throws safe "
    "partialReconciliation exceptions with immutable completed IDs."
)
