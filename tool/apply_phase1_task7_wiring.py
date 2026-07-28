#!/usr/bin/env python3
from pathlib import Path
import re

providers_path = Path('lib/core/providers/persistence_providers.dart')
source = providers_path.read_text(encoding='utf-8')

required_imports = {
    "import 'package:dashboard_shakhsi/core/notifications/device_time_zone_source.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/flutter_local_notifications_driver.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/local_notification_plugin_config.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/local_notifications_driver.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/local_notifications_initializer.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/native_notification_gateway.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/notification_host_platform.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/notification_platform_capabilities.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/notification_startup_service.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/notification_time_zone_initializer.dart';",
    "import 'package:dashboard_shakhsi/core/notifications/platform_notification_scheduler.dart';",
    "import 'package:flutter/foundation.dart';",
}

lines = source.splitlines()
imports = {line for line in lines if line.startswith('import ')}
imports.update(required_imports)

non_import_lines = [line for line in lines if not line.startswith('import ')]
while non_import_lines and not non_import_lines[0].strip():
    non_import_lines.pop(0)

source = '\n'.join(sorted(imports) + [''] + non_import_lines).rstrip() + '\n'

scheduler_pattern = re.compile(
    r'final notificationSchedulerProvider\s*=\s*'
    r'Provider<NotificationScheduler>\(\(ref\)\s*\{.*?\n\}\);',
    re.DOTALL,
)

scheduler_block = """final notificationSchedulerProvider =
    Provider<NotificationScheduler>((ref) {
      final capabilities = ref.watch(
        notificationPlatformCapabilitiesProvider,
      );

      if (!capabilities.supportsImmediateDelivery &&
          !capabilities.supportsScheduledDelivery) {
        return const NoopNotificationScheduler();
      }

      return PlatformNotificationScheduler(
        gateway: ref.watch(nativeNotificationGatewayProvider),
        capabilities: capabilities,
        clock: ref.watch(appClockProvider),
      );
    });"""

if scheduler_pattern.search(source):
    source = scheduler_pattern.sub(scheduler_block, source, count=1)
else:
    source = source.rstrip() + '\n\n' + scheduler_block + '\n'

provider_blocks = {
    'notificationHostPlatformProvider': """
final notificationHostPlatformProvider =
    Provider<NotificationHostPlatform>((ref) {
      return detectNotificationHostPlatform(
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
      );
    });
""",
    'notificationPlatformCapabilitiesProvider': """
final notificationPlatformCapabilitiesProvider =
    Provider<NotificationPlatformCapabilities>((ref) {
      return NotificationPlatformCapabilities.forPlatform(
        ref.watch(notificationHostPlatformProvider),
      );
    });
""",
    'localNotificationPluginConfigProvider': """
final localNotificationPluginConfigProvider =
    Provider<LocalNotificationPluginConfig>((ref) {
      return const LocalNotificationPluginConfig.defaults();
    });
""",
    'deviceTimeZoneSourceProvider': """
final deviceTimeZoneSourceProvider =
    Provider<DeviceTimeZoneSource>((ref) {
      return const FlutterDeviceTimeZoneSource();
    });
""",
    'notificationTimeZoneRuntimeProvider': """
final notificationTimeZoneRuntimeProvider =
    Provider<NotificationTimeZoneRuntime>((ref) {
      return const TimezonePackageRuntime();
    });
""",
    'flutterLocalNotificationsDriverProvider': """
final flutterLocalNotificationsDriverProvider =
    Provider<FlutterLocalNotificationsDriver>((ref) {
      return FlutterLocalNotificationsDriver(
        config: ref.watch(localNotificationPluginConfigProvider),
      );
    });
""",
    'localNotificationsDriverProvider': """
final localNotificationsDriverProvider =
    Provider<LocalNotificationsDriver>((ref) {
      return ref.watch(flutterLocalNotificationsDriverProvider);
    });
""",
    'nativeNotificationGatewayProvider': """
final nativeNotificationGatewayProvider =
    Provider<NativeNotificationGateway>((ref) {
      return ref.watch(flutterLocalNotificationsDriverProvider);
    });
""",
    'notificationTimeZoneInitializerProvider': """
final notificationTimeZoneInitializerProvider =
    Provider<NotificationTimeZoneInitializer>((ref) {
      return NotificationTimeZoneInitializer(
        source: ref.watch(deviceTimeZoneSourceProvider),
        runtime: ref.watch(notificationTimeZoneRuntimeProvider),
      );
    });
""",
    'localNotificationsInitializerProvider': """
final localNotificationsInitializerProvider =
    Provider<LocalNotificationsInitializer>((ref) {
      return LocalNotificationsInitializer(
        timeZoneInitializer: ref.watch(
          notificationTimeZoneInitializerProvider,
        ),
        driver: ref.watch(localNotificationsDriverProvider),
      );
    });
""",
    'notificationStartupProvider': """
final notificationStartupProvider = Provider<NotificationStartup>((ref) {
  final capabilities = ref.watch(
    notificationPlatformCapabilitiesProvider,
  );
  final enabled = capabilities.supportsImmediateDelivery ||
      capabilities.supportsScheduledDelivery;

  return NotificationStartupService(
    enabled: enabled,
    initializer: ref.watch(localNotificationsInitializerProvider),
    coordinator: ref.watch(notificationCoordinatorProvider),
  );
});
""",
}

for name, block in provider_blocks.items():
    if f'final {name}' not in source:
        source = source.rstrip() + '\n\n' + block.strip() + '\n'

providers_path.write_text(source, encoding='utf-8')

bootstrap_path = Path('lib/app/bootstrap/app_bootstrap.dart')
bootstrap = bootstrap_path.read_text(encoding='utf-8')

provider_import = (
    "import 'package:dashboard_shakhsi/core/providers/"
    "persistence_providers.dart';\n"
)
router_import = (
    "import 'package:dashboard_shakhsi/app/router/app_router.dart';\n"
)
if provider_import not in bootstrap:
    if router_import not in bootstrap:
        raise SystemExit('Bootstrap import anchor was not found.')
    bootstrap = bootstrap.replace(
        router_import,
        router_import + provider_import,
        1,
    )

old_run_app = (
    "  runApp(const ProviderScope(child: DashboardShakhsiApp()));"
)
new_run_app = """  final container = ProviderContainer();

  try {
    await initializeNotificationsForApp(container);
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'dashboard_shakhsi',
        context: ErrorDescription(
          'while initializing local notifications',
        ),
      ),
    );
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DashboardShakhsiApp(),
    ),
  );"""

if old_run_app in bootstrap:
    bootstrap = bootstrap.replace(old_run_app, new_run_app, 1)
elif 'UncontrolledProviderScope(' not in bootstrap:
    raise SystemExit('Bootstrap runApp anchor was not found.')

helper = """
@visibleForTesting
Future<void> initializeNotificationsForApp(
  ProviderContainer container,
) {
  return container.read(notificationStartupProvider).initialize();
}
"""

if 'Future<void> initializeNotificationsForApp(' not in bootstrap:
    marker = '\nfinal class DashboardShakhsiApp'
    if marker not in bootstrap:
        raise SystemExit('DashboardShakhsiApp marker was not found.')
    bootstrap = bootstrap.replace(
        marker,
        '\n' + helper.strip() + '\n\nfinal class DashboardShakhsiApp',
        1,
    )

bootstrap_path.write_text(bootstrap, encoding='utf-8')

print('Phase 1 Task 7 runtime providers and bootstrap applied.')
