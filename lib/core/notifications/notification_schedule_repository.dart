import 'notification_owner.dart';
import 'notification_request.dart';

abstract interface class NotificationScheduleRepository {
  Stream<List<NotificationRequest>> watchAll();

  Future<List<NotificationRequest>> getAll();

  Future<void> upsert(NotificationRequest request);

  Future<void> delete(String scheduleId);

  Future<void> deleteByOwner(NotificationOwner owner);

  Future<void> replaceAll(List<NotificationRequest> expected);
}
