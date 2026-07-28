#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path(
    "test/core/notifications/notification_routing_providers_test.dart"
)
production_paths = [
    Path("lib/core/notifications/notification_routing_providers.dart"),
    Path("lib/app/bootstrap/notification_routing_bootstrap.dart"),
]

if not test_path.exists():
    print(f"ERROR: missing RED test file: {test_path}")
    sys.exit(1)

existing = [str(path) for path in production_paths if path.exists()]
if existing:
    print(
        "ERROR: RED expects Task 9.5 production files to be absent, "
        f"but found: {', '.join(existing)}"
    )
    sys.exit(1)

text = test_path.read_text(encoding="utf-8")
required = [
    "notificationResponseSourceProvider",
    "notificationLaunchDetailsLoaderProvider",
    "notificationNavigationQueueProvider",
    "notificationRoutingStartupServiceProvider",
    "notificationRoutingStartupProvider",
    "NotificationRoutingBootstrap",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: RED tests are missing required contracts: {missing}")
    sys.exit(1)

print(
    "OK: RED test is installed and Task 9.5 production files are absent. "
    "Run the focused Flutter test and confirm the missing-import failure."
)
