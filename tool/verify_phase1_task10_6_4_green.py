#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "service": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_service.dart"
    ),
    "exception": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_exception.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_notification_delivery_service_test.dart"
    ),
    "result": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_result.dart"
    ),
    "repository": Path(
        "lib/core/notifications/"
        "notification_schedule_repository.dart"
    ),
}

for label, path in paths.items():
    if not path.is_file():
        print(f"ERROR: missing Task 10.6.4 {label}: {path}")
        sys.exit(1)

service = paths["service"].read_text(encoding="utf-8")
exception = paths["exception"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")
result = paths["result"].read_text(encoding="utf-8")
repository = paths["repository"].read_text(encoding="utf-8")

required_exception = (
    "enum LinuxNotificationDeliveryOperation",
    "initialize",
    "lookup",
    "display",
    "close",
    "enum LinuxNotificationDeliveryFailure",
    "initializationFailed",
    "lookupFailed",
    "displayFailed",
    "closeFailed",
    "final class LinuxNotificationDeliveryException implements Exception",
    "const LinuxNotificationDeliveryException._",
    "factory LinuxNotificationDeliveryException.forOperation",
    "final Object cause;",
    "final StackTrace causeStackTrace;",
    "operation=${operation.name}",
    "failure=${failure.name}",
    "causeType=${cause.runtimeType}",
)
missing_exception = [
    token for token in required_exception if token not in exception
]
if missing_exception:
    print(
        "ERROR: typed delivery exception model incomplete: "
        f"{missing_exception}"
    )
    sys.exit(1)


if (
    "final openedResources = await _run(" not in service
    or "resources = openedResources;" not in service
):
    print(
        "ERROR: initialized resources must first be captured as a non-null "
        "local before being retained for finally cleanup."
    )
    sys.exit(1)

try_start = service.find("    try {")
finally_start = service.find("    } finally {", try_start)
if try_start < 0 or finally_start < 0:
    print("ERROR: delivery try/finally boundary is missing.")
    sys.exit(1)

delivery_path = service[try_start:finally_start]
cleanup_path = service[finally_start:]

if "final openedResources = resources;" in delivery_path:
    print(
        "ERROR: nullable resources are copied into the lookup/display path."
    )
    sys.exit(1)

if "final openedResources = resources;" not in cleanup_path:
    print(
        "ERROR: finally cleanup no longer snapshots nullable resources "
        "before the null check."
    )
    sys.exit(1)

required_service = (
    "abstract interface class LinuxNotificationDeliveryResources",
    "NotificationScheduleRepository get repository;",
    "NativeNotificationGateway get gateway;",
    "Future<void> close();",
    "abstract interface class LinuxNotificationDeliveryResourcesFactory",
    "Future<LinuxNotificationDeliveryResources> open();",
    "final class LinuxNotificationDeliveryService",
    "Future<LinuxNotificationDeliveryResult> deliver(String scheduleId)",
    "operation: LinuxNotificationDeliveryOperation.initialize",
    "action: _resourcesFactory.open",
    "operation: LinuxNotificationDeliveryOperation.lookup",
    "repository.getById(scheduleId)",
    "LinuxNotificationDeliveryResult.missingRequest()",
    "NotificationDeliveryPolicy.contentFor(request)",
    "NotificationPayloadCodec.encode(request)",
    "StableNotificationId.fromScheduleId(request.scheduleId)",
    "operation: LinuxNotificationDeliveryOperation.display",
    "gateway.showNow(",
    "LinuxNotificationDeliveryResult.delivered()",
    "await openedResources.close();",
    "LinuxNotificationDeliveryOperation.close",
    "LinuxNotificationDeliveryCloseFailure(",
    "primary.withCloseFailures(closeFailures)",
    "LinuxNotificationDeliveryResult.initializationFailed(",
    "LinuxNotificationDeliveryResult.lookupFailed(",
    "LinuxNotificationDeliveryResult.displayFailed(",
    "Error.throwWithStackTrace(",
)
missing_service = [token for token in required_service if token not in service]
if missing_service:
    print(
        "ERROR: persisted hidden delivery orchestration incomplete: "
        f"{missing_service}"
    )
    sys.exit(1)

# Delivery must be read-only with respect to desired state.
for forbidden in (
    ".upsert(",
    ".delete(",
    ".deleteByOwner(",
    ".replaceAll(",
    ".getAll(",
    ".watchAll(",
):
    if forbidden in service:
        print(
            "ERROR: hidden delivery mutates or scans desired state: "
            f"{forbidden}"
        )
        sys.exit(1)

# Content and payload must be sourced from the canonical policy/codecs.
for forbidden in (
    "request.title,",
    "request.body,",
    "jsonEncode(",
    "hashCode",
):
    if forbidden in service:
        print(
            "ERROR: hidden delivery bypasses canonical content/identity "
            f"behavior: {forbidden}"
        )
        sys.exit(1)

# Close failure must append the original error/stack, not replace primary.
close_index = service.find("await openedResources.close();")
append_index = service.find(
    "LinuxNotificationDeliveryCloseFailure(",
    close_index,
)
return_index = service.find(
    "primary.withCloseFailures(closeFailures)",
    append_index,
)
if close_index < 0 or append_index < 0 or return_index < 0:
    print("ERROR: close-failure attachment flow is incomplete.")
    sys.exit(1)

required_tests = (
    "loads the exact request, displays it, and closes resources",
    "missing request succeeds without displaying",
    "private mode uses policy-safe content",
    "full mode preserves title and body",
    "uses stable ID and canonical navigation payload",
    "initialization failure returns typed non-zero result",
    "lookup failure returns typed result and still closes",
    "display failure returns typed result and still closes",
    "close failure is appended after successful delivery",
    "close failure does not replace primary display failure",
    "delivery exception string is privacy-safe",
    "delivery never mutates desired-state repository methods",
    "harness.repository.lookups",
    "harness.gateway.displays",
    "harness.resources.closeCalls",
    "harness.repository.mutations",
)
missing_tests = [token for token in required_tests if token not in test]
if missing_tests:
    print(f"ERROR: Task 10.6.4 GREEN coverage incomplete: {missing_tests}")
    sys.exit(1)

if "Future<NotificationRequest?> getById(String scheduleId)" not in repository:
    print("ERROR: repository exact lookup contract is missing.")
    sys.exit(1)

for token in (
    "LinuxNotificationDeliveryResult.initializationFailed",
    "LinuxNotificationDeliveryResult.lookupFailed",
    "LinuxNotificationDeliveryResult.displayFailed",
    "LinuxNotificationDeliveryCloseFailure",
    "withCloseFailures",
):
    if token not in result:
        print(f"ERROR: required delivery result capability is missing: {token}")
        sys.exit(1)

combined = "\n".join((service, exception, test))
for forbidden in (
    "dart:io",
    "package:flutter/",
    "Process.start",
    "Process.run",
    "Directory.systemTemp",
    "Future.delayed(",
    "systemctl",
    "TODO",
    "FIXME",
    "UnimplementedError",
):
    if forbidden in combined:
        print(f"ERROR: Task 10.6.4 contains forbidden behavior: {forbidden}")
        sys.exit(1)

# Safe diagnostic strings must expose only enum names and cause types.
exception_to_string = exception[exception.rfind("String toString()"):]
for forbidden in ("$cause", "cause.toString", "scheduleId", "title", "body"):
    if forbidden in exception_to_string:
        print(
            "ERROR: delivery exception string may expose private content: "
            f"{forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.6.4 GREEN adds a read-only persisted hidden-delivery service "
    "with exact getById lookup, benign missing-request success, canonical "
    "privacy content, stable notification IDs and payload encoding, typed "
    "initialize/lookup/display results preserving original causes and stacks, "
    "unconditional cleanup after successful open, ordered close-failure "
    "attachment without replacing the primary result, privacy-safe diagnostics, "
    "and no desired-state mutations or platform side effects."
)
