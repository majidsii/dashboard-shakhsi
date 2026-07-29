import 'dart:async';

import 'linux_bounded_output.dart';
import 'linux_cancellation_token.dart';
import 'linux_process_exception.dart';
import 'linux_process_request.dart';
import 'linux_process_result.dart';
import 'linux_process_runner.dart';
import 'linux_process_starter.dart';
import 'linux_started_process.dart';

final class DartIoLinuxProcessRunner implements LinuxProcessRunner {
  DartIoLinuxProcessRunner({LinuxProcessStarter? processStarter})
    : _processStarter = processStarter ?? const DartIoLinuxProcessStarter();

  final LinuxProcessStarter _processStarter;

  @override
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (cancellationToken?.isCancelled ?? false) {
      stopwatch.stop();

      throw LinuxProcessCancellationException(
        executable: request.executable,
        arguments: request.arguments,
        duration: stopwatch.elapsed,
        stdout: _emptyOutput,
        stderr: _emptyOutput,
        terminationGracePeriod: request.terminationGracePeriod,
      );
    }

    late final LinuxStartedProcess process;

    try {
      process = await _processStarter.start(request);
    } on LinuxProcessStartException {
      rethrow;
    } catch (error, stackTrace) {
      stopwatch.stop();

      throw LinuxProcessStartException(
        executable: request.executable,
        arguments: request.arguments,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    final stdoutCollector = LinuxBoundedOutputCollector(
      limitBytes: request.stdoutLimitBytes,
    );
    final stderrCollector = LinuxBoundedOutputCollector(
      limitBytes: request.stderrLimitBytes,
    );

    final stdoutFuture = _captureStream(
      process.stdout,
      stdoutCollector,
      LinuxProcessStreamKind.stdout,
    );
    final stderrFuture = _captureStream(
      process.stderr,
      stderrCollector,
      LinuxProcessStreamKind.stderr,
    );
    final exitOutcomeFuture = _captureExit(process.exitCode);

    final coordinator = _TerminalCoordinator();
    Timer? timeoutTimer;

    unawaited(
      exitOutcomeFuture.then((_) {
        coordinator.tryComplete(_TerminalReason.completed);
      }),
    );

    if (cancellationToken != null) {
      unawaited(
        cancellationToken.whenCancelled.then((_) {
          coordinator.tryComplete(_TerminalReason.cancelled);
        }),
      );
    }

    if (cancellationToken?.isCancelled ?? false) {
      coordinator.tryComplete(_TerminalReason.cancelled);
    }

    if (!coordinator.isCompleted) {
      final remainingTimeout = request.timeout - stopwatch.elapsed;

      if (remainingTimeout.inMicroseconds <= 0) {
        coordinator.tryComplete(_TerminalReason.timedOut);
      } else {
        timeoutTimer = Timer(remainingTimeout, () {
          coordinator.tryComplete(_TerminalReason.timedOut);
        });
      }
    }

    final terminalReason = await coordinator.future;
    timeoutTimer?.cancel();

    if (terminalReason == _TerminalReason.completed) {
      final exitOutcome = await exitOutcomeFuture;
      final captures = await Future.wait<_CapturedLinuxProcessStream>(
        <Future<_CapturedLinuxProcessStream>>[stdoutFuture, stderrFuture],
      );

      stopwatch.stop();

      final stdout = stdoutCollector.finish();
      final stderr = stderrCollector.finish();
      final streamFailure = captures[0].failure ?? captures[1].failure;

      if (exitOutcome.failure != null) {
        throw LinuxProcessTerminationException(
          executable: request.executable,
          arguments: request.arguments,
          pid: process.pid,
          duration: stopwatch.elapsed,
          stdout: stdout,
          stderr: stderr,
          terminationGracePeriod: request.terminationGracePeriod,
          sigtermAttempted: false,
          sigtermDelivered: false,
          sigkillAttempted: false,
          sigkillDelivered: false,
          cause: exitOutcome.failure!.error,
          stackTrace: exitOutcome.failure!.stackTrace,
        );
      }

      if (streamFailure != null) {
        throw LinuxProcessStreamException(
          executable: request.executable,
          arguments: request.arguments,
          pid: process.pid,
          duration: stopwatch.elapsed,
          stdout: stdout,
          stderr: stderr,
          stream: streamFailure.stream,
          cause: streamFailure.error,
          stackTrace: streamFailure.stackTrace,
        );
      }

      return LinuxProcessResult(
        executable: request.executable,
        arguments: request.arguments,
        pid: process.pid,
        exitCode: exitOutcome.exitCode!,
        duration: stopwatch.elapsed,
        stdout: stdout,
        stderr: stderr,
      );
    }

    final termination = await _terminate(
      process,
      exitOutcomeFuture,
      request.terminationGracePeriod,
    );

    final captures = await Future.wait<_CapturedLinuxProcessStream>(
      <Future<_CapturedLinuxProcessStream>>[stdoutFuture, stderrFuture],
    );
    final exitOutcome = await exitOutcomeFuture;

    stopwatch.stop();

    final stdout = stdoutCollector.finish();
    final stderr = stderrCollector.finish();
    final streamFailure = captures[0].failure ?? captures[1].failure;
    final terminalCause =
        termination.failure ?? exitOutcome.failure ?? streamFailure;

    if (termination.failure != null || exitOutcome.failure != null) {
      throw LinuxProcessTerminationException(
        executable: request.executable,
        arguments: request.arguments,
        pid: process.pid,
        duration: stopwatch.elapsed,
        stdout: stdout,
        stderr: stderr,
        terminationGracePeriod: request.terminationGracePeriod,
        sigtermAttempted: termination.sigtermAttempted,
        sigtermDelivered: termination.sigtermDelivered,
        sigkillAttempted: termination.sigkillAttempted,
        sigkillDelivered: termination.sigkillDelivered,
        cause: terminalCause!.error,
        stackTrace: terminalCause.stackTrace,
      );
    }

    if (terminalReason == _TerminalReason.timedOut) {
      throw LinuxProcessTimeoutException(
        executable: request.executable,
        arguments: request.arguments,
        pid: process.pid,
        duration: stopwatch.elapsed,
        stdout: stdout,
        stderr: stderr,
        timeout: request.timeout,
        terminationGracePeriod: request.terminationGracePeriod,
        sigtermAttempted: termination.sigtermAttempted,
        sigtermDelivered: termination.sigtermDelivered,
        sigkillAttempted: termination.sigkillAttempted,
        sigkillDelivered: termination.sigkillDelivered,
        cause: streamFailure?.error,
        stackTrace: streamFailure?.stackTrace,
      );
    }

    throw LinuxProcessCancellationException(
      executable: request.executable,
      arguments: request.arguments,
      pid: process.pid,
      duration: stopwatch.elapsed,
      stdout: stdout,
      stderr: stderr,
      terminationGracePeriod: request.terminationGracePeriod,
      sigtermAttempted: termination.sigtermAttempted,
      sigtermDelivered: termination.sigtermDelivered,
      sigkillAttempted: termination.sigkillAttempted,
      sigkillDelivered: termination.sigkillDelivered,
      cause: streamFailure?.error,
      stackTrace: streamFailure?.stackTrace,
    );
  }

  static Future<_TerminationOutcome> _terminate(
    LinuxStartedProcess process,
    Future<_ExitOutcome> exitOutcomeFuture,
    Duration gracePeriod,
  ) async {
    final sigterm = _sendSignal(process, LinuxProcessSignal.sigterm);

    final exitedDuringGrace = await Future.any<bool>(<Future<bool>>[
      exitOutcomeFuture.then((_) => true),
      Future<void>.delayed(gracePeriod).then((_) => false),
    ]);

    var sigkill = const _SignalOutcome.notAttempted();

    if (!exitedDuringGrace) {
      sigkill = _sendSignal(process, LinuxProcessSignal.sigkill);
    }

    await exitOutcomeFuture;

    return _TerminationOutcome(
      sigtermAttempted: sigterm.attempted,
      sigtermDelivered: sigterm.delivered,
      sigkillAttempted: sigkill.attempted,
      sigkillDelivered: sigkill.delivered,
      failure: sigterm.failure ?? sigkill.failure,
    );
  }

  static _SignalOutcome _sendSignal(
    LinuxStartedProcess process,
    LinuxProcessSignal signal,
  ) {
    try {
      return _SignalOutcome(attempted: true, delivered: process.kill(signal));
    } catch (error, stackTrace) {
      return _SignalOutcome(
        attempted: true,
        delivered: false,
        failure: _LinuxProcessFailure(error: error, stackTrace: stackTrace),
      );
    }
  }

  static Future<_ExitOutcome> _captureExit(Future<int> exitCode) async {
    try {
      return _ExitOutcome(exitCode: await exitCode);
    } catch (error, stackTrace) {
      return _ExitOutcome(
        failure: _LinuxProcessFailure(error: error, stackTrace: stackTrace),
      );
    }
  }

  static Future<_CapturedLinuxProcessStream> _captureStream(
    Stream<List<int>> stream,
    LinuxBoundedOutputCollector collector,
    LinuxProcessStreamKind streamKind,
  ) {
    final completer = Completer<_CapturedLinuxProcessStream>.sync();
    _LinuxProcessStreamFailure? failure;

    stream.listen(
      collector.add,
      onError: (Object error, StackTrace stackTrace) {
        failure ??= _LinuxProcessStreamFailure(
          error: error,
          stackTrace: stackTrace,
          stream: streamKind,
        );
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(_CapturedLinuxProcessStream(failure: failure));
        }
      },
      cancelOnError: false,
    );

    return completer.future;
  }
}

