#!/usr/bin/env python3
from pathlib import Path
import hashlib
import sys

root = Path.cwd()
files = {
    "test": root / "test/core/notifications/notification_route_parser_test.dart",
    "intent": root / "lib/core/notifications/notification_route_intent.dart",
    "parser": root / "lib/core/notifications/notification_route_parser.dart",
}

errors = []
for label, path in files.items():
    if not path.is_file():
        errors.append(f"missing {label} file: {path}")

if files["test"].is_file():
    digest = hashlib.sha256(files["test"].read_bytes()).hexdigest()
    if digest != "83b9b37011c95b039000193432123657056d6ddf0a919f9bfc3034ea89d83423":
        errors.append("focused test file changed between RED and GREEN")

if files["intent"].is_file():
    intent = files["intent"].read_text(encoding="utf-8")
    required_intents = [
        "sealed class NotificationRouteIntent",
        "NotificationTaskRouteIntent",
        "NotificationHabitRouteIntent",
        "NotificationChallengeRouteIntent",
        "NotificationGoalRouteIntent",
        "NotificationDebtRouteIntent",
        "NotificationInstallmentRouteIntent",
        "NotificationTransactionRouteIntent",
        "NotificationSectionRouteIntent",
        "enum NotificationSection",
    ]
    for marker in required_intents:
        if marker not in intent:
            errors.append(f"intent file missing marker: {marker}")

if files["parser"].is_file():
    parser = files["parser"].read_text(encoding="utf-8")
    required_parser_markers = [
        "NotificationRouteIntent? parse(String? rawPayload)",
        "jsonDecode(rawPayload)",
        "supportedPayloadVersion = 1",
        r"^/tasks/([A-Za-z0-9_-]{1,128})$",
        r"^/habits/([A-Za-z0-9_-]{1,128})$",
        r"^/challenges/([A-Za-z0-9_-]{1,128})$",
        r"^/goals/([A-Za-z0-9_-]{1,128})$",
        r"^/finance/debts/([A-Za-z0-9_-]{1,128})$",
        r"^/finance/installments/([A-Za-z0-9_-]{1,128})$",
        r"^/finance/transactions/([A-Za-z0-9_-]{1,128})$",
        "An explicit but invalid route must not silently fall back to owner",
    ]
    for marker in required_parser_markers:
        if marker not in parser:
            errors.append(f"parser file missing marker: {marker}")

    forbidden_markers = [
        "package:go_router",
        "package:flutter_local_notifications",
        "Uri.parse(",
        "router.go(",
        "router.push(",
    ]
    for marker in forbidden_markers:
        if marker in parser:
            errors.append(f"parser has forbidden coupling or raw navigation: {marker}")

if errors:
    print("Task 9.1 GREEN verification failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("Task 9.1 GREEN package verified.")
print("Now run:")
print("  dart format lib test")
print("  flutter test test/core/notifications/notification_route_parser_test.dart")
