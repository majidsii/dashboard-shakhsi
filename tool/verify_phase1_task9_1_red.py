#!/usr/bin/env python3
from pathlib import Path
import hashlib
import sys

root = Path.cwd()
test_file = root / "test/core/notifications/notification_route_parser_test.dart"
production_files = [
    root / "lib/core/notifications/notification_route_intent.dart",
    root / "lib/core/notifications/notification_route_parser.dart",
]

errors = []
if not test_file.is_file():
    errors.append(f"missing RED test file: {test_file}")
else:
    text = test_file.read_text(encoding="utf-8")
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
    if digest != "83b9b37011c95b039000193432123657056d6ddf0a919f9bfc3034ea89d83423":
        errors.append("RED test file content does not match the Task 9.1 package")

    required_markers = [
        "NotificationTaskRouteIntent",
        "NotificationHabitRouteIntent",
        "NotificationChallengeRouteIntent",
        "NotificationGoalRouteIntent",
        "NotificationDebtRouteIntent",
        "NotificationInstallmentRouteIntent",
        "NotificationTransactionRouteIntent",
        "NotificationSectionRouteIntent",
        "/tasks/task-1?tab=notes",
        "/tasks/task-1#notes",
        "/tasks/../settings",
        "/tasks/task-1/edit",
        "unsupported payload version",
        "does not fall back when an explicit route is invalid",
    ]
    for marker in required_markers:
        if marker not in text:
            errors.append(f"RED test is missing required coverage marker: {marker}")

for production_file in production_files:
    if production_file.exists():
        errors.append(
            f"RED requires production file to be absent before the failing test: {production_file}"
        )

if errors:
    print("Task 9.1 RED verification failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("Task 9.1 RED package verified.")
print("Now run:")
print("  flutter test test/core/notifications/notification_route_parser_test.dart")
print("Expected result: compilation fails because the two production files do not exist yet.")
