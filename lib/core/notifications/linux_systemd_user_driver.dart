// ignore_for_file: prefer_initializing_formals
// Public named constructor parameters are intentionally preserved.

import 'async_fifo_keyed_mutex.dart';
import 'async_writer_preferring_rw_lock.dart';
import 'linux_cancellation_token.dart';
import 'linux_process_exception.dart';
import 'linux_process_request.dart';
import 'linux_process_result.dart';
import 'linux_process_runner.dart';
import 'linux_systemd_mutation.dart';
import 'linux_systemd_timer_name.dart';
import 'linux_systemd_timer_status.dart';
import 'linux_systemd_timer_status_parser.dart';

enum LinuxSystemdCommandOperation { daemonReload, status }

final class LinuxSystemdCommandException implements Exception {
  const LinuxSystemdCommandException({
    required this.operation,
    required this.result,
    this.timerName,
  });

  final LinuxSystemdCommandOperation operation;
  final LinuxProcessResult result;
  final LinuxSystemdTimerName? timerName;

  @override
  String toString() {
    final timer = timerName == null ? '' : ', timer=${timerName!.value}';

    return 'LinuxSystemdCommandException('
        'operation=${operation.name}$timer, '
        'exitCode=${result.exitCode}, '
        'command=${result.executable} '
        '${result.arguments.join(' ')})';
  }
}

enum LinuxSystemdStatusOutputFailure { truncated, malformedUtf8 }

final class LinuxSystemdStatusOutputException implements Exception {
  const LinuxSystemdStatusOutputException({
    required this.failure,
    required this.timerName,
    required this.result,
  });

  final LinuxSystemdStatusOutputFailure failure;
  final LinuxSystemdTimerName timerName;
  final LinuxProcessResult result;

  @override
  String toString() {
    return 'LinuxSystemdStatusOutputException('
        'failure=${failure.name}, '
        'timer=${timerName.value}, '
        'exitCode=${result.exitCode})';
  }
}

final class LinuxSystemdUserDriver {
  LinuxSystemdUserDriver({
    required LinuxProcessRunner processRunner,
    LinuxSystemdTimerStatusParser statusParser =
        const LinuxSystemdTimerStatusParser(),
    AsyncWriterPreferringRwLock? globalLock,
    AsyncFifoKeyedMutex<String>? unitMutex,
    this.executable = 'systemctl',
    this.timeout = const Duration(seconds: 15),
    this.terminationGracePeriod = const Duration(seconds: 2),
    this.stdoutLimitBytes = LinuxProcessRequest.defaultOutputLimitBytes,
    this.stderrLimitBytes = LinuxProcessRequest.defaultOutputLimitBytes,
    this.includeParentEnvironment = true,
  }) : _processRunner = processRunner,
       _statusParser = statusParser,
       _globalLock = globalLock ?? AsyncWriterPreferringRwLock(),
       _unitMutex = unitMutex ?? AsyncFifoKeyedMutex<String>();

  static const Map<String, String> hardenedEnvironment = <String, String>{
    'LC_ALL': 'C',
    'LANG': 'C',
    'SYSTEMD_COLORS': '0',
    'SYSTEMD_PAGER': 'cat',
    'SYSTEMD_PAGERSECURE': '1',
  };

  static const String _statusProperties =
      'Id,LoadState,ActiveState,SubState,UnitFileState,Result';

  final LinuxProcessRunner _processRunner;
  final LinuxSystemdTimerStatusParser _statusParser;
  final AsyncWriterPreferringRwLock _globalLock;
  final AsyncFifoKeyedMutex<String> _unitMutex;

  final String executable;
  final Duration timeout;
  final Duration terminationGracePeriod;
  final int stdoutLimitBytes;
  final int stderrLimitBytes;
  final bool includeParentEnvironment;

  Future<void> reloadDaemon({LinuxCancellationToken? cancellationToken}) {
    return _globalLock.runWrite(
      () => _reloadDaemonUnlocked(cancellationToken: cancellationToken),
    );
  }

  Future<LinuxSystemdTimerStatus> status(
    LinuxSystemdTimerName timerName, {
    LinuxCancellationToken? cancellationToken,
  }) {
    return _globalLock.runRead(
      () => _unitMutex.synchronized(
        timerName.value,
        () => _statusUnlocked(timerName, cancellationToken: cancellationToken),
      ),
    );
  }

