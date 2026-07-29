/// High-level operation performed by the systemd user-unit store.
enum LinuxSystemdUserUnitStoreOperation { install, remove }

/// One failure encountered while attempting rollback or cleanup.
final class LinuxSystemdRollbackFailure {
  const LinuxSystemdRollbackFailure({
    required this.step,
    required this.error,
    required this.stackTrace,
  });

  final String step;
  final Object error;
  final StackTrace stackTrace;
}

/// Structured store failure that keeps the original cause primary.
final class LinuxSystemdUserUnitStoreException implements Exception {
  factory LinuxSystemdUserUnitStoreException({
    required LinuxSystemdUserUnitStoreOperation operation,
    required String serviceFileName,
    required String timerFileName,
    required Object cause,
    required StackTrace causeStackTrace,
    List<LinuxSystemdRollbackFailure> rollbackFailures =
        const <LinuxSystemdRollbackFailure>[],
  }) {
    return LinuxSystemdUserUnitStoreException._(
      operation: operation,
      serviceFileName: serviceFileName,
      timerFileName: timerFileName,
      cause: cause,
      causeStackTrace: causeStackTrace,
      rollbackFailures: List<LinuxSystemdRollbackFailure>.unmodifiable(
        rollbackFailures,
      ),
    );
  }

  const LinuxSystemdUserUnitStoreException._({
    required this.operation,
    required this.serviceFileName,
    required this.timerFileName,
    required this.cause,
    required this.causeStackTrace,
    required this.rollbackFailures,
  });

  final LinuxSystemdUserUnitStoreOperation operation;
  final String serviceFileName;
  final String timerFileName;
  final Object cause;
  final StackTrace causeStackTrace;
  final List<LinuxSystemdRollbackFailure> rollbackFailures;

  @override
  String toString() {
    return 'LinuxSystemdUserUnitStoreException('
        'operation: ${operation.name}, '
        'service: $serviceFileName, '
        'timer: $timerFileName, '
        'cause: $cause, '
        'rollbackFailures: ${rollbackFailures.length}'
        ')';
  }
}
