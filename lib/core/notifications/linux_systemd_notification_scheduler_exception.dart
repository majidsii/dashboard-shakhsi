import 'linux_systemd_notification_unit.dart';
import 'linux_systemd_timer_status.dart';
import 'notification_owner.dart';

enum LinuxSystemdNotificationSchedulerOperation {
  schedule,
  cancel,
  cancelByOwner,
  reconcile,
}

enum LinuxSystemdNotificationSchedulerFailure {
  commandFactoryFailed,
  renderFailed,
  unitTransactionFailed,
  daemonReloadFailed,
  mutationFailed,
  registryFailed,
  rollbackFailed,
  partialOwnerCancellation,
  partialReconciliation,
}

final class LinuxSystemdSchedulerRollbackFailure {
  const LinuxSystemdSchedulerRollbackFailure({
    required this.step,
    required this.error,
    required this.stackTrace,
  });

  final String step;
  final Object error;
  final StackTrace stackTrace;
}

final class LinuxSystemdNotificationSchedulerException implements Exception {
  factory LinuxSystemdNotificationSchedulerException({
    required LinuxSystemdNotificationSchedulerOperation operation,
    required LinuxSystemdNotificationSchedulerFailure failure,
    String? scheduleId,
    NotificationOwner? owner,
    LinuxSystemdUnitNames? names,
    Object? cause,
    StackTrace? causeStackTrace,
    List<LinuxSystemdSchedulerRollbackFailure> rollbackFailures =
        const <LinuxSystemdSchedulerRollbackFailure>[],
    LinuxSystemdTimerStatus? confirmedStatus,
    Iterable<String> completedScheduleIds = const <String>[],
  }) {
    return LinuxSystemdNotificationSchedulerException._(
      operation: operation,
      failure: failure,
      scheduleId: scheduleId,
      owner: owner,
      names: names,
      cause: cause,
      causeStackTrace: causeStackTrace,
      rollbackFailures: List<LinuxSystemdSchedulerRollbackFailure>.unmodifiable(
        rollbackFailures,
      ),
      confirmedStatus: confirmedStatus,
      completedScheduleIds: List<String>.unmodifiable(completedScheduleIds),
    );
  }

  const LinuxSystemdNotificationSchedulerException._({
    required this.operation,
    required this.failure,
    required this.scheduleId,
    required this.owner,
    required this.names,
    required this.cause,
    required this.causeStackTrace,
    required this.rollbackFailures,
    required this.confirmedStatus,
    required this.completedScheduleIds,
  });

  final LinuxSystemdNotificationSchedulerOperation operation;
  final LinuxSystemdNotificationSchedulerFailure failure;
  final String? scheduleId;
  final NotificationOwner? owner;
  final LinuxSystemdUnitNames? names;
  final Object? cause;
  final StackTrace? causeStackTrace;
  final List<LinuxSystemdSchedulerRollbackFailure> rollbackFailures;
  final LinuxSystemdTimerStatus? confirmedStatus;
  final List<String> completedScheduleIds;

  @override
  String toString() {
    final parts = <String>[
      'operation=${operation.name}',
      'failure=${failure.name}',
      if (scheduleId != null) 'scheduleId=$scheduleId',
      if (owner != null) 'ownerType=${owner!.type.name}',
      if (names != null) 'unit=${names!.baseName}',
      'rollbackFailures=${rollbackFailures.length}',
      'completedScheduleIds=${completedScheduleIds.length}',
      'confirmedStatus=${confirmedStatus == null ? 'none' : 'present'}',
    ];

    return 'LinuxSystemdNotificationSchedulerException('
        '${parts.join(', ')})';
  }
}
