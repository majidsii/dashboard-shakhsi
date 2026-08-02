enum LinuxNotificationDeliveryOperation { initialize, lookup, display, close }

enum LinuxNotificationDeliveryFailure {
  initializationFailed,
  lookupFailed,
  displayFailed,
  closeFailed,
}

final class LinuxNotificationDeliveryException implements Exception {
  const LinuxNotificationDeliveryException._({
    required this.operation,
    required this.failure,
    required this.cause,
    required this.causeStackTrace,
  });

  factory LinuxNotificationDeliveryException.forOperation({
    required LinuxNotificationDeliveryOperation operation,
    required Object cause,
    required StackTrace causeStackTrace,
  }) {
    return LinuxNotificationDeliveryException._(
      operation: operation,
      failure: switch (operation) {
        LinuxNotificationDeliveryOperation.initialize =>
          LinuxNotificationDeliveryFailure.initializationFailed,
        LinuxNotificationDeliveryOperation.lookup =>
          LinuxNotificationDeliveryFailure.lookupFailed,
        LinuxNotificationDeliveryOperation.display =>
          LinuxNotificationDeliveryFailure.displayFailed,
        LinuxNotificationDeliveryOperation.close =>
          LinuxNotificationDeliveryFailure.closeFailed,
      },
      cause: cause,
      causeStackTrace: causeStackTrace,
    );
  }

  final LinuxNotificationDeliveryOperation operation;
  final LinuxNotificationDeliveryFailure failure;
  final Object cause;
  final StackTrace causeStackTrace;

  @override
  String toString() {
    return 'LinuxNotificationDeliveryException('
        'operation=${operation.name}, '
        'failure=${failure.name}, '
        'causeType=${cause.runtimeType}'
        ')';
  }
}
