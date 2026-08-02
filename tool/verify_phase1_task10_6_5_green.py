#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "entrypoint": Path(
        "lib/app/bootstrap/application_entrypoint.dart"
    ),
    "bootstrap": Path(
        "lib/app/bootstrap/"
        "linux_notification_delivery_bootstrap.dart"
    ),
    "main": Path("lib/main.dart"),
    "entrypoint_test": Path(
        "test/app/bootstrap/application_entrypoint_test.dart"
    ),
    "bootstrap_test": Path(
        "test/app/bootstrap/"
        "linux_notification_delivery_bootstrap_test.dart"
    ),
    "service": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_service.dart"
    ),
    "invocation": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_invocation.dart"
    ),
    "result": Path(
        "lib/core/notifications/"
        "linux_notification_delivery_result.dart"
    ),
}

for label, path in paths.items():
    if not path.is_file():
        print(f"ERROR: missing Task 10.6.5 {label}: {path}")
        sys.exit(1)

entrypoint = paths["entrypoint"].read_text(encoding="utf-8")
bootstrap = paths["bootstrap"].read_text(encoding="utf-8")
main = paths["main"].read_text(encoding="utf-8")
tests = (
    paths["entrypoint_test"].read_text(encoding="utf-8")
    + "\n"
    + paths["bootstrap_test"].read_text(encoding="utf-8")
)

required_entrypoint = (
    "abstract interface class NormalApplicationRunner",
    "final class CallbackNormalApplicationRunner",
    "abstract interface class ProcessExitCodeSink",
    "final class DartIoProcessExitCodeSink",
    "exitCode = value;",
    "final class ApplicationEntrypoint",
    "LinuxNotificationDeliveryInvocationParser",
    "Future<void> run(List<String> arguments) async",
    "invocation = _invocationParser(arguments);",
    "LinuxNotificationDeliveryResult.invalidArguments(",
    "_exitCodeSink.setExitCode(result.exitCode);",
    "case LinuxNormalApplicationInvocation():",
    "await _normalApplicationRunner.run();",
    "case LinuxHiddenNotificationDeliveryInvocation(:final scheduleId):",
    "_deliverWithoutEscaping(scheduleId)",
    "LinuxNotificationDeliveryResult.initializationFailed(",
    "ApplicationEntrypoint buildProductionApplicationEntrypoint(",
    "ProductionLinuxNotificationDeliveryBootstrap()",
    "LinuxNotificationDeliveryService(",
)
missing_entrypoint = [
    token for token in required_entrypoint if token not in entrypoint
]
if missing_entrypoint:
    print(
        "ERROR: application entrypoint contract incomplete: "
        f"{missing_entrypoint}"
    )
    sys.exit(1)

required_bootstrap = (
    "abstract interface class LinuxNotificationDeliveryBootstrap",
    "implements LinuxNotificationDeliveryResourcesFactory",
    "final class LinuxNotificationDeliveryRepositoryResource",
    "final class LinuxNotificationDeliveryGatewayResource",
    "final class CallbackLinuxNotificationDeliveryBootstrap",
    "await _ensureBindingInitialized();",
    "final repositoryResource = await _openRepository();",
    "gatewayResource = await _openGateway();",
    "await repositoryResource.close();",
    "final class ProductionLinuxNotificationDeliveryBootstrap",
    "WidgetsFlutterBinding.ensureInitialized();",
    "final database = AppDatabase();",
    "DriftNotificationScheduleRepository(database)",
    "FlutterLocalNotificationsDriver(",
    "LocalNotificationPluginConfig.defaults()",
    "NotificationHostPlatform.linux",
    "await driver.initialize();",
    "close: database.close",
    "final class _OpenedLinuxNotificationDeliveryResources",
    "Future<void>? _closeFuture;",
    "return _closeFuture ??= _close();",
    "await _gatewayClose();",
    "await _repositoryClose();",
    "Error.throwWithStackTrace(",
)
missing_bootstrap = [
    token for token in required_bootstrap if token not in bootstrap
]
if missing_bootstrap:
    print(
        "ERROR: minimum hidden bootstrap incomplete: "
        f"{missing_bootstrap}"
    )
    sys.exit(1)

