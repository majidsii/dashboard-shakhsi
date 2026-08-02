enum LinuxNotificationDeliveryExitKind {
  normalApplication,
  delivered,
  missingRequest,
  invalidArguments,
  initializationFailed,
  lookupFailed,
  displayFailed,
}

final class LinuxNotificationDeliveryCloseFailure {
  const LinuxNotificationDeliveryCloseFailure({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() {
    return 'LinuxNotificationDeliveryCloseFailure('
        'errorType=${error.runtimeType})';
  }
}

final class LinuxNotificationDeliveryResult {
  factory LinuxNotificationDeliveryResult({
    required LinuxNotificationDeliveryExitKind kind,
    required int exitCode,
    Object? cause,
    StackTrace? causeStackTrace,
    Iterable<LinuxNotificationDeliveryCloseFailure> closeFailures =
        const <LinuxNotificationDeliveryCloseFailure>[],
  }) {
    return LinuxNotificationDeliveryResult._(
      kind: kind,
      exitCode: exitCode,
      cause: cause,
      causeStackTrace: causeStackTrace,
      closeFailures: List<LinuxNotificationDeliveryCloseFailure>.unmodifiable(
        closeFailures,
      ),
    );
  }

  const LinuxNotificationDeliveryResult._({
    required this.kind,
    required this.exitCode,
    required this.cause,
    required this.causeStackTrace,
    required this.closeFailures,
  });

  factory LinuxNotificationDeliveryResult.normalApplication({
    Iterable<LinuxNotificationDeliveryCloseFailure> closeFailures =
        const <LinuxNotificationDeliveryCloseFailure>[],
  }) {
    return LinuxNotificationDeliveryResult(
      kind: LinuxNotificationDeliveryExitKind.normalApplication,
      exitCode: 0,
      closeFailures: closeFailures,
    );
  }

  factory LinuxNotificationDeliveryResult.delivered({
    Iterable<LinuxNotificationDeliveryCloseFailure> closeFailures =
        const <LinuxNotificationDeliveryCloseFailure>[],
  }) {
    return LinuxNotificationDeliveryResult(
      kind: LinuxNotificationDeliveryExitKind.delivered,
      exitCode: 0,
      closeFailures: closeFailures,
    );
  }

  factory LinuxNotificationDeliveryResult.missingRequest({
    Iterable<LinuxNotificationDeliveryCloseFailure> closeFailures =
        const <LinuxNotificationDeliveryCloseFailure>[],
  }) {
    return LinuxNotificationDeliveryResult(
      kind: LinuxNotificationDeliveryExitKind.missingRequest,
      exitCode: 0,
      closeFailures: closeFailures,
    );
  }

  factory LinuxNotificationDeliveryResult.invalidArguments(
    Object cause,
    StackTrace causeStackTrace, {
    Iterable<LinuxNotificationDeliveryCloseFailure> closeFailures =
        const <LinuxNotificationDeliveryCloseFailure>[],
  }) {
    return LinuxNotificationDeliveryResult(
      kind: LinuxNotificationDeliveryExitKind.invalidArguments,
      exitCode: 64,
      cause: cause,
      causeStackTrace: causeStackTrace,
      closeFailures: closeFailures,
    );
  }

  factory LinuxNotificationDeliveryResult.initializationFailed(
    Object cause,
    StackTrace causeStackTrace, {
    Iterable<LinuxNotificationDeliveryCloseFailure> closeFailures =
        const <LinuxNotificationDeliveryCloseFailure>[],
  }) {
    return LinuxNotificationDeliveryResult(
      kind: LinuxNotificationDeliveryExitKind.initializationFailed,
      exitCode: 70,
      cause: cause,
      causeStackTrace: causeStackTrace,
      closeFailures: closeFailures,
    );
  }

  factory LinuxNotificationDeliveryResult.lookupFailed(
    Object cause,
    StackTrace causeStackTrace, {
    Iterable<LinuxNotificationDeliveryCloseFailure> closeFailures =
        const <LinuxNotificationDeliveryCloseFailure>[],
  }) {
    return LinuxNotificationDeliveryResult(
      kind: LinuxNotificationDeliveryExitKind.lookupFailed,
      exitCode: 74,
      cause: cause,
      causeStackTrace: causeStackTrace,
      closeFailures: closeFailures,
    );
  }

  factory LinuxNotificationDeliveryResult.displayFailed(
    Object cause,
    StackTrace causeStackTrace, {
    Iterable<LinuxNotificationDeliveryCloseFailure> closeFailures =
        const <LinuxNotificationDeliveryCloseFailure>[],
  }) {
    return LinuxNotificationDeliveryResult(
      kind: LinuxNotificationDeliveryExitKind.displayFailed,
      exitCode: 1,
      cause: cause,
      causeStackTrace: causeStackTrace,
      closeFailures: closeFailures,
    );
  }

  final LinuxNotificationDeliveryExitKind kind;
  final int exitCode;
  final Object? cause;
  final StackTrace? causeStackTrace;
  final List<LinuxNotificationDeliveryCloseFailure> closeFailures;

  LinuxNotificationDeliveryResult withCloseFailures(
    Iterable<LinuxNotificationDeliveryCloseFailure> additionalFailures,
  ) {
    return LinuxNotificationDeliveryResult(
      kind: kind,
      exitCode: exitCode,
      cause: cause,
      causeStackTrace: causeStackTrace,
      closeFailures: <LinuxNotificationDeliveryCloseFailure>[
        ...closeFailures,
        ...additionalFailures,
      ],
    );
  }

  @override
  String toString() {
    return 'LinuxNotificationDeliveryResult('
        'kind=${kind.name}, '
        'exitCode=$exitCode, '
        'causeType=${cause?.runtimeType ?? 'none'}, '
        'closeFailures=${closeFailures.length}'
        ')';
  }
}