enum _TerminalReason { completed, timedOut, cancelled }

final class _TerminalCoordinator {
  final Completer<_TerminalReason> _completer =
      Completer<_TerminalReason>.sync();

  bool get isCompleted => _completer.isCompleted;

  Future<_TerminalReason> get future => _completer.future;

  bool tryComplete(_TerminalReason reason) {
    if (_completer.isCompleted) {
      return false;
    }

    _completer.complete(reason);
    return true;
  }
}

final class _ExitOutcome {
  const _ExitOutcome({this.exitCode, this.failure})
    : assert((exitCode == null) != (failure == null));

  final int? exitCode;
  final _LinuxProcessFailure? failure;
}

final class _TerminationOutcome {
  const _TerminationOutcome({
    required this.sigtermAttempted,
    required this.sigtermDelivered,
    required this.sigkillAttempted,
    required this.sigkillDelivered,
    required this.failure,
  });

  final bool sigtermAttempted;
  final bool sigtermDelivered;
  final bool sigkillAttempted;
  final bool sigkillDelivered;
  final _LinuxProcessFailure? failure;
}

final class _SignalOutcome {
  const _SignalOutcome({
    required this.attempted,
    required this.delivered,
    this.failure,
  });

  const _SignalOutcome.notAttempted()
    : attempted = false,
      delivered = false,
      failure = null;

  final bool attempted;
  final bool delivered;
  final _LinuxProcessFailure? failure;
}

final class _CapturedLinuxProcessStream {
  const _CapturedLinuxProcessStream({required this.failure});

  final _LinuxProcessStreamFailure? failure;
}

class _LinuxProcessFailure {
  const _LinuxProcessFailure({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;
}

final class _LinuxProcessStreamFailure extends _LinuxProcessFailure {
  const _LinuxProcessStreamFailure({
    required super.error,
    required super.stackTrace,
    required this.stream,
  });

  final LinuxProcessStreamKind stream;
}

const LinuxBoundedOutput _emptyOutput = LinuxBoundedOutput(
  text: '',
  totalBytes: 0,
  retainedBytes: 0,
  droppedBytes: 0,
  truncated: false,
  malformedUtf8: false,
);
