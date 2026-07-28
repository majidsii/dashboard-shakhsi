#!/usr/bin/env python3
from pathlib import Path
import sys

providers_path = Path(
    "lib/core/notifications/notification_routing_providers.dart"
)
bootstrap_path = Path(
    "lib/app/bootstrap/notification_routing_bootstrap.dart"
)
test_path = Path(
    "test/core/notifications/notification_routing_providers_test.dart"
)

for path in (providers_path, bootstrap_path, test_path):
    if not path.exists():
        print(f"ERROR: missing required Task 9.5 file: {path}")
        sys.exit(1)

providers = providers_path.read_text(encoding="utf-8")
bootstrap = bootstrap_path.read_text(encoding="utf-8")
tests = test_path.read_text(encoding="utf-8")

provider_tokens = [
    "notificationResponseSourceProvider",
    "notificationLaunchDetailsLoaderProvider",
    "notificationColdStartGatewayProvider",
    "notificationRouteParserProvider",
    "notificationNavigationQueueProvider",
    "notificationRoutingStartupServiceProvider",
    "notificationRoutingStartupProvider",
    "ref.onDispose",
    "unawaited(source.close())",
    "unawaited(service.dispose())",
]
missing_providers = [token for token in provider_tokens if token not in providers]
if missing_providers:
    print(f"ERROR: provider graph is incomplete: {missing_providers}")
    sys.exit(1)

bootstrap_tokens = [
    "final class NotificationRoutingBootstrap extends ConsumerWidget",
    "ref.watch(notificationRoutingStartupProvider)",
    "return child;",
]
missing_bootstrap = [token for token in bootstrap_tokens if token not in bootstrap]
if missing_bootstrap:
    print(f"ERROR: bootstrap wrapper is incomplete: {missing_bootstrap}")
    sys.exit(1)

if tests.count("test(") + tests.count("testWidgets(") < 11:
    print("ERROR: expected at least 11 focused Task 9.5 tests.")
    sys.exit(1)

print(
    "OK: Task 9.5 Riverpod provider graph, lifecycle ownership, "
    "and non-blocking bootstrap wrapper are present."
)
