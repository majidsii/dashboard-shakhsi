import 'notification_owner.dart';
import 'notification_request.dart';
import 'notification_schedule_repository.dart';
import 'notification_scheduler.dart';

final class NotificationCoordinator {
  factory NotificationCoordinator({
    required NotificationScheduleRepository repository,
    required NotificationScheduler scheduler,
  }) {
    return NotificationCoordinator._(repository, scheduler);
  }

  const NotificationCoordinator._(this._repository, this._scheduler);

  final NotificationScheduleRepository _repository;
  final NotificationScheduler _scheduler;

  Future<void> schedule(NotificationRequest request) async {
    await _repository.upsert(request);
    await _scheduler.schedule(request);
  }

  Future<void> cancel(String scheduleId) async {
    await _repository.delete(scheduleId);
    await _scheduler.cancel(scheduleId);
  }

  Future<void> cancelByOwner(NotificationOwner owner) async {
    await _repository.deleteByOwner(owner);
    await _scheduler.cancelByOwner(owner);
  }

  Future<void> replaceAll(List<NotificationRequest> expected) async {
    final desired = _deduplicate(expected);
    await _repository.replaceAll(desired);
    await _scheduler.reconcile(desired);
  }

  Future<void> replaceByOwner(
    NotificationOwner owner,
    List<NotificationRequest> expected,
  ) async {
    for (final request in expected) {
      if (request.owner != owner) {
        throw ArgumentError.value(
          request.owner,
          'expected',
          'Every notification request must belong to $owner.',
        );
      }
    }

    final current = await _repository.getAll();
    final merged = <NotificationRequest>[
      for (final request in current)
        if (request.owner != owner) request,
      ...expected,
    ];
    await replaceAll(merged);
  }

  Future<void> reconcileFromPersistence() async {
    final expected = await _repository.getAll();
    await _scheduler.reconcile(expected);
  }
}

List<NotificationRequest> _deduplicate(List<NotificationRequest> requests) {
  final byScheduleId = <String, NotificationRequest>{};
  for (final request in requests) {
    byScheduleId[request.scheduleId] = request;
  }
  return List<NotificationRequest>.unmodifiable(byScheduleId.values);
}