  Future<LinuxSystemdTimerStatus> enableAndStart(
    LinuxSystemdTimerName timerName, {
    LinuxCancellationToken? cancellationToken,
  }) {
    return _runUnitMutation(
      LinuxSystemdMutationOperation.enableAndStart,
      timerName,
      cancellationToken: cancellationToken,
    );
  }

  Future<LinuxSystemdTimerStatus> disableAndStop(
    LinuxSystemdTimerName timerName, {
    LinuxCancellationToken? cancellationToken,
  }) {
    return _runUnitMutation(
      LinuxSystemdMutationOperation.disableAndStop,
      timerName,
      cancellationToken: cancellationToken,
    );
  }

  Future<void> _reloadDaemonUnlocked({
    LinuxCancellationToken? cancellationToken,
  }) async {
    final result = await _processRunner.run(
      _request(const <String>['--user', '--no-pager', 'daemon-reload']),
      cancellationToken: cancellationToken,
    );

    if (result.exitCode != 0) {
      throw LinuxSystemdCommandException(
        operation: LinuxSystemdCommandOperation.daemonReload,
        result: result,
      );
    }
  }

  Future<LinuxSystemdTimerStatus> _statusUnlocked(
    LinuxSystemdTimerName timerName, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    final result = await _processRunner.run(
      _request(<String>[
        '--user',
        '--no-pager',
        'show',
        timerName.value,
        '--property=$_statusProperties',
      ]),
      cancellationToken: cancellationToken,
    );

    if (result.exitCode != 0) {
      throw LinuxSystemdCommandException(
        operation: LinuxSystemdCommandOperation.status,
        timerName: timerName,
        result: result,
      );
    }

    if (result.stdout.truncated) {
      throw LinuxSystemdStatusOutputException(
        failure: LinuxSystemdStatusOutputFailure.truncated,
        timerName: timerName,
        result: result,
      );
    }

    if (result.stdout.malformedUtf8) {
      throw LinuxSystemdStatusOutputException(
        failure: LinuxSystemdStatusOutputFailure.malformedUtf8,
        timerName: timerName,
        result: result,
      );
    }

    return _statusParser.parse(
      expectedName: timerName,
      output: result.stdout.text,
    );
  }

  Future<LinuxSystemdTimerStatus> _runUnitMutation(
    LinuxSystemdMutationOperation operation,
    LinuxSystemdTimerName timerName, {
    LinuxCancellationToken? cancellationToken,
  }) {
    return _globalLock.runRead(
      () => _unitMutex.synchronized(
        timerName.value,
        () => _mutateUnlocked(
          operation,
          timerName,
          cancellationToken: cancellationToken,
        ),
      ),
    );
  }

  Future<LinuxSystemdTimerStatus> _mutateUnlocked(
    LinuxSystemdMutationOperation operation,
    LinuxSystemdTimerName timerName, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    final arguments = _mutationArguments(operation, timerName);

    late final LinuxProcessResult commandResult;

    try {
      commandResult = await _processRunner.run(
        _request(arguments),
        cancellationToken: cancellationToken,
      );
    } on LinuxProcessCancellationException {
      rethrow;
    } on LinuxProcessStartException {
      rethrow;
    } catch (error, stackTrace) {
      if (!_isAmbiguousCommandFailure(error)) {
        rethrow;
      }

      return _reconcileAmbiguousCommand(
        operation,
        timerName,
        commandError: error,
        commandStackTrace: stackTrace,
        cancellationToken: cancellationToken,
      );
    }

    if (commandResult.exitCode != 0) {
      throw LinuxSystemdMutationException(
        operation: operation,
        failure: LinuxSystemdMutationFailure.commandFailed,
        timerName: timerName,
        commandResult: commandResult,
        statusChecks: 0,
      );
    }

    return _verifySuccessfulCommand(
      operation,
      timerName,
      commandResult: commandResult,
      cancellationToken: cancellationToken,
    );
  }

