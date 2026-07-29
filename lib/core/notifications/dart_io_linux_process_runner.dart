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
    final exitCodeFuture = process.exitCode;

    final captures = await Future.wait<_CapturedLinuxProcessStream>(
      <Future<_CapturedLinuxProcessStream>>[stdoutFuture, stderrFuture],
    );
    final exitCode = await exitCodeFuture;

    stopwatch.stop();

    final stdout = stdoutCollector.finish();
    final stderr = stderrCollector.finish();

    final streamFailure = captures[0].failure ?? captures[1].failure;
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
      exitCode: exitCode,
      duration: stopwatch.elapsed,
      stdout: stdout,
      stderr: stderr,
    );
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

final class _CapturedLinuxProcessStream {
  const _CapturedLinuxProcessStream({required this.failure});

  final _LinuxProcessStreamFailure? failure;
}

final class _LinuxProcessStreamFailure {
  const _LinuxProcessStreamFailure({
    required this.error,
    required this.stackTrace,
    required this.stream,
  });

  final Object error;
  final StackTrace stackTrace;
  final LinuxProcessStreamKind stream;
}
