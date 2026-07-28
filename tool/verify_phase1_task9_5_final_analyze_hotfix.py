#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "test/core/notifications/notification_routing_providers_test.dart"
)

if not path.exists():
    print(f"ERROR: missing {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "Future<NotificationLaunchDetails> loader() async {",
    "notificationLaunchDetailsLoaderProvider.overrideWithValue(loader)",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: final Task 9.5 analyze hotfix is incomplete: {missing}")
    sys.exit(1)

if "final loader = () async {" in text:
    print("ERROR: closure variable form is still present.")
    sys.exit(1)

print(
    "OK: Task 9.5 loader now uses a local function declaration."
)
