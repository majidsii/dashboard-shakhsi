#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "mapper": Path("lib/app/router/notification_route_location_mapper.dart"),
    "adapter": Path("lib/app/router/go_router_notification_adapter.dart"),
    "binding": Path("lib/app/router/notification_router_binding.dart"),
    "test": Path("test/app/router/notification_go_router_adapter_test.dart"),
}

for name, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 9.6 {name} file: {path}")
        sys.exit(1)

mapper = paths["mapper"].read_text(encoding="utf-8")
adapter = paths["adapter"].read_text(encoding="utf-8")
binding = paths["binding"].read_text(encoding="utf-8")
tests = paths["test"].read_text(encoding="utf-8")

mapper_required = [
    "String? locationFor(NotificationRouteIntent intent)",
    "r'^[A-Za-z0-9_-]{1,128}$'",
    "NotificationSection.tasks => '/tasks'",
    "NotificationSection.finance => '/finance'",
    "NotificationSection.settings => '/settings'",
]
adapter_required = [
    "implements NotificationRouterAdapter",
    "final location = _mapper.locationFor(intent);",
    "if (location == null)",
    "_router.go(location);",
]
binding_required = [
    "extends ConsumerStatefulWidget",
    "WidgetsBinding.instance.addPostFrameCallback",
    "markRouterReady(GoRouterNotificationAdapter(router))",
    "markRouterUnavailable()",
    "NotificationRoutingBootstrap(child: widget.child)",
]

for label, text, required in (
    ("mapper", mapper, mapper_required),
    ("adapter", adapter, adapter_required),
    ("binding", binding, binding_required),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: Task 9.6 {label} is incomplete: {missing}")
        sys.exit(1)

if tests.count("test(") + tests.count("testWidgets(") < 20:
    print("ERROR: expected at least 20 focused Task 9.6 tests.")
    sys.exit(1)

print(
    "OK: Task 9.6 safe location mapper, GoRouter adapter, "
    "and lifecycle binding are present."
)
