import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';
import 'package:dashboard_shakhsi/core/ids/id_generator.dart';
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
import 'package:dashboard_shakhsi/features/tasks/application/task_occurrence_projector.dart';
import 'package:dashboard_shakhsi/features/tasks/application/task_recurrence_service.dart';
import 'package:dashboard_shakhsi/features/tasks/application/task_reminder_projection_service.dart';
import 'package:dashboard_shakhsi/features/tasks/application/task_reminder_rules_service.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_recurrence_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_reminder_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/data/reminder_aware_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_occurrence_completion.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_recurrence_exception.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_recurrence_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_recurrence_rule.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_reminder_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_reminder_rule.dart';
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

final baseTaskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DriftTaskRepository(ref.watch(appDatabaseProvider));
});

final taskReminderRepositoryProvider = Provider<TaskReminderRepository>((ref) {
  return DriftTaskReminderRepository(ref.watch(appDatabaseProvider));
});

final taskRecurrenceRepositoryProvider = Provider<TaskRecurrenceRepository>((
  ref,
) {
  return DriftTaskRecurrenceRepository(ref.watch(appDatabaseProvider));
});

final taskOccurrenceProjectorProvider = Provider<TaskOccurrenceProjector>((
  ref,
) {
  return const TaskOccurrenceProjector();
});

final taskReminderProjectionServiceProvider =
    Provider<TaskReminderProjectionService>((ref) {
      return TaskReminderProjectionService(
        reminderRepository: ref.watch(taskReminderRepositoryProvider),
        coordinator: ref.watch(notificationCoordinatorProvider),
        nowUtc: () => ref.read(appClockProvider).nowUtc(),
        recurrenceRepository: ref.watch(taskRecurrenceRepositoryProvider),
        occurrenceProjector: ref.watch(taskOccurrenceProjectorProvider),
        floatingTimeZoneId: () =>
            ref.read(deviceTimeZoneSourceProvider).localTimeZoneName(),
      );
    });

final taskReminderRulesServiceProvider = Provider<TaskReminderRulesService>((
  ref,
) {
  return TaskReminderRulesService(
    repository: ref.watch(taskReminderRepositoryProvider),
    projection: ref.watch(taskReminderProjectionServiceProvider),
  );
});

final taskRecurrenceServiceProvider = Provider<TaskRecurrenceService>((ref) {
  return TaskRecurrenceService(
    repository: ref.watch(taskRecurrenceRepositoryProvider),
    nowUtc: () => ref.read(appClockProvider).nowUtc(),
    nextId: const UuidV7IdGenerator().next,
    onChanged: (taskId) async {
      final task = await ref.read(baseTaskRepositoryProvider).getById(taskId);
      if (task != null) {
        await ref.read(taskReminderProjectionServiceProvider).reproject(task);
      }
    },
  );
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return ReminderAwareTaskRepository(
    inner: ref.watch(baseTaskRepositoryProvider),
    reminderRepository: ref.watch(taskReminderRepositoryProvider),
    projection: () => ref.read(taskReminderProjectionServiceProvider),
  );
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

final taskReminderRulesProvider =
    StreamProvider.family<List<TaskReminderRule>, String>((ref, taskId) {
      return ref.watch(taskReminderRepositoryProvider).watchByTask(taskId);
    });

final taskRecurrenceRulesProvider = StreamProvider<List<TaskRecurrenceRule>>((
  ref,
) {
  return ref.watch(taskRecurrenceRepositoryProvider).watchRules();
});

final taskRecurrenceExceptionsProvider =
    StreamProvider<List<TaskRecurrenceException>>((ref) {
      return ref.watch(taskRecurrenceRepositoryProvider).watchExceptions();
    });

final taskOccurrenceCompletionsProvider =
    StreamProvider<List<TaskOccurrenceCompletion>>((ref) {
      return ref.watch(taskRecurrenceRepositoryProvider).watchCompletions();
    });

final taskCalendarTimeZoneProvider = FutureProvider<String>((ref) {
  return ref.watch(deviceTimeZoneSourceProvider).localTimeZoneName();
});

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
