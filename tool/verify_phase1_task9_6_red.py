#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path("test/app/router/notification_go_router_adapter_test.dart")
production_paths = [
    Path("lib/app/router/notification_route_location_mapper.dart"),
    Path("lib/app/router/go_router_notification_adapter.dart"),
    Path("lib/app/router/notification_router_binding.dart"),
]

if not test_path.exists():
    print(f"ERROR: missing RED test file: {test_path}")
    sys.exit(1)

existing = [str(path) for path in production_paths if path.exists()]
if existing:
    print(
        "ERROR: RED expects Task 9.6 production files to be absent, "
        f"but found: {', '.join(existing)}"
    )
    sys.exit(1)

text = test_path.read_text(encoding="utf-8")
required = [
    "NotificationRouteLocationMapper",
    "GoRouterNotificationAdapter",
    "NotificationRouterBinding",
    "rejects traversal, query, and fragment characters defensively",
    "drains queued intents after the router first frame",
    "rebinds future navigation to a replacement router",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: RED tests are missing required contracts: {missing}")
    sys.exit(1)

print(
    "OK: RED test is installed and Task 9.6 production files are absent. "
    "Run the focused Flutter test and confirm the missing-import failure."
)
