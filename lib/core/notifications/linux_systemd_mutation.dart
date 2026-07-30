import 'linux_process_result.dart';
import 'linux_systemd_timer_name.dart';
import 'linux_systemd_timer_status.dart';

enum LinuxSystemdMutationOperation { enableAndStart, disableAndStop }

enum LinuxSystemdMutationFailure {
  commandFailed,
  postconditionFailed,
  ambiguousOutcome,
  reconciliationFailed,
}

final class LinuxSystemdMutationException implements Exception {
  const LinuxSystemdMutationException({
    required this.operation,
    required this.failure,
    required this.timerName,
    required this.statusChecks,
    this.commandResult,
    this.commandError,
    this.commandStackTrace,
    this.observedStatus,
    this.reconciliationError,
    this.reconciliationStackTrace,
  });

  final LinuxSystemdMutationOperation operation;
  final LinuxSystemdMutationFailure failure;
  final LinuxSystemdTimerName timerName;
  final int statusChecks;
  final LinuxProcessResult? commandResult;
  final Object? commandError;
  final StackTrace? commandStackTrace;
  final LinuxSystemdTimerStatus? observedStatus;
  final Object? reconciliationError;
  final StackTrace? reconciliationStackTrace;

  @override
  String toString() {
    return 'LinuxSystemdMutationException('
        'operation=${operation.name}, '
        'failure=${failure.name}, '
        'timer=${timerName.value}, '
        'statusChecks=$statusChecks, '
        'commandExitCode=${commandResult?.exitCode}, '
        'hasCommandError=${commandError != null}, '
        'hasObservedStatus=${observedStatus != null}, '
        'hasReconciliationError=${reconciliationError != null})';
  }
}
