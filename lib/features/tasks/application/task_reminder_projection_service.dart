import 'package:dashboard_shakhsi/core/notifications/notification_coordinator.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_owner.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_request.dart';
import 'package:dashboard_shakhsi/features/tasks/application/task_reminder_projector.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_reminder_repository.dart';

final class TaskReminderProjectionService {
  factory TaskReminderProjectionService({
    required TaskReminderRepository reminderRepository,
    required NotificationCoordinator coordinator,
    required DateTime Function() nowUtc,
    TaskReminderProjector projector = const TaskReminderProjector(),
  }) {
    return TaskReminderProjectionService._(
      reminderRepository,
      coordinator,
      nowUtc,
      projector,
    );
  }

  const TaskReminderProjectionService._(
    this._reminderRepository,
    this._coordinator,
    this._nowUtc,
    this._projector,
  );

  final TaskReminderRepository _reminderRepository;
  final NotificationCoordinator _coordinator;
  final DateTime Function() _nowUtc;
  final TaskReminderProjector _projector;

  Future<void> reproject(TaskItem task) async {
    final rules = await _reminderRepository.getByTask(task.id);
    final expected = _projector.project(
      task: task,
      rules: rules,
      nowUtc: _nowUtc().toUtc(),
    );
    await _coordinator.replaceByOwner(_owner(task.id), expected);
  }

  Future<void> clear(String taskId) {
    return _coordinator.replaceByOwner(
      _owner(taskId),
      const <NotificationRequest>[],
    );
  }
}

NotificationOwner _owner(String taskId) {
  return NotificationOwner(type: NotificationOwnerType.task, id: taskId);
}
