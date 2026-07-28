#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path(
    "test/app/router/notification_click_routing_end_to_end_test.dart"
)
harness_path = Path(
    "test/support/notification_routing_test_harness.dart"
)
checkpoint_path = Path(
    "docs/superpowers/checkpoints/"
    "2026-07-28-notification-routing-checkpoint.md"
)

if not test_path.exists():
    print(f"ERROR: missing Task 9.7 RED test: {test_path}")
    sys.exit(1)

unexpected = [
    str(path)
    for path in (harness_path, checkpoint_path)
    if path.exists()
]
if unexpected:
    print(
        "ERROR: RED expects the Task 9.7 GREEN artifacts to be absent, "
        f"but found: {', '.join(unexpected)}"
    )
    sys.exit(1)

text = test_path.read_text(encoding="utf-8")
required = [
    "NotificationRoutingTestHarness",
    "routes a cold-start task payload after router readiness",
    "routes a runtime transaction payload",
    "preserves cold-start ordering before a buffered runtime tap",
    "does not replay a consumed cold-start payload on rebuild",
    "stops routing after the application host is unmounted",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 9.7 RED coverage is incomplete: {missing}")
    sys.exit(1)

print(
    "OK: Task 9.7 RED test is installed and the verification harness "
    "is intentionally absent. Run the focused Flutter test and confirm "
    "the missing-harness import failure."
)
