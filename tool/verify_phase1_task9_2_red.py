#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
test_file = root / "test/core/notifications/notification_navigation_queue_test.dart"
production_file = root / "lib/core/notifications/notification_navigation_queue.dart"

errors: list[str] = []

if not test_file.is_file():
    errors.append(f"missing RED test: {test_file.relative_to(root)}")
else:
    text = test_file.read_text(encoding="utf-8")
    required = [
        "NotificationNavigationQueue",
        "keeps an intent pending until the router is ready",
        "drains pending intents in FIFO order",
        "does not replay delivered intents when readiness is repeated",
        "delivers a reentrant enqueue once",
        "does not replay an intent whose navigation attempt throws",
        "implements NotificationRouterAdapter",
    ]
    for marker in required:
        if marker not in text:
            errors.append(f"RED test is missing marker: {marker!r}")

if production_file.exists():
    errors.append(
        "RED requires lib/core/notifications/notification_navigation_queue.dart "
        "to be absent before the focused test is run"
    )

if errors:
    print("RED verification failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("OK: Task 9.2 RED test is present and production code is still absent.")
print("Next: run the focused Flutter test and confirm it fails because the queue file is missing.")
