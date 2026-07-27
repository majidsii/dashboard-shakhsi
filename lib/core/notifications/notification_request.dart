import 'notification_owner.dart';

enum NotificationPrivacyMode {
  full,
  private,
}

final class NotificationRequest {
  NotificationRequest({
    required String scheduleId,
    required this.owner,
    required String title,
    required this.body,
    required DateTime scheduledAtUtc,
    Map<String, String> payload = const <String, String>{},
    this.privacyMode = NotificationPrivacyMode.full,
  }) : scheduleId = _requiredText(
         scheduleId,
         fieldName: 'scheduleId',
         message: 'Notification schedule id cannot be blank.',
       ),
       title = _requiredText(
         title,
         fieldName: 'title',
         message: 'Notification title cannot be blank.',
       ),
       scheduledAtUtc = _requireUtc(scheduledAtUtc),
       payload = Map<String, String>.unmodifiable(payload);

  final String scheduleId;
  final NotificationOwner owner;
  final String title;
  final String body;
  final DateTime scheduledAtUtc;
  final Map<String, String> payload;
  final NotificationPrivacyMode privacyMode;

  static String _requiredText(
    String value, {
    required String fieldName,
    required String message,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, fieldName, message);
    }
    return normalized;
  }

  static DateTime _requireUtc(DateTime value) {
    if (!value.isUtc) {
      throw ArgumentError.value(
        value,
        'scheduledAtUtc',
        'Notification schedule must use a UTC DateTime.',
      );
    }
    return value;
  }
}