  Future<LinuxSystemdTimerStatus> _verifySuccessfulCommand(
    LinuxSystemdMutationOperation operation,
    LinuxSystemdTimerName timerName, {
    required LinuxProcessResult commandResult,
    LinuxCancellationToken? cancellationToken,
  }) async {
    final first = await _observeStatus(
      timerName,
      cancellationToken: cancellationToken,
    );

    if (first.status != null &&
        _matchesPostcondition(operation, first.status!)) {
      return first.status!;
    }

    final second = await _observeStatus(
      timerName,
      cancellationToken: cancellationToken,
    );

    if (second.status != null &&
        _matchesPostcondition(operation, second.status!)) {
      return second.status!;
    }

    if (second.error != null) {
      throw LinuxSystemdMutationException(
        operation: operation,
        failure: LinuxSystemdMutationFailure.reconciliationFailed,
        timerName: timerName,
        commandResult: commandResult,
        statusChecks: 2,
        observedStatus: first.status,
        reconciliationError: second.error,
        reconciliationStackTrace: second.stackTrace,
      );
    }

    throw LinuxSystemdMutationException(
      operation: operation,
      failure: LinuxSystemdMutationFailure.postconditionFailed,
      timerName: timerName,
      commandResult: commandResult,
      statusChecks: 2,
      observedStatus: second.status ?? first.status,
      reconciliationError: first.error,
      reconciliationStackTrace: first.stackTrace,
    );
  }

  Future<LinuxSystemdTimerStatus> _reconcileAmbiguousCommand(
    LinuxSystemdMutationOperation operation,
    LinuxSystemdTimerName timerName, {
    required Object commandError,
    required StackTrace commandStackTrace,
    LinuxCancellationToken? cancellationToken,
  }) async {
    final observation = await _observeStatus(
      timerName,
      cancellationToken: cancellationToken,
    );

    if (observation.status != null &&
        _matchesPostcondition(operation, observation.status!)) {
      return observation.status!;
    }

    if (observation.error != null) {
      throw LinuxSystemdMutationException(
        operation: operation,
        failure: LinuxSystemdMutationFailure.reconciliationFailed,
        timerName: timerName,
        commandError: commandError,
        commandStackTrace: commandStackTrace,
        statusChecks: 1,
        reconciliationError: observation.error,
        reconciliationStackTrace: observation.stackTrace,
      );
    }

    throw LinuxSystemdMutationException(
      operation: operation,
      failure: LinuxSystemdMutationFailure.ambiguousOutcome,
      timerName: timerName,
      commandError: commandError,
      commandStackTrace: commandStackTrace,
      statusChecks: 1,
      observedStatus: observation.status,
    );
  }

  Future<_StatusObservation> _observeStatus(
    LinuxSystemdTimerName timerName, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    try {
      return _StatusObservation.status(
        await _statusUnlocked(timerName, cancellationToken: cancellationToken),
      );
    } on LinuxProcessCancellationException {
      rethrow;
    } catch (error, stackTrace) {
      return _StatusObservation.failure(error, stackTrace);
    }
  }

  List<String> _mutationArguments(
    LinuxSystemdMutationOperation operation,
    LinuxSystemdTimerName timerName,
  ) {
    return <String>[
      '--user',
      '--no-pager',
      switch (operation) {
        LinuxSystemdMutationOperation.enableAndStart => 'enable',
        LinuxSystemdMutationOperation.disableAndStop => 'disable',
      },
      '--now',
      timerName.value,
    ];
  }

  bool _matchesPostcondition(
    LinuxSystemdMutationOperation operation,
    LinuxSystemdTimerStatus status,
  ) {
    return switch (operation) {
      LinuxSystemdMutationOperation.enableAndStart =>
        status.isInstalled && status.isEnabled && status.isActive,
      LinuxSystemdMutationOperation.disableAndStop =>
        status.isInstalled && !status.isEnabled && !status.isActive,
    };
  }

  bool _isAmbiguousCommandFailure(Object error) {
    return error is LinuxProcessTimeoutException ||
        error is LinuxProcessTerminationException ||
        error is LinuxProcessStreamException;
  }

  LinuxProcessRequest _request(List<String> arguments) {
    return LinuxProcessRequest(
      executable: executable,
      arguments: arguments,
      environment: hardenedEnvironment,
      timeout: timeout,
      terminationGracePeriod: terminationGracePeriod,
      stdoutLimitBytes: stdoutLimitBytes,
      stderrLimitBytes: stderrLimitBytes,
      includeParentEnvironment: includeParentEnvironment,
    );
  }
}

final class _StatusObservation {
  const _StatusObservation._({this.status, this.error, this.stackTrace})
    : assert(status != null || error != null);

  const _StatusObservation.status(LinuxSystemdTimerStatus value)
    : this._(status: value);

  const _StatusObservation.failure(Object error, StackTrace stackTrace)
    : this._(error: error, stackTrace: stackTrace);

  final LinuxSystemdTimerStatus? status;
  final Object? error;
  final StackTrace? stackTrace;
}
