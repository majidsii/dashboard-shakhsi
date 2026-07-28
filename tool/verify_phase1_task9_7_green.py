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

for path in (test_path, harness_path, checkpoint_path):
    if not path.exists():
        print(f"ERROR: missing Task 9.7 artifact: {path}")
        sys.exit(1)

test_text = test_path.read_text(encoding="utf-8")
harness_text = harness_path.read_text(encoding="utf-8")
checkpoint_text = checkpoint_path.read_text(encoding="utf-8")

if test_text.count("testWidgets(") < 9:
    print("ERROR: expected at least 9 Task 9.7 end-to-end tests.")
    sys.exit(1)

required_harness = [
    "final class NotificationRoutingTestHarness",
    "notificationLaunchDetailsLoaderProvider.overrideWithValue",
    "NotificationRouterBinding(",
    "MaterialApp.router(routerConfig: router)",
    "publishRuntimePayload(payload)",
]
missing_harness = [
    token for token in required_harness if token not in harness_text
]
if missing_harness:
    print(f"ERROR: Task 9.7 harness is incomplete: {missing_harness}")
    sys.exit(1)

required_checkpoint = [
    "# Notification Click Routing — Phase 1 Checkpoint",
    "Raw notification routes are never passed directly to GoRouter.",
    "## Linux limitation",
    "## Automated verification gate",
    "## Manual native smoke checklist",
    "## Deferred work outside Task 9",
]
missing_checkpoint = [
    token for token in required_checkpoint if token not in checkpoint_text
]
if missing_checkpoint:
    print(
        "ERROR: notification routing checkpoint is incomplete: "
        f"{missing_checkpoint}"
    )
    sys.exit(1)

print(
    "OK: Task 9.7 end-to-end verification harness, focused tests, "
    "and documentation checkpoint are present."
)
