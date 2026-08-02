#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "invocation": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_invocation.dart"
    ),
    "result": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_result.dart"
    ),
    "invocation_test": Path(
        "test/core/notifications/"
        "linux_notification_delivery_invocation_test.dart"
    ),
    "result_test": Path(
        "test/core/notifications/"
        "linux_notification_delivery_result_test.dart"
    ),
}

for label, path in paths.items():
    if not path.is_file():
        print(f"ERROR: missing Task 10.6.2 {label}: {path}")
        sys.exit(1)

invocation = paths["invocation"].read_text(encoding="utf-8")
result = paths["result"].read_text(encoding="utf-8")
tests = (
    paths["invocation_test"].read_text(encoding="utf-8")
    + "\n"
    + paths["result_test"].read_text(encoding="utf-8")
)

required_invocation = (
    "const String linuxNotificationDeliveryFlag",
    "'--deliver-notification'",
    "enum LinuxNotificationDeliveryArgumentFailure",
    "invalidShape",
    "invalidScheduleId",
    "final class LinuxNotificationDeliveryArgumentException",
    "sealed class LinuxNotificationDeliveryInvocation",
    "factory LinuxNotificationDeliveryInvocation.parse(",
    "if (!arguments.contains(linuxNotificationDeliveryFlag))",
    "arguments.length != 2",
    "arguments.first != linuxNotificationDeliveryFlag",
    "arguments.last == linuxNotificationDeliveryFlag",
    "value.isEmpty || value.trim() != value",
    "rune <= 0x1f",
    "rune >= 0x7f && rune <= 0x9f",
    "final class LinuxNormalApplicationInvocation",
    "final class LinuxHiddenNotificationDeliveryInvocation",
    "final String scheduleId;",
)
missing_invocation = [
    token for token in required_invocation if token not in invocation
]
if missing_invocation:
    print(
        "ERROR: hidden invocation parser/model incomplete: "
        f"{missing_invocation}"
    )
    sys.exit(1)

required_result = (
    "enum LinuxNotificationDeliveryExitKind",
    "normalApplication",
    "delivered",
    "missingRequest",
    "invalidArguments",
    "initializationFailed",
    "lookupFailed",
    "displayFailed",
    "final class LinuxNotificationDeliveryCloseFailure",
    "final class LinuxNotificationDeliveryResult",
    "List<LinuxNotificationDeliveryCloseFailure>.unmodifiable",
    "LinuxNotificationDeliveryResult.normalApplication",
    "LinuxNotificationDeliveryResult.delivered",
    "LinuxNotificationDeliveryResult.missingRequest",
    "LinuxNotificationDeliveryResult.invalidArguments",
    "LinuxNotificationDeliveryResult.initializationFailed",
    "LinuxNotificationDeliveryResult.lookupFailed",
    "LinuxNotificationDeliveryResult.displayFailed",
    "LinuxNotificationDeliveryResult withCloseFailures(",
    "...closeFailures",
    "...additionalFailures",
    "causeType=${cause?.runtimeType ?? 'none'}",
    "closeFailures=${closeFailures.length}",
)
missing_result = [token for token in required_result if token not in result]
if missing_result:
    print(
        "ERROR: hidden delivery exit model incomplete: "
        f"{missing_result}"
    )
    sys.exit(1)

# Zero is reserved for normal startup, successful delivery, and benign stale
# timers. Every typed failure factory must remain non-zero.
for factory in (
    "invalidArguments",
    "initializationFailed",
    "lookupFailed",
    "displayFailed",
):
    start = result.find(
        f"factory LinuxNotificationDeliveryResult.{factory}("
    )
    if start < 0:
        print(f"ERROR: missing result factory: {factory}")
        sys.exit(1)
    end = result.find("\n  factory ", start + 1)
    if end < 0:
        end = result.find("\n  final ", start + 1)
    body = result[start:end]
    if "exitCode: 0" in body:
        print(f"ERROR: failure factory uses exit code zero: {factory}")
        sys.exit(1)

required_tests = (
    "uses normal startup when the hidden flag is absent",
    "parses the exact hidden delivery command",
    "preserves valid Unicode and punctuation in one argument",
    "LinuxNotificationDeliveryArgumentFailure.invalidShape",
    "LinuxNotificationDeliveryArgumentFailure.invalidScheduleId",
    r"'task\u000042'",
    r"'task\u001f42'",
    r"'task\u007f42'",
    r"'task\u008542'",
    r"'task\u009f42'",
    "argument exception string does not expose raw arguments",
    "uses zero only for normal, delivered, and missing outcomes",
    "copies and exposes close failures as an immutable list",
    "appends close failures without replacing the primary result",
    "safe string includes types and counts but not private messages",
    "throwsUnsupportedError",
)
missing_tests = [token for token in required_tests if token not in tests]
if missing_tests:
    print(f"ERROR: Task 10.6.2 GREEN test coverage incomplete: {missing_tests}")
    sys.exit(1)

for source_name, source in (
    ("invocation", invocation),
    ("result", result),
    ("tests", tests),
):
    for forbidden in (
        "dart:io",
        "package:flutter/",
        "package:flutter_riverpod/",
        "Process.",
        "Directory.",
        "Platform.",
        "Future.delayed(",
        "TODO",
        "FIXME",
        "UnimplementedError",
    ):
        if forbidden in source:
            print(
                f"ERROR: Task 10.6.2 {source_name} contains forbidden "
                f"dependency/placeholder: {forbidden}"
            )
            sys.exit(1)

# Raw argument values and cause messages must not be included in safe strings.
argument_to_string_start = invocation.find("String toString()")
argument_to_string_end = invocation.find(
    "\n}\n\nsealed class LinuxNotificationDeliveryInvocation",
    argument_to_string_start,
)
if argument_to_string_start < 0 or argument_to_string_end < 0:
    print("ERROR: argument exception toString boundary was not found.")
    sys.exit(1)
argument_to_string = invocation[
    argument_to_string_start:argument_to_string_end
]
if "scheduleId" in argument_to_string or "arguments" in argument_to_string:
    print("ERROR: argument exception string may expose raw command data.")
    sys.exit(1)

result_to_string_start = result.rfind("String toString()")
result_to_string = result[result_to_string_start:]
for forbidden in ("cause.toString", "$cause", "error.toString", "$error"):
    if forbidden in result_to_string:
        print(f"ERROR: result string may expose private cause data: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.6.2 GREEN adds a pure exact hidden-command parser that "
    "keeps ordinary arguments in normal startup, requires one flag plus one "
    "safe schedule ID, rejects invalid shape, trim-changing values, and C0/C1 "
    "controls, preserves valid Unicode and punctuation, and provides typed "
    "privacy-safe immutable exit and close-failure models with zero reserved "
    "for normal, delivered, and benign missing-request outcomes."
)
