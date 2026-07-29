import 'linux_bounded_output.dart';

final class LinuxProcessResult {
  LinuxProcessResult({
    required this.executable,
    required List<String> arguments,
    required this.pid,
    required this.exitCode,
    required this.duration,
    required this.stdout,
    required this.stderr,
  }) : arguments = List<String>.unmodifiable(List<String>.of(arguments));

  final String executable;
  final List<String> arguments;
  final int pid;
  final int exitCode;
  final Duration duration;
  final LinuxBoundedOutput stdout;
  final LinuxBoundedOutput stderr;
}
