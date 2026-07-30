/// High-level operation performed by the systemd user-unit store.
enum LinuxSystemdUserUnitStoreOperation {
  install,
  remove,
  beginInstall,
  beginRemove,
  applyInstall,
  finalizeInstall,
  rollbackInstall,
  applyRemove,
  finalizeRemove,
  rollbackRemove,
}

/// Safe category for a retained transaction lifecycle failure.
enum LinuxSystemdUserUnitTransactionFailure { invalidState, filesystemFailure }

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
    LinuxSystemdUserUnitTransactionFailure? transactionFailure,
    required String serviceFileName,
    required String timerFileName,
    required Object cause,
    required StackTrace causeStackTrace,
    List<LinuxSystemdRollbackFailure> rollbackFailures =
        const <LinuxSystemdRollbackFailure>[],
  }) {
    return LinuxSystemdUserUnitStoreException._(
      operation: operation,
      transactionFailure: transactionFailure,
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
    required this.transactionFailure,
    required this.serviceFileName,
    required this.timerFileName,
    required this.cause,
    required this.causeStackTrace,
    required this.rollbackFailures,
  });

  final LinuxSystemdUserUnitStoreOperation operation;
  final LinuxSystemdUserUnitTransactionFailure? transactionFailure;
  final String serviceFileName;
  final String timerFileName;
  final Object cause;
  final StackTrace causeStackTrace;
  final List<LinuxSystemdRollbackFailure> rollbackFailures;

  @override
  String toString() {
    return 'LinuxSystemdUserUnitStoreException('
        'operation: ${operation.name}, '
        'transactionFailure: ${transactionFailure?.name ?? 'none'}, '
        'service: $serviceFileName, '
        'timer: $timerFileName, '
        'rollbackFailures: ${rollbackFailures.length}'
        ')';
  }
}
