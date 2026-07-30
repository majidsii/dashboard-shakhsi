#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "registry": Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry.dart"
    ),
    "exception": Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry_exception.dart"
    ),
    "unit_names": Path(
        "lib/core/notifications/"
        "linux_systemd_notification_unit.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_model_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.4.1 {label}: {path}")
        sys.exit(1)

registry = paths["registry"].read_text(encoding="utf-8")
exception = paths["exception"].read_text(encoding="utf-8")
unit_names = paths["unit_names"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_registry = [
    "final class LinuxSystemdScheduleRegistryEntry",
    "final class LinuxSystemdScheduleRegistry",
    "static const int currentSchemaVersion = 1",
    "List<LinuxSystemdScheduleRegistryEntry>.unmodifiable",
    "duplicateScheduleId",
    "duplicateTimerName",
    "duplicateServiceName",
    "final class LinuxSystemdPartialUnitPair",
    "final class LinuxSystemdUnitDiscovery",
    "Set<LinuxSystemdUnitNames>.unmodifiable",
    "Set<LinuxSystemdPartialUnitPair>.unmodifiable",
    "entryForScheduleId",
    "r'^[0-9a-f]{64}$'",
]
required_exception = [
    "enum LinuxSystemdScheduleRegistryOperation",
    "enum LinuxSystemdScheduleRegistryFailure",
    "final class LinuxSystemdRegistryRollbackFailure",
    "final class LinuxSystemdScheduleRegistryException",
    "List<LinuxSystemdRegistryRollbackFailure>.unmodifiable",
    "rollbackFailures=",
]
required_unit_names = [
    "factory LinuxSystemdUnitNames.parseBaseName",
    "r'^dashboard-shakhsi-notification-[0-9a-f]{16}$'",
    "LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity",
]
required_test = [
    "stores one canonical immutable registry entry",
    "sorts entries by schedule id",
    "parses one exact app-owned base name",
    "stores sorted immutable complete and partial pairs",
    "diagnostics safe",
]

for label, text, required in (
    ("registry models", registry, required_registry),
    ("typed exception models", exception, required_exception),
    ("unit-name parser", unit_names, required_unit_names),
    ("Gate test", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = "\n".join((registry, exception, unit_names))

for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "systemctl",
    "title",
    "body",
    "payload",
    "uncheckedForTesting",
    "@visibleForTesting",
):
    if forbidden in combined:
        print(
            "ERROR: Task 10.4.1 contains forbidden coupling or "
            f"sensitive field: {forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.4.1 GREEN implements immutable version-one registry "
    "entries, deterministic registry ordering, exact stable-unit identity, "
    "typed validation failures, immutable complete/partial discovery models, "
    "and safe rollback diagnostics without filesystem, process, or sensitive "
    "notification content."
)
