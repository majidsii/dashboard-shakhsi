import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';
import 'package:dashboard_shakhsi/core/notifications/device_time_zone_source.dart';
import 'package:dashboard_shakhsi/core/notifications/drift_notification_schedule_repository.dart';
import 'package:dashboard_shakhsi/core/notifications/local_notification_plugin_config.dart';
import 'package:dashboard_shakhsi/core/notifications/local_notifications_driver.dart';
import 'package:dashboard_shakhsi/core/notifications/local_notifications_initializer.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_coordinator.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_permission.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_permission_service.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_platform_providers.dart'
    as notification_platform;
import 'package:dashboard_shakhsi/core/notifications/notification_request.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_schedule_repository.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_startup_service.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_time_zone_initializer.dart';
import 'package:dashboard_shakhsi/features/finance/application/finance_report_service.dart';
import 'package:dashboard_shakhsi/features/finance/data/drift_finance_repository.dart';
import 'package:dashboard_shakhsi/features/finance/domain/debt.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_repository.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:dashboard_shakhsi/features/finance/domain/installment_plan.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appClockProvider = Provider<AppClock>((ref) {
  return const SystemAppClock();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DriftTaskRepository(ref.watch(appDatabaseProvider));
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return DriftFinanceRepository(ref.watch(appDatabaseProvider));
});

final notificationScheduleRepositoryProvider =
    Provider<NotificationScheduleRepository>((ref) {
      return DriftNotificationScheduleRepository(
        ref.watch(appDatabaseProvider),
        clock: ref.watch(appClockProvider),
      );
    });

final notificationSchedulesProvider = StreamProvider<List<NotificationRequest>>(
  (ref) {
    return ref.watch(notificationScheduleRepositoryProvider).watchAll();
  },
);

final taskItemsProvider = StreamProvider<List<TaskItem>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});

final financeTransactionsProvider = StreamProvider<List<FinanceTransaction>>((
  ref,
) {
  return ref.watch(financeRepositoryProvider).watchTransactions();
});

final debtsProvider = StreamProvider<List<Debt>>((ref) {
  return ref.watch(financeRepositoryProvider).watchDebts();
});

final installmentPlansProvider = StreamProvider<List<InstallmentPlan>>((ref) {
  return ref.watch(financeRepositoryProvider).watchInstallmentPlans();
});

final financeReportServiceProvider = Provider<FinanceReportService>((ref) {
  return const FinanceReportService();
});

final notificationSchedulerProvider =
    notification_platform.notificationSchedulerProvider;

final notificationCoordinatorProvider = Provider<NotificationCoordinator>((
  ref,
) {
  return NotificationCoordinator(
    repository: ref.watch(notificationScheduleRepositoryProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
  );
});

final notificationHostPlatformProvider =
    notification_platform.notificationHostPlatformProvider;

final notificationPlatformCapabilitiesProvider =
    notification_platform.notificationPlatformCapabilitiesProvider;

final localNotificationPluginConfigProvider =
    Provider<LocalNotificationPluginConfig>((ref) {
      return const LocalNotificationPluginConfig.defaults();
    });

final deviceTimeZoneSourceProvider = Provider<DeviceTimeZoneSource>((ref) {
  return const FlutterDeviceTimeZoneSource();
});

final notificationTimeZoneRuntimeProvider =
    Provider<NotificationTimeZoneRuntime>((ref) {
      return const TimezonePackageRuntime();
    });

final flutterLocalNotificationsDriverProvider =
    notification_platform.flutterLocalNotificationsDriverProvider;

final localNotificationsDriverProvider = Provider<LocalNotificationsDriver>((
  ref,
) {
  return ref.watch(flutterLocalNotificationsDriverProvider);
});

final nativeNotificationGatewayProvider =
    notification_platform.nativeNotificationGatewayProvider;

final notificationTimeZoneInitializerProvider =
    Provider<NotificationTimeZoneInitializer>((ref) {
      return NotificationTimeZoneInitializer(
        source: ref.watch(deviceTimeZoneSourceProvider),
        runtime: ref.watch(notificationTimeZoneRuntimeProvider),
      );
    });

final localNotificationsInitializerProvider =
    Provider<LocalNotificationsInitializer>((ref) {
      return LocalNotificationsInitializer(
        timeZoneInitializer: ref.watch(notificationTimeZoneInitializerProvider),
        driver: ref.watch(localNotificationsDriverProvider),
      );
    });

final notificationStartupProvider = Provider<NotificationStartup>((ref) {
  final capabilities = ref.watch(notificationPlatformCapabilitiesProvider);
  final enabled =
      capabilities.supportsImmediateDelivery ||
      capabilities.supportsScheduledDelivery;

  return NotificationStartupService(
    enabled: enabled,
    initializer: ref.watch(localNotificationsInitializerProvider),
    coordinator: ref.watch(notificationCoordinatorProvider),
  );
});

final notificationPermissionGatewayProvider =
    Provider<NotificationPermissionGateway>((ref) {
      return ref.watch(flutterLocalNotificationsDriverProvider);
    });

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
      return NotificationPermissionService(
        permissionGateway: ref.watch(notificationPermissionGatewayProvider),
        notificationGateway: ref.watch(nativeNotificationGatewayProvider),
      );
    });

final notificationPermissionHealthProvider =
    FutureProvider<NotificationPermissionHealth>((ref) {
      return ref.watch(notificationPermissionServiceProvider).health();
    });
