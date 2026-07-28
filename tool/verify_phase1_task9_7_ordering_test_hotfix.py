#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "test/app/router/notification_click_routing_end_to_end_test.dart"
)

if not path.exists():
    print(f"ERROR: missing {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "The final route proves ordering:",
    "expect(find.text('/settings'), findsOneWidget);",
    "expect(find.text('/tasks/cold-first'), findsNothing);",
    "expect(harness.queue.pendingCount, 0);",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 9.7 ordering hotfix is incomplete: {missing}")
    sys.exit(1)

ordering_test_start = text.find(
    "testWidgets('preserves cold-start ordering before a buffered runtime tap'"
)
ordering_test_end = text.find(
    "testWidgets('ignores malformed runtime payload without leaving root'",
    ordering_test_start,
)
if ordering_test_start == -1 or ordering_test_end == -1:
    print("ERROR: could not isolate the ordering test.")
    sys.exit(1)

ordering_block = text[ordering_test_start:ordering_test_end]

if "containsAllInOrder" in ordering_block:
    print(
        "ERROR: ordering test still depends on rendered-page history."
    )
    sys.exit(1)

print(
    "OK: Task 9.7 ordering test now verifies the final route and empty queue "
    "without relying on intermediate page rendering."
)
