import 'notification_owner.dart';
import 'notification_request.dart';
import 'notification_scheduler.dart';

final class NoopNotificationScheduler implements NotificationScheduler {
  const NoopNotificationScheduler();

  @override
  Future<void> schedule(NotificationRequest request) async {}

  @override
  Future<void> cancel(String scheduleId) async {}

  @override
  Future<void> cancelByOwner(NotificationOwner owner) async {}

  @override
  Future<void> reconcile(List<NotificationRequest> expected) async {}
}
