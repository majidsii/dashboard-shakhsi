import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';

enum TaskDetailsField { title, startAt, dueAt, estimatedDuration }

final class TaskDetailsDraft {
  TaskDetailsDraft({
    required this.title,
    required this.description,
    required this.priority,
    required this.startLocal,
    required this.dueLocal,
    required this.estimatedHours,
    required this.estimatedMinutes,
  });

  factory TaskDetailsDraft.create({
    required DateTime nowLocal,
    int priority = 0,
  }) {
    return TaskDetailsDraft(
      title: '',
      description: '',
      priority: priority,
      startLocal: null,
      dueLocal: null,
      estimatedHours: 0,
      estimatedMinutes: 0,
    );
  }

  factory TaskDetailsDraft.fromTask(TaskItem task) {
    final durationMinutes = task.estimatedDurationMinutes ?? 0;

    return TaskDetailsDraft(
      title: task.title,
      description: task.description ?? '',
      priority: task.priority,
      startLocal: task.startAtUtc?.toLocal(),
      dueLocal: task.dueAtUtc?.toLocal(),
      estimatedHours: durationMinutes ~/ 60,
      estimatedMinutes: durationMinutes % 60,
    );
  }

  String title;
  String description;
  int priority;
  DateTime? startLocal;
  DateTime? dueLocal;
  int estimatedHours;
  int estimatedMinutes;

  Map<TaskDetailsField, String> validate() {
    final errors = <TaskDetailsField, String>{};

    if (title.trim().isEmpty) {
      errors[TaskDetailsField.title] = 'عنوان کار نمی‌تواند خالی باشد.';
    }

    final start = startLocal;
    if (start != null && start.isUtc) {
      errors[TaskDetailsField.startAt] =
          'زمان شروع باید به‌صورت زمان محلی وارد شود.';
    }

    final due = dueLocal;
    if (due != null && due.isUtc) {
      errors[TaskDetailsField.dueAt] =
          'زمان سررسید باید به‌صورت زمان محلی وارد شود.';
    } else if (start != null && due != null && due.isBefore(start)) {
      errors[TaskDetailsField.dueAt] =
          'زمان سررسید نمی‌تواند قبل از زمان شروع باشد.';
    }

    if (estimatedHours < 0) {
      errors[TaskDetailsField.estimatedDuration] =
          'ساعت مدت تخمینی نمی‌تواند منفی باشد.';
    } else if (estimatedMinutes < 0 || estimatedMinutes > 59) {
      errors[TaskDetailsField.estimatedDuration] =
          'دقیقه مدت تخمینی باید بین ۰ تا ۵۹ باشد.';
    }

    return errors;
  }

  TaskItem buildNewTask({required String id, required DateTime savedAtUtc}) {
    _throwIfInvalid();

    return TaskItem(
      id: id,
      displayNumber: 1,
      title: title.trim(),
      description: _normalizedDescription,
      priority: priority,
      status: TaskStatus.planned,
      positionInStatus: 0,
      startAtUtc: startLocal?.toUtc(),
      dueAtUtc: dueLocal?.toUtc(),
      estimatedDurationMinutes: _normalizedDurationMinutes,
      createdAtUtc: savedAtUtc,
      updatedAtUtc: savedAtUtc,
    );
  }

  TaskItem applyTo({required TaskItem task, required DateTime savedAtUtc}) {
    _throwIfInvalid();

    final normalizedDescription = _normalizedDescription;
    final startAtUtc = startLocal?.toUtc();
    final dueAtUtc = dueLocal?.toUtc();
    final durationMinutes = _normalizedDurationMinutes;

    return task.copyWith(
      title: title.trim(),
      description: normalizedDescription,
      clearDescription: normalizedDescription == null,
      priority: priority,
      startAtUtc: startAtUtc,
      clearStartAt: startAtUtc == null,
      dueAtUtc: dueAtUtc,
      clearDueAt: dueAtUtc == null,
      estimatedDurationMinutes: durationMinutes,
      clearEstimatedDuration: durationMinutes == null,
      updatedAtUtc: savedAtUtc,
    );
  }

  String? get _normalizedDescription {
    final normalized = description.trim();
    return normalized.isEmpty ? null : normalized;
  }

  int? get _normalizedDurationMinutes {
    if (estimatedHours == 0 && estimatedMinutes == 0) {
      return null;
    }

    return estimatedHours * 60 + estimatedMinutes;
  }

  void _throwIfInvalid() {
    final errors = validate();
    if (errors.isNotEmpty) {
      throw ValidationFailure(errors.values.first);
    }
  }
}
