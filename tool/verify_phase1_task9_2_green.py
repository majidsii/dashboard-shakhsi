#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
source = root / "lib/core/notifications/notification_navigation_queue.dart"
test_file = root / "test/core/notifications/notification_navigation_queue_test.dart"

errors: list[str] = []

if not source.is_file():
    errors.append(f"missing GREEN source: {source.relative_to(root)}")
else:
    text = source.read_text(encoding="utf-8")
    required = [
        "abstract interface class NotificationRouterAdapter",
        "final class NotificationNavigationQueue",
        "Queue<NotificationRouteIntent>",
        "void enqueue(NotificationRouteIntent intent)",
        "void markRouterReady(NotificationRouterAdapter router)",
        "void markRouterUnavailable()",
        "_pending.removeFirst()",
        "router.navigate(intent)",
        "bool _isDraining = false",
    ]
    for marker in required:
        if marker not in text:
            errors.append(f"GREEN source is missing marker: {marker!r}")

    remove_index = text.find("_pending.removeFirst()")
    navigate_index = text.find("router.navigate(intent)")
    if remove_index == -1 or navigate_index == -1 or remove_index > navigate_index:
        errors.append(
            "the queue entry must be removed before navigation to prevent replay "
            "after an adapter exception"
        )

if not test_file.is_file():
    errors.append(
        "missing focused test; apply the RED directory before the GREEN directory"
    )

if errors:
    print("GREEN verification failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("OK: Task 9.2 queue contract and exactly-once safeguards are present.")
print("Next: format and run the focused Flutter test.")
