#!/usr/bin/env python3
from pathlib import Path
import sys

adapter_path = Path("lib/app/router/go_router_notification_adapter.dart")
binding_path = Path("lib/app/router/notification_router_binding.dart")

for path in (adapter_path, binding_path):
    if not path.exists():
        print(f"ERROR: missing required Task 9.6 file: {path}")
        sys.exit(1)

adapter = adapter_path.read_text(encoding="utf-8")
binding = binding_path.read_text(encoding="utf-8")

adapter_required = [
    "factory GoRouterNotificationAdapter(",
    "return GoRouterNotificationAdapter._(router, mapper);",
    "GoRouterNotificationAdapter._(this._router, this._mapper);",
]
missing_adapter = [token for token in adapter_required if token not in adapter]
if missing_adapter:
    print(f"ERROR: adapter initializing-formal hotfix incomplete: {missing_adapter}")
    sys.exit(1)

if ": _mapper = mapper" in adapter:
    print("ERROR: old mapper initializer assignment is still present.")
    sys.exit(1)

expected_import_order = [
    "import '../../core/notifications/notification_navigation_queue.dart';",
    "import '../../core/notifications/notification_routing_providers.dart';",
    "import '../bootstrap/notification_routing_bootstrap.dart';",
    "import 'go_router_notification_adapter.dart';",
]
positions = [binding.find(item) for item in expected_import_order]
if any(position == -1 for position in positions):
    print("ERROR: one or more binding imports are missing.")
    sys.exit(1)

if positions != sorted(positions):
    print("ERROR: binding imports are not in analyzer ordering.")
    sys.exit(1)

print(
    "OK: Task 9.6 adapter uses initializing formals and binding imports "
    "are correctly ordered."
)