required_main = (
    "Future<void> main(List<String> arguments) async",
    "buildProductionApplicationEntrypoint(",
    "normalApplicationRunner: CallbackNormalApplicationRunner(",
    "_runNormalApplication,",
    "await entrypoint.run(arguments);",
    "Future<void> _runNormalApplication() async",
)
missing_main = [token for token in required_main if token not in main]
if missing_main:
    print(
        "ERROR: lib/main.dart was not routed through the hidden-mode "
        f"entrypoint: {missing_main}"
    )
    sys.exit(1)

main_start = main.find("Future<void> main(List<String> arguments) async")
normal_start = main.find("Future<void> _runNormalApplication() async")
if main_start < 0 or normal_start < 0 or normal_start <= main_start:
    print("ERROR: main/normal startup boundaries are invalid.")
    sys.exit(1)

hidden_wrapper = main[main_start:normal_start]
for forbidden in (
    "runApp(",
    "ProviderScope(",
    "GoRouter(",
    "NotificationStartup",
    "reconcileFromPersistence",
):
    if forbidden in hidden_wrapper:
        print(
            "ERROR: UI or normal startup work occurs before hidden dispatch: "
            f"{forbidden}"
        )
        sys.exit(1)

if "application_entrypoint.dart" not in main:
    print("ERROR: main.dart does not import the application entrypoint.")
    sys.exit(1)

# The minimum hidden bootstrap must not create root UI/routing/scheduler state.
for forbidden in (
    "flutter_riverpod",
    "ProviderScope",
    "GoRouter",
    "Dashboard",
    "notification_routing",
    "NotificationStartupService",
    "NotificationCoordinator",
    "reconcileFromPersistence",
    "LinuxSystemdNotificationScheduler",
    "systemctl",
):
    if forbidden in bootstrap:
        print(
            "ERROR: hidden bootstrap creates non-minimum application state: "
            f"{forbidden}"
        )
        sys.exit(1)

if "linux_notification_delivery_result.dart" in paths["entrypoint_test"].read_text(encoding="utf-8"):
    print(
        "ERROR: unused delivery-result import remains in entrypoint test."
    )
    sys.exit(1)

required_tests = (
    "normal arguments run the existing application exactly once",
    "valid hidden command never starts the normal application",
    "invalid hidden command never starts UI and sets non-zero exit",
    "missing persisted request remains a successful hidden exit",
    "typed delivery failure does not escape the entrypoint",
    "unexpected delivery exception is converted to non-zero exit",
    "hidden mode never invokes dashboard, router, or startup sentinels",
    "normal runner failure is not mislabeled as hidden delivery",
    "opens only binding, repository, and gateway in order",
    "resources close gateway and database exactly once",
    "gateway initialization failure closes opened repository",
    "repository initialization failure does not create gateway",
    "close attempts repository after gateway close failure",
    "harness.resourcesOpenCalls",
    "harness.normalRunner.dashboardBuilds",
    "harness.normalRunner.routerStarts",
    "harness.normalRunner.startupReconciliations",
)
missing_tests = [token for token in required_tests if token not in tests]
if missing_tests:
    print(f"ERROR: Task 10.6.5 GREEN coverage incomplete: {missing_tests}")
    sys.exit(1)

# Entry parsing, service orchestration, and typed results from previous Gates
# must remain the dependencies rather than being duplicated in app bootstrap.
for label, path in (
    ("service", paths["service"]),
    ("invocation", paths["invocation"]),
    ("result", paths["result"]),
):
    if path.stat().st_size == 0:
        print(f"ERROR: required prior-Gate {label} file is empty.")
        sys.exit(1)

combined = "\n".join((entrypoint, bootstrap, main, tests))
for forbidden in (
    "Process.start",
    "Process.run",
    "Directory.systemTemp",
    "Future.delayed(",
    "TODO",
    "FIXME",
    "UnimplementedError",
):
    if forbidden in combined:
        print(f"ERROR: Task 10.6.5 contains forbidden behavior: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.6.5 GREEN routes main arguments through a typed application "
    "entrypoint before the preserved normal startup body, keeps ordinary startup "
    "unchanged, prevents UI/router/reconciliation bootstrap in hidden mode, maps "
    "invalid and delivery outcomes to process exit codes without escaping, opens "
    "only Flutter binding, AppDatabase/Drift lookup, and the initialized local "
    "notification gateway, rolls back partial initialization, and closes gateway "
    "and database idempotently."
)
