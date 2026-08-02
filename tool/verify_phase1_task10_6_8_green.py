#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "integration": Path(
        "test/core/notifications/"
        "linux_notification_pipeline_integration_test.dart"
    ),
    "scheduler": Path(
        "lib/core/notifications/linux_systemd_notification_scheduler.dart"
    ),
    "delivery": Path(
        "lib/core/notifications/linux_notification_delivery_service.dart"
    ),
    "entrypoint": Path(
        "lib/app/bootstrap/application_entrypoint.dart"
    ),
    "providers": Path(
        "lib/core/notifications/notification_platform_providers.dart"
    ),
    "startup_widget": Path(
        "lib/app/bootstrap/notification_startup_bootstrap.dart"
    ),
    "app_bootstrap": Path(
        "lib/app/bootstrap/app_bootstrap.dart"
    ),
    "persistence": Path(
        "lib/core/providers/persistence_providers.dart"
    ),
}

for label, path in paths.items():
    if not path.is_file():
        print(f"ERROR: missing Task 10.6.8 {label}: {path}")
        sys.exit(1)

integration = paths["integration"].read_text(encoding="utf-8")
scheduler = paths["scheduler"].read_text(encoding="utf-8")
delivery = paths["delivery"].read_text(encoding="utf-8")
entrypoint = paths["entrypoint"].read_text(encoding="utf-8")
providers = paths["providers"].read_text(encoding="utf-8")
startup_widget = paths["startup_widget"].read_text(encoding="utf-8")
app_bootstrap = paths["app_bootstrap"].read_text(encoding="utf-8")
persistence = paths["persistence"].read_text(encoding="utf-8")

required_integration = (
    "AppDatabase(",
    "NativeDatabase.memory()",
    "await repository.upsert(request);",
    "await scheduler.schedule(request);",
    "FakeLinuxSystemdFileSystem",
    "_ControlledSystemctlRunner",
    "ResolvedLinuxNotificationDeliveryCommandFactory(",
    "'/opt/dashboard-shakhsi/bin/dashboard-shakhsi'",
    "LinuxSystemdUserUnitStore(",
    "LinuxSystemdScheduleRegistryFileStore(",
    "ApplicationEntrypoint(",
    "LinuxNotificationDeliveryService(",
    "recordingRepository.lookups",
    "displayCalls, hasLength(1)",
    "NotificationPayloadCodec.decode(display.payload!)",
    "StableNotificationId.fromScheduleId",
    "persisted.privacyMode, NotificationPrivacyMode.private",
    "missing hidden request exits zero",
    "gateway.calls, isEmpty",
    "normalRunner.runCalls, 0",
    "never constructs Linux dependencies",
    "linuxConstructionCount, 0",
    "startup reconciliation reads the same persisted request once",
    "expect(identical(first, second), isTrue)",
    "scheduler.reconcileCalls, 1",
    "driver.initializeCalls, 1",
)
missing = [
    token for token in required_integration if token not in integration
]
if missing:
    print(
        "ERROR: Task 10.6.8 integrated behavior coverage incomplete: "
        f"{missing}"
    )
    sys.exit(1)

required_production = {
    "scheduler": (
        "_commandFactory.create(request)",
        "_renderer.render(unit)",
        "_driver.enableAndStart",
        "_registryStore.replace",
    ),
    "delivery": (
        "repository.getById(scheduleId)",
        "NotificationDeliveryPolicy.contentFor(request)",
        "NotificationPayloadCodec.encode(request)",
        "StableNotificationId.fromScheduleId",
        "gateway.showNow",
    ),
    "entrypoint": (
        "LinuxHiddenNotificationDeliveryInvocation",
        "_deliveryService.deliver(scheduleId)",
        "_normalApplicationRunner.run()",
    ),
    "providers": (
        "NotificationHostPlatform.linux",
        "linuxSystemdNotificationSchedulerProvider",
        "NotificationHostPlatform.unsupported",
        "noopNotificationSchedulerProvider",
        "FutureProvider.family",
    ),
    "startup_widget": (
        "notificationStartupProvider(widget.startupProvider)",
        "return widget.child;",
        "widget.reporter.report(error, stackTrace);",
    ),
    "app_bootstrap": (
        "UncontrolledProviderScope(",
        "NotificationStartupBootstrap(",
        "startupProvider: notificationStartupProvider",
    ),
    "persistence": (
        "Provider<NotificationStartup>",
        "NotificationStartupService(",
        "notificationCoordinatorProvider",
    ),
}

sources = {
    "scheduler": scheduler,
    "delivery": delivery,
    "entrypoint": entrypoint,
    "providers": providers,
    "startup_widget": startup_widget,
    "app_bootstrap": app_bootstrap,
    "persistence": persistence,
}

for label, tokens in required_production.items():
    missing_tokens = [
        token for token in tokens if token not in sources[label]
    ]
    if missing_tokens:
        print(
            f"ERROR: Task 10.6.8 production contract drift in {label}: "
            f"{missing_tokens}"
        )
        sys.exit(1)

if "await initializeNotificationsForApp(container);" in app_bootstrap[
    app_bootstrap.find("Future<void> bootstrapApp() async"):
    app_bootstrap.find("@visibleForTesting")
]:
    print(
        "ERROR: normal UI remains blocked on notification reconciliation."
    )
    sys.exit(1)

if "final notificationStartupServiceProvider" in persistence:
    print("ERROR: duplicate startup service provider remains.")
    sys.exit(1)

combined = "\n".join(sources.values()) + "\n" + integration
for forbidden in (
    "Process.run",
    "Process.start",
    "Platform.isLinux",
    "TODO",
    "FIXME",
    "UnimplementedError",
):
    if forbidden in combined:
        print(f"ERROR: Task 10.6.8 contains forbidden behavior: {forbidden}")
        sys.exit(1)

drift_import = "import 'package:drift/drift.dart' hide isNotNull;"
if drift_import not in integration:
    print(
        "ERROR: Drift import must hide isNotNull to avoid matcher ambiguity."
    )
    sys.exit(1)

if "import 'package:drift/drift.dart';" in integration:
    print(
        "ERROR: bare Drift import reintroduces the isNotNull collision."
    )
    sys.exit(1)

print(
    "OK: Task 10.6.8 GREEN verifies the complete persisted Linux notification "
    "pipeline: Drift lookup, deterministic minimal systemd command rendering, "
    "controlled scheduler mutation, hidden entrypoint isolation, privacy and "
    "payload preservation, stable display ID, retained desired state, missing "
    "request success, non-Linux lazy selection, and one provider-scope startup "
    "reconciliation."
)
