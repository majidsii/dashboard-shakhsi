#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "bootstrap": Path(
        "lib/app/bootstrap/notification_startup_bootstrap.dart"
    ),
    "app_bootstrap": Path(
        "lib/app/bootstrap/app_bootstrap.dart"
    ),
    "platform": Path(
        "lib/core/notifications/notification_platform_providers.dart"
    ),
    "main": Path("lib/main.dart"),
    "test": Path(
        "test/app/bootstrap/notification_startup_bootstrap_test.dart"
    ),
    "startup_service": Path(
        "lib/core/notifications/notification_startup_service.dart"
    ),
    "startup_service_test": Path(
        "test/core/notifications/notification_startup_service_test.dart"
    ),
    "application_entrypoint": Path(
        "lib/app/bootstrap/application_entrypoint.dart"
    ),
    "hidden_bootstrap": Path(
        "lib/app/bootstrap/linux_notification_delivery_bootstrap.dart"
    ),
    "persistence": Path(
        "lib/core/providers/persistence_providers.dart"
    ),
}

for label, path in paths.items():
    if not path.is_file():
        print(f"ERROR: missing Task 10.6.7 {label}: {path}")
        sys.exit(1)

bootstrap = paths["bootstrap"].read_text(encoding="utf-8")
app_bootstrap = paths["app_bootstrap"].read_text(encoding="utf-8")
platform = paths["platform"].read_text(encoding="utf-8")
main = paths["main"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")
startup_service = paths["startup_service"].read_text(encoding="utf-8")
startup_service_test = paths["startup_service_test"].read_text(
    encoding="utf-8"
)
persistence = paths["persistence"].read_text(encoding="utf-8")

required_platform = (
    "final notificationStartupProvider",
    "FutureProvider.family",
    "ProviderListenable<NotificationStartup>",
    "await ref.watch(startupProvider).initialize();",
    "notification_startup_service.dart",
)
missing_platform = [
    token for token in required_platform if token not in platform
]
if missing_platform:
    print(
        "ERROR: startup future-provider composition incomplete: "
        f"{missing_platform}"
    )
    sys.exit(1)

if platform.count("final notificationStartupProvider") != 1:
    print(
        "ERROR: platform startup future provider must be declared once."
    )
    sys.exit(1)

required_bootstrap = (
    "abstract interface class NotificationStartupFailureReporter",
    "final class FlutterNotificationStartupFailureReporter",
    "FlutterError.reportError(",
    "final class NotificationStartupBootstrap",
    "extends ConsumerStatefulWidget",
    "final ProviderListenable<NotificationStartup> startupProvider;",
    "final NotificationStartupFailureReporter reporter;",
    "final Widget child;",
    "ProviderSubscription<AsyncValue<void>>? _subscription;",
    "ref.listenManual<AsyncValue<void>>(",
    "notificationStartupProvider(widget.startupProvider)",
    "case AsyncError(:final error, :final stackTrace)",
    "widget.reporter.report(error, stackTrace);",
    "fireImmediately: true",
    "if (oldWidget.startupProvider != widget.startupProvider)",
    "_subscription?.close();",
    "return widget.child;",
)
missing_bootstrap = [
    token for token in required_bootstrap if token not in bootstrap
]
if missing_bootstrap:
    print(
        "ERROR: non-blocking startup widget incomplete: "
        f"{missing_bootstrap}"
    )
    sys.exit(1)

for forbidden in (
    "FutureBuilder",
    "AsyncValueWidget",
    "CircularProgressIndicator",
    "return const SizedBox",
    "throw error",
    "rethrow",
):
    if forbidden in bootstrap:
        print(
            "ERROR: startup widget can block or replace the dashboard: "
            f"{forbidden}"
        )
        sys.exit(1)

required_app_bootstrap = (
    "Future<void> bootstrapApp() async",
    "final container = ProviderContainer();",
    "runApp(",
    "UncontrolledProviderScope(",
    "container: container",
    "child: NotificationStartupBootstrap(",
    "startupProvider: notificationStartupProvider",
    "child: const DashboardShakhsiApp()",
    "notification_startup_bootstrap.dart",
)
missing_app_bootstrap = [
    token
    for token in required_app_bootstrap
    if token not in app_bootstrap
]
if missing_app_bootstrap:
    print(
        "ERROR: normal root application wiring incomplete: "
        f"{missing_app_bootstrap}"
    )
    sys.exit(1)

bootstrap_function_start = app_bootstrap.find(
    "Future<void> bootstrapApp() async"
)
bootstrap_function_end = app_bootstrap.find(
    "@visibleForTesting",
    bootstrap_function_start,
)
if bootstrap_function_end < 0:
    bootstrap_function_end = len(app_bootstrap)

production_bootstrap = app_bootstrap[
    bootstrap_function_start:bootstrap_function_end
]

if "await initializeNotificationsForApp(container);" in production_bootstrap:
    print(
        "ERROR: notification startup still blocks before runApp."
    )
    sys.exit(1)

run_app_index = production_bootstrap.find("runApp(")
scope_index = production_bootstrap.find(
    "UncontrolledProviderScope(",
    run_app_index,
)
startup_widget_index = production_bootstrap.find(
    "NotificationStartupBootstrap(",
    scope_index,
)
dashboard_index = production_bootstrap.find(
    "const DashboardShakhsiApp()",
    startup_widget_index,
)

if not (
    run_app_index >= 0
    and scope_index > run_app_index
    and startup_widget_index > scope_index
    and dashboard_index > startup_widget_index
):
    print(
        "ERROR: startup widget is not nested under the normal "
        "UncontrolledProviderScope and above the dashboard."
    )
    sys.exit(1)

required_main = (
    "Future<void> _runNormalApplication() async",
    "await bootstrapApp();",
)
missing_main = [token for token in required_main if token not in main]
if missing_main:
    print(
        "ERROR: normal entrypoint no longer delegates to bootstrapApp: "
        f"{missing_main}"
    )
    sys.exit(1)

if "NotificationStartupBootstrap(" in main:
    print(
        "ERROR: startup widget must live in app_bootstrap.dart, not before "
        "the hidden-mode entrypoint in main.dart."
    )
    sys.exit(1)

for label in ("application_entrypoint", "hidden_bootstrap"):
    hidden_source = paths[label].read_text(encoding="utf-8")
    for forbidden in (
        "NotificationStartupBootstrap",
        "notificationStartupProvider",
        "notificationStartupServiceProvider",
        "reconcileFromPersistence",
    ):
        if forbidden in hidden_source:
            print(
                "ERROR: hidden delivery path resolves normal startup work: "
                f"{label}:{forbidden}"
            )
            sys.exit(1)

required_persistence = (
    "final notificationStartupProvider",
    "Provider<NotificationStartup>",
    "NotificationStartupService(",
    "localNotificationsInitializerProvider",
    "notificationCoordinatorProvider",
)
missing_persistence = [
    token for token in required_persistence if token not in persistence
]
if missing_persistence:
    print(
        "ERROR: original production startup provider is incomplete: "
        f"{missing_persistence}"
    )
    sys.exit(1)

if "final notificationStartupServiceProvider" in persistence:
    print(
        "ERROR: duplicate notificationStartupServiceProvider remains in "
        "the persistence graph."
    )
    sys.exit(1)

required_tests = (
    "repeated reads share one startup future in one provider scope",
    "a new provider scope can retry a failed startup",
    "renders the application while reconciliation is pending",
    "keeps the application rendered after startup failure",
    "rebuilds do not start duplicate reconciliation",
    "reports one failure despite repeated widget rebuilds",
    "changing startup provider subscribes to the new scope work",
    "expect(identical(first, second), isTrue)",
    "expect(find.text('dashboard-ready'), findsOneWidget)",
    "expect(find.text('dashboard-still-ready'), findsOneWidget)",
    "expect(reporter.failures, hasLength(1))",
)
missing_tests = [token for token in required_tests if token not in test]
if missing_tests:
    print(
        f"ERROR: Task 10.6.7 GREEN coverage incomplete: {missing_tests}"
    )
    sys.exit(1)

if (
    "failed reconcile can be retried without reinitializing plugin"
    not in startup_service_test
):
    print(
        "ERROR: startup service retry regression coverage is missing."
    )
    sys.exit(1)

for token in (
    "Future<void>? _initialization",
    "Future<void> initialize()",
):
    if token not in startup_service:
        print(
            "ERROR: startup service single-flight contract is missing: "
            f"{token}"
        )
        sys.exit(1)

combined = "\n".join(
    (
        bootstrap,
        app_bootstrap,
        platform,
        main,
        test,
    )
)
for forbidden in (
    "Process.start",
    "Process.run",
    "systemctl",
    "Directory.systemTemp",
    "Future.delayed(const Duration(",
    "TODO",
    "FIXME",
    "UnimplementedError",
):
    if forbidden in combined:
        print(f"ERROR: Task 10.6.7 contains forbidden behavior: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.6.7 GREEN runs persisted notification startup through a "
    "provider-scope single-flight future after runApp begins, always renders "
    "the dashboard while pending or failed, reports exact failures without "
    "replacing UI, preserves the original capability-aware startup provider "
    "and retry contract, removes duplicate startup composition, and keeps "
    "hidden delivery isolated from normal startup."
)
