#!/usr/bin/env python3
from pathlib import Path
import re
import sys

paths = {
    "interface": Path(
        "lib/core/notifications/notification_schedule_repository.dart"
    ),
    "drift": Path(
        "lib/core/notifications/drift_notification_schedule_repository.dart"
    ),
    "memory": Path(
        "test/support/memory_notification_schedule_repository.dart"
    ),
    "drift_test": Path(
        "test/core/notifications/drift_notification_schedule_repository_test.dart"
    ),
    "memory_test": Path(
        "test/support/memory_notification_schedule_repository_test.dart"
    ),
}

for label, path in paths.items():
    if not path.is_file():
        print(f"ERROR: missing Task 10.6.1 {label}: {path}")
        sys.exit(1)

interface = paths["interface"].read_text(encoding="utf-8")
drift = paths["drift"].read_text(encoding="utf-8")
memory = paths["memory"].read_text(encoding="utf-8")
drift_test = paths["drift_test"].read_text(encoding="utf-8")
memory_test = paths["memory_test"].read_text(encoding="utf-8")

signature = "Future<NotificationRequest?> getById(String scheduleId)"
if interface.count(signature) != 1:
    print(
        "ERROR: repository interface must declare exactly one nullable "
        "getById contract."
    )
    sys.exit(1)

required_drift = (
    "@override\n  Future<NotificationRequest?> getById(String scheduleId) async",
    "_database.select(_database.notificationScheduleRows)",
    "..where((item) => item.scheduleId.equals(scheduleId))",
    ".getSingleOrNull()",
    "return row == null ? null : _requestFromRow(row);",
)
missing_drift = [token for token in required_drift if token not in drift]
if missing_drift:
    print(f"ERROR: Drift exact lookup is incomplete: {missing_drift}")
    sys.exit(1)

required_memory = (
    "@override\n  Future<NotificationRequest?> getById(String scheduleId) async",
    "return _items[scheduleId];",
)
missing_memory = [token for token in required_memory if token not in memory]
if missing_memory:
    print(f"ERROR: memory exact lookup is incomplete: {missing_memory}")
    sys.exit(1)

for implementation_name, text in (
    ("Drift", drift),
    ("memory", memory),
):
    method_start = text.find(
        "Future<NotificationRequest?> getById(String scheduleId)"
    )
    if method_start < 0:
        print(f"ERROR: {implementation_name} getById is missing.")
        sys.exit(1)
    method_end = text.find("\n  @override", method_start + 1)
    method = text[method_start:method_end if method_end >= 0 else None]

    for forbidden in (
        "getAll(",
        "watchAll(",
        "toLowerCase(",
        ".trim()",
        "startsWith(",
        "contains(",
    ):
        if forbidden in method:
            print(
                f"ERROR: {implementation_name} getById is not an exact "
                f"direct lookup: {forbidden}"
            )
            sys.exit(1)

required_tests = (
    "getById uses exact ID and maps the complete request",
    "getById uses exact case-sensitive schedule ID lookup",
    "getById('task-exact')",
    "getById('TASK-EXACT')",
    "getById('task-exact ')",
    "getById('missing')",
    "actual.owner",
    "actual.title",
    "actual.body",
    "actual.scheduledAtUtc",
    "actual.payload",
    "actual.privacyMode",
    "same(request)",
)
tests = f"{drift_test}\n{memory_test}"
missing_tests = [token for token in required_tests if token not in tests]
if missing_tests:
    print(f"ERROR: GREEN lookup coverage is incomplete: {missing_tests}")
    sys.exit(1)

if drift.count("_requestFromRow(row)") < 1:
    print("ERROR: Drift lookup does not reuse the canonical row mapper.")
    sys.exit(1)

for forbidden in (
    "Process.start",
    "Process.run",
    "Directory.systemTemp",
    "Future.delayed(",
    "TODO",
    "FIXME",
    "UnimplementedError",
):
    if forbidden in f"{interface}\n{drift}\n{memory}\n{tests}":
        print(f"ERROR: Task 10.6.1 contains forbidden behavior: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.6.1 GREEN adds one nullable getById repository contract, "
    "uses exact Drift scheduleId equality with getSingleOrNull and the "
    "canonical row mapper, uses direct case-sensitive map lookup in memory, "
    "returns null for missing and near-match IDs, and round-trips all persisted "
    "NotificationRequest fields."
)
