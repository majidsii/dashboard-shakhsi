import 'package:dashboard_shakhsi/core/notifications/notification_owner.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_request.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_reminder_rule.dart';

final class TaskReminderProjector {
  const TaskReminderProjector();

  List<NotificationRequest> project({
    required TaskItem task,
    required List<TaskReminderRule> rules,
    required DateTime nowUtc,
  }) {
    if (!nowUtc.isUtc) {
      throw ArgumentError.value(
        nowUtc,
        'nowUtc',
        'Reminder projection requires UTC.',
      );
    }

    final dueAtUtc = task.dueAtUtc;
    if (!task.isActive || dueAtUtc == null) {
      return const <NotificationRequest>[];
    }

    final requests = <NotificationRequest>[];
    final seenTriggers = <Object>{};

    for (final rule in rules) {
      if (rule.taskId != task.id) {
        throw ArgumentError.value(
          rule.taskId,
          'rules',
          'Reminder rule does not belong to task ${task.id}.',
        );
      }
      if (!seenTriggers.add(rule.trigger)) {
        throw ArgumentError.value(
          rules,
          'rules',
          'Duplicate task reminder triggers are not allowed.',
        );
      }
      if (!rule.enabled) continue;

      final scheduledAtUtc = rule.trigger.scheduledAtUtc(dueAtUtc);
      if (!scheduledAtUtc.isAfter(nowUtc)) continue;

      requests.add(
        NotificationRequest(
          scheduleId: rule.scheduleId,
          owner: NotificationOwner(
            type: NotificationOwnerType.task,
            id: task.id,
          ),
          title: 'یادآور کار: ${task.title}',
          body: _bodyFor(task, rule),
          scheduledAtUtc: scheduledAtUtc,
          payload: <String, String>{
            'route': '/tasks/${task.id}',
            'taskId': task.id,
            'reminderRuleId': rule.id,
            'trigger': rule.trigger.storageValue,
          },
          privacyMode: rule.privacyMode,
        ),
      );
    }

    requests.sort((left, right) {
      final time = left.scheduledAtUtc.compareTo(right.scheduledAtUtc);
      if (time != 0) return time;
      return left.scheduleId.compareTo(right.scheduleId);
    });
    return List<NotificationRequest>.unmodifiable(requests);
  }
}

String _bodyFor(TaskItem task, TaskReminderRule rule) {
  return switch (rule.trigger.offsetMinutes) {
    0 => 'زمان انجام «${task.title}» رسیده است.',
    final minutes when minutes < 60 =>
      'تا سررسید «${task.title}»، $minutes دقیقه باقی مانده است.',
    final minutes when minutes % 1440 == 0 =>
      'تا سررسید «${task.title}»، ${minutes ~/ 1440} روز باقی مانده است.',
    final minutes =>
      'تا سررسید «${task.title}»، ${minutes ~/ 60} ساعت باقی مانده است.',
  };
}
