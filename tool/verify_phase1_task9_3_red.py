#!/usr/bin/env python3
from pathlib import Path

TEST = Path("test/core/notifications/notification_response_source_test.dart")
PRODUCTION = Path("lib/core/notifications/notification_response_source.dart")

required = [
    "NotificationResponseSource",
    "publishRuntimePayload",
    "NotificationColdStartGateway",
    "takeInitialPayload",
    "serializes concurrent reads",
    "allows a retry when reading launch details throws",
]

if not TEST.is_file():
    raise SystemExit(f"missing RED test: {TEST}")

text = TEST.read_text(encoding="utf-8")
missing = [token for token in required if token not in text]
if missing:
    raise SystemExit(f"RED test is missing required coverage: {missing}")

if PRODUCTION.exists():
    raise SystemExit(
        f"RED expects production file to be absent, but it exists: {PRODUCTION}"
    )

print("OK: Task 9.3 RED test is present and production implementation is absent.")
