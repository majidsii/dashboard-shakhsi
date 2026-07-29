import 'linux_cancellation_token.dart';
import 'linux_process_request.dart';
import 'linux_process_result.dart';
import 'linux_process_runner.dart';
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
    this.executable = 'systemctl',
    this.timeout = const Duration(seconds: 15),
    this.terminationGracePeriod = const Duration(seconds: 2),
    this.stdoutLimitBytes = LinuxProcessRequest.defaultOutputLimitBytes,
    this.stderrLimitBytes = LinuxProcessRequest.defaultOutputLimitBytes,
    this.includeParentEnvironment = true,
  }) : _processRunner = processRunner,
       _statusParser = statusParser;

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

  final String executable;
  final Duration timeout;
  final Duration terminationGracePeriod;
  final int stdoutLimitBytes;
  final int stderrLimitBytes;
  final bool includeParentEnvironment;

  Future<void> reloadDaemon({LinuxCancellationToken? cancellationToken}) async {
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

  Future<LinuxSystemdTimerStatus> status(
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
