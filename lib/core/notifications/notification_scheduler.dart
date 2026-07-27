import 'notification_owner.dart';
import 'notification_request.dart';

abstract interface class NotificationScheduler {
  Future<void> schedule(NotificationRequest request);

  Future<void> cancel(String scheduleId);

  Future<void> cancelByOwner(NotificationOwner owner);

  Future<void> reconcile(List<NotificationRequest> expected);
}
