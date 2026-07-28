#!/usr/bin/env python3
from pathlib import Path
import re
import sys

path = Path(
    "lib/core/notifications/notification_routing_startup_service.dart"
)

if not path.exists():
    print(f"ERROR: missing {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

field_pattern = re.compile(
    r"// ignore: cancel_subscriptions\s*\n"
    r"\s*StreamSubscription<String\?>\? _runtimeSubscription;"
)
if not field_pattern.search(text):
    print(
        "ERROR: cancel_subscriptions suppression must be immediately "
        "above the owned StreamSubscription field."
    )
    sys.exit(1)

if "await subscription?.cancel();" not in text:
    print("ERROR: dispose() must still cancel the retained subscription.")
    sys.exit(1)

if text.count("// ignore: cancel_subscriptions") != 1:
    print("ERROR: expected exactly one targeted cancel_subscriptions suppression.")
    sys.exit(1)

if "NotificationRoutingStartupService._(" not in text:
    print("ERROR: private initializing constructor from the first hotfix is missing.")
    sys.exit(1)

print("OK: final Task 9.4 analyze suppression is correctly targeted.")
