import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';
import 'package:dashboard_shakhsi/core/notifications/drift_notification_schedule_repository.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_request.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_schedule_repository.dart';
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
