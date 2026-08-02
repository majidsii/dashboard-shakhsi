#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "scheduler": Path(
        "lib/core/notifications/"
        "linux_systemd_notification_scheduler.dart"
    ),
    "schedule_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_schedule_test.dart"
    ),
    "inventory_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_reconcile_inventory_test.dart"
    ),
    "repair_test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_reconcile_repair_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.10 v2 {label}: {path}")
        sys.exit(1)

scheduler = paths["scheduler"].read_text(encoding="utf-8")
schedule_test = paths["schedule_test"].read_text(encoding="utf-8")
inventory_test = paths["inventory_test"].read_text(encoding="utf-8")
repair_test = paths["repair_test"].read_text(encoding="utf-8")

cleanup_start = scheduler.find(
    "Future<void> _reconcileInventoryUnlocked("
)
repair_helper_start = scheduler.find(
    "Future<void> _repairReconciliationDesired(",
    cleanup_start,
)
if cleanup_start < 0 or repair_helper_start < 0:
    print("ERROR: reconciliation method boundaries are missing.")
    sys.exit(1)

cleanup_body = scheduler[cleanup_start:repair_helper_start]
catch_index = cleanup_body.find("} catch (error, stackTrace)")
confirmed_registry_index = cleanup_body.rfind(
    "final confirmedRegistry ="
)
repair_call_index = cleanup_body.rfind(
    "await _repairReconciliationDesired("
)

if not (
    -1
    < catch_index
    < confirmed_registry_index
    < repair_call_index
):
    print(
        "ERROR: desired repair is still inside the cleanup rollback "
        "transaction boundary."
    )
    sys.exit(1)

if "task-reconcile-temporary" in schedule_test:
    print(
        "ERROR: obsolete non-empty temporary reconcile contract remains."
    )
    sys.exit(1)

if "reconcile accepts empty input" not in schedule_test:
    print("ERROR: empty reconcile smoke contract is missing.")
    sys.exit(1)

required_inventory = [
    "last value wins before due filtering",
    "_entryForRequest(future, futureFingerprint)",
    "repairs orphan complete pair when desired future lacks registry evidence",
    "quarantines corruption, discovers once, and repairs desired state",
    "repair failure does not roll back finalized cleanup",
    "LinuxSystemdNotificationSchedulerFailure.partialReconciliation",
    "failFactoryId",
    "_RepairFactory(failId: failFactoryId)",
    "final class _InstallTransaction",
    "_disabledBaseNames",
    "_enabledBaseNames",
    "installCalls",
]
missing_inventory = [
    token for token in required_inventory
    if token not in inventory_test
]
if missing_inventory:
    print(
        "ERROR: Task 10.5.10 v2 inventory regression coverage "
        f"is incomplete: {missing_inventory}"
    )
    sys.exit(1)

for obsolete in (
    "Install is reserved for Gate 10.5.10",
    "Repair is reserved for Gate 10.5.10",
    "preserves orphan complete pair when it belongs to desired future state",
    "removes all exact pairs",
):
    if obsolete in inventory_test:
        print(f"ERROR: obsolete cleanup-only fixture remains: {obsolete}")
        sys.exit(1)

required_repair = [
    "matching fingerprint and healthy status is preserved",
    "matching fingerprint with unhealthy status is repaired",
    "changed fingerprint replaces the existing schedule",
    "missing registry and unit pair creates the desired schedule",
    "enable failure preserves prior confirmed success and stops batch",
    "finalize failure rolls back the failing and later installs",
    "registry failure reports confirmed completed IDs and repairs inventory",
]
missing_repair = [
    token for token in required_repair
    if token not in repair_test
]
if missing_repair:
    print(
        "ERROR: dedicated repair test coverage is incomplete: "
        f"{missing_repair}"
    )
    sys.exit(1)

for text_name, text in (
    ("scheduler", scheduler),
    ("schedule test", schedule_test),
    ("inventory test", inventory_test),
    ("repair test", repair_test),
):
    for forbidden in (
        "Process.start",
        "Process.run",
        "Directory.systemTemp",
        "systemctl --user",
        "UnimplementedError",
        "TODO",
        "FIXME",
    ):
        if forbidden in text:
            print(
                f"ERROR: {text_name} contains external or placeholder "
                f"behavior: {forbidden}"
            )
            sys.exit(1)

print(
    "OK: Task 10.5.10 hotfix v2 places desired repair outside the finalized "
    "cleanup rollback boundary, removes the obsolete temporary reconcile "
    "contract, upgrades inventory fixtures to retained installation and typed "
    "timer states, validates request-accurate fingerprints, repairs desired "
    "orphan and corrupt-registry state, and proves repair failure cannot roll "
    "back confirmed cleanup."
)
