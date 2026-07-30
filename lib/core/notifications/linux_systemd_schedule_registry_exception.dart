enum LinuxSystemdScheduleRegistryOperation {
  validate,
  decode,
  load,
  replace,
  quarantine,
  discover,
}

enum LinuxSystemdScheduleRegistryFailure {
  unsupportedSchemaVersion,
  malformedJson,
  malformedUtf8,
  oversizedRegistry,
  excessiveEntryCount,
  invalidGeneration,
  invalidGenerationTransition,
  duplicateScheduleId,
  duplicateTimerName,
  duplicateServiceName,
  invalidScheduleId,
  invalidOwner,
  invalidTimestamp,
  invalidFingerprint,
  invalidUnitIdentity,
  unsafeRegistryPath,
  insecureRegistryMode,
  unsafeAppUnitPath,
  atomicReplacementFailed,
  quarantineFailed,
  discoveryFailed,
}

final class LinuxSystemdRegistryRollbackFailure {
  const LinuxSystemdRegistryRollbackFailure({
    required this.step,
    required this.error,
    required this.stackTrace,
  });

  final String step;
  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() {
    return 'LinuxSystemdRegistryRollbackFailure(step=$step)';
  }
}

final class LinuxSystemdScheduleRegistryException implements Exception {
  factory LinuxSystemdScheduleRegistryException({
    required LinuxSystemdScheduleRegistryOperation operation,
    required LinuxSystemdScheduleRegistryFailure failure,
    String? path,
    String? field,
    Object? cause,
    StackTrace? causeStackTrace,
    List<LinuxSystemdRegistryRollbackFailure> rollbackFailures =
        const <LinuxSystemdRegistryRollbackFailure>[],
  }) {
    return LinuxSystemdScheduleRegistryException._(
      operation: operation,
      failure: failure,
      path: path,
      field: field,
      cause: cause,
      causeStackTrace: causeStackTrace,
      rollbackFailures: List<LinuxSystemdRegistryRollbackFailure>.unmodifiable(
        rollbackFailures,
      ),
    );
  }

  const LinuxSystemdScheduleRegistryException._({
    required this.operation,
    required this.failure,
    required this.path,
    required this.field,
    required this.cause,
    required this.causeStackTrace,
    required this.rollbackFailures,
  });

  final LinuxSystemdScheduleRegistryOperation operation;
  final LinuxSystemdScheduleRegistryFailure failure;
  final String? path;
  final String? field;
  final Object? cause;
  final StackTrace? causeStackTrace;
  final List<LinuxSystemdRegistryRollbackFailure> rollbackFailures;

  @override
  String toString() {
    final details = <String>[
      'operation=${operation.name}',
      'failure=${failure.name}',
      if (path != null) 'path=$path',
      if (field != null) 'field=$field',
      'rollbackFailures=${rollbackFailures.length}',
    ];

    return 'LinuxSystemdScheduleRegistryException('
        '${details.join(', ')})';
  }
}
