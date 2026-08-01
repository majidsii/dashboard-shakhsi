#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "factory": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_command_factory.dart"
    ),
    "exception": Path(
        "lib/core/notifications/"
        "linux_systemd_notification_scheduler_exception.dart"
    ),
    "fake": Path(
        "test/support/"
        "fake_linux_notification_delivery_command_factory.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_model_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.4 {label}: {path}")
        sys.exit(1)

factory = paths["factory"].read_text(encoding="utf-8")
exception = paths["exception"].read_text(encoding="utf-8")
fake = paths["fake"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_factory = [
    "abstract interface class LinuxNotificationDeliveryCommandFactory",
    "LinuxSystemdNotificationUnit create(NotificationRequest request)",
]
required_exception = [
    "enum LinuxSystemdNotificationSchedulerOperation",
    "schedule",
    "cancel",
    "cancelByOwner",
    "reconcile",
    "enum LinuxSystemdNotificationSchedulerFailure",
    "commandFactoryFailed",
    "renderFailed",
    "unitTransactionFailed",
    "daemonReloadFailed",
    "mutationFailed",
    "registryFailed",
    "rollbackFailed",
    "partialOwnerCancellation",
    "partialReconciliation",
    "final class LinuxSystemdSchedulerRollbackFailure",
    "final class LinuxSystemdNotificationSchedulerException",
    "List<LinuxSystemdSchedulerRollbackFailure>.unmodifiable",
    "List<String>.unmodifiable",
    "ownerType=${owner!.type.name}",
    "rollbackFailures=${rollbackFailures.length}",
    "completedScheduleIds=${completedScheduleIds.length}",
    "confirmedStatus=${confirmedStatus == null ? 'none' : 'present'}",
]
required_fake = [
    "implements LinuxNotificationDeliveryCommandFactory",
    "final List<NotificationRequest> requests",
    "requests.add(request)",
    "Error.throwWithStackTrace",
    "return result",
]
required_test = [
    "fake records the exact request and returns the configured unit",
    "fake preserves the configured failure and stack trace",
    "exposes the exact public scheduler operations",
    "exposes the exact typed scheduler failures",
    "retains exact metadata without depending on owner equality",
    "copies rollback and completed lists into immutable storage",
    "toString includes safe context and excludes nested error text",
]

for label, text, required in (
    ("delivery factory", factory, required_factory),
    ("scheduler exception", exception, required_exception),
    ("factory fake", fake, required_fake),
    ("Gate tests", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = f"{factory}\n{exception}\n{fake}"

for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "systemctl",
    "daemon-reload",
    "enable --now",
    "disable --now",
    "UnimplementedError",
    "TODO",
):
    if forbidden in combined:
        print(
            "ERROR: Task 10.5.4 contains orchestration, process, or "
            f"placeholder coupling: {forbidden}"
        )
        sys.exit(1)

to_string_start = exception.find("String toString()")
if to_string_start < 0:
    print("ERROR: scheduler exception safe toString is missing.")
    sys.exit(1)

to_string_body = exception[to_string_start:]
for forbidden in (
    "$cause",
    "cause=",
    ".error",
    "$error",
    "stackTrace",
    "owner!.id",
    "completedScheduleIds.join",
):
    if forbidden in to_string_body:
        print(
            "ERROR: scheduler exception diagnostics expose sensitive or "
            f"unbounded nested content: {forbidden}"
        )
        sys.exit(1)

if exception.count(
    "enum LinuxSystemdNotificationSchedulerOperation"
) != 1:
    print("ERROR: scheduler operation enum must be defined exactly once.")
    sys.exit(1)

if exception.count(
    "enum LinuxSystemdNotificationSchedulerFailure"
) != 1:
    print("ERROR: scheduler failure enum must be defined exactly once.")
    sys.exit(1)

print(
    "OK: Task 10.5.4 GREEN defines the injectable delivery-command factory, "
    "exact scheduler operation/failure taxonomies, structured rollback "
    "evidence, identity-preserving optional metadata, immutable rollback and "
    "completed-ID lists, deterministic non-sensitive diagnostics, and a "
    "configurable recording factory fake without scheduler orchestration."
)
