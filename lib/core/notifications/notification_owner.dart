enum NotificationOwnerType {
  task,
  habit,
  routine,
  challenge,
  installment,
  debt,
  recurringTransaction,
  dailySummary,
}

final class NotificationOwner {
  factory NotificationOwner({
    required NotificationOwnerType type,
    required String id,
  }) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'Notification owner id cannot be blank.',
      );
    }

    return NotificationOwner._(type: type, id: normalizedId);
  }

  const NotificationOwner._({required this.type, required this.id});

  final NotificationOwnerType type;
  final String id;

  @override
  bool operator ==(Object other) {
    return other is NotificationOwner && other.type == type && other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => '${type.name}:$id';
}
