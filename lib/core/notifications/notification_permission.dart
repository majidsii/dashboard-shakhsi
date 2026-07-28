enum NotificationPermissionStatus { granted, denied, notRequired, unavailable }

extension NotificationPermissionStatusDelivery on NotificationPermissionStatus {
  bool get allowsDelivery {
    return this == NotificationPermissionStatus.granted ||
        this == NotificationPermissionStatus.notRequired;
  }
}

NotificationPermissionStatus notificationPermissionStatusFromNullableBool(
  bool? value,
) {
  return switch (value) {
    true => NotificationPermissionStatus.granted,
    false => NotificationPermissionStatus.denied,
    null => NotificationPermissionStatus.unavailable,
  };
}

abstract interface class NotificationPermissionGateway {
  Future<NotificationPermissionStatus> status();

  Future<NotificationPermissionStatus> request();
}

final class NotificationPermissionHealth {
  const NotificationPermissionHealth({required this.status});

  final NotificationPermissionStatus status;

  bool get canDeliver => status.allowsDelivery;

  bool get canRequest => status == NotificationPermissionStatus.denied;
}
