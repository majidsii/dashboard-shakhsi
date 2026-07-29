import 'linux_bounded_output.dart';

abstract class LinuxProcessException implements Exception {
  LinuxProcessException({
    required this.executable,
    required List<String> arguments,
    this.pid,
    this.duration,
    this.stdout,
    this.stderr,
    this.cause,
    this.stackTrace,
  }) : arguments = List<String>.unmodifiable(List<String>.of(arguments));

  final String executable;
  final List<String> arguments;
  final int? pid;
  final Duration? duration;
  final LinuxBoundedOutput? stdout;
  final LinuxBoundedOutput? stderr;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final pidDescription = pid == null ? '' : ', pid: $pid';

    return '$runtimeType('
        'executable: $executable, '
        'arguments: $arguments'
        '$pidDescription'
        ')';
  }
}

final class LinuxProcessStartException extends LinuxProcessException {
  LinuxProcessStartException({
    required super.executable,
    required super.arguments,
    required super.cause,
    required super.stackTrace,
  });
}

final class LinuxProcessTimeoutException extends LinuxProcessException {
  LinuxProcessTimeoutException({
    required super.executable,
    required super.arguments,
    required super.pid,
    required super.duration,
    required super.stdout,
    required super.stderr,
    required this.timeout,
    required this.terminationGracePeriod,
    required this.sigtermAttempted,
    required this.sigtermDelivered,
    required this.sigkillAttempted,
    required this.sigkillDelivered,
    super.cause,
    super.stackTrace,
  });

  final Duration timeout;
  final Duration terminationGracePeriod;
  final bool sigtermAttempted;
  final bool sigtermDelivered;
  final bool sigkillAttempted;
  final bool sigkillDelivered;
}

final class LinuxProcessCancellationException extends LinuxProcessException {
  LinuxProcessCancellationException({
    required super.executable,
    required super.arguments,
    super.pid,
    super.duration,
    super.stdout,
    super.stderr,
    this.terminationGracePeriod = Duration.zero,
    this.sigtermAttempted = false,
    this.sigtermDelivered = false,
    this.sigkillAttempted = false,
    this.sigkillDelivered = false,
    super.cause,
    super.stackTrace,
  });

  final Duration terminationGracePeriod;
  final bool sigtermAttempted;
  final bool sigtermDelivered;
  final bool sigkillAttempted;
  final bool sigkillDelivered;
}

enum LinuxProcessStreamKind { stdout, stderr }

final class LinuxProcessStreamException extends LinuxProcessException {
  LinuxProcessStreamException({
    required super.executable,
    required super.arguments,
    required this.stream,
    super.pid,
    super.duration,
    super.stdout,
    super.stderr,
    required super.cause,
    required super.stackTrace,
  });

  final LinuxProcessStreamKind stream;
}

final class LinuxProcessTerminationException extends LinuxProcessException {
  LinuxProcessTerminationException({
    required super.executable,
    required super.arguments,
    required super.pid,
    super.duration,
    super.stdout,
    super.stderr,
    required this.terminationGracePeriod,
    required this.sigtermAttempted,
    required this.sigtermDelivered,
    required this.sigkillAttempted,
    required this.sigkillDelivered,
    required super.cause,
    required super.stackTrace,
  });

  final Duration terminationGracePeriod;
  final bool sigtermAttempted;
  final bool sigtermDelivered;
  final bool sigkillAttempted;
  final bool sigkillDelivered;
}
