final class NativePendingNotification {
  const NativePendingNotification({required this.id, required this.payload});

  final int id;
  final String? payload;
}

abstract interface class NativeNotificationGateway {
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  });

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAtUtc,
    required String payload,
  });

  Future<void> cancel(int id);

  Future<List<NativePendingNotification>> pending();
}
