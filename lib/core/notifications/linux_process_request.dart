final class LinuxProcessRequest {
  factory LinuxProcessRequest({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    Duration timeout = const Duration(seconds: 15),
    Duration terminationGracePeriod = const Duration(seconds: 2),
    int stdoutLimitBytes = 256 * 1024,
    int stderrLimitBytes = 256 * 1024,
    bool includeParentEnvironment = true,
  }) {
    final validatedExecutable = _validateExecutable(executable);
    final validatedArguments = _snapshotArguments(arguments);
    final validatedEnvironment = _snapshotEnvironment(environment);

    if (timeout.inMicroseconds <= 0) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'must be greater than zero',
      );
    }

    if (terminationGracePeriod.isNegative) {
      throw ArgumentError.value(
        terminationGracePeriod,
        'terminationGracePeriod',
        'must not be negative',
      );
    }

    if (stdoutLimitBytes < minimumOutputLimitBytes) {
      throw ArgumentError.value(
        stdoutLimitBytes,
        'stdoutLimitBytes',
        'must be at least $minimumOutputLimitBytes bytes',
      );
    }

    if (stderrLimitBytes < minimumOutputLimitBytes) {
      throw ArgumentError.value(
        stderrLimitBytes,
        'stderrLimitBytes',
        'must be at least $minimumOutputLimitBytes bytes',
      );
    }

    return LinuxProcessRequest._(
      executable: validatedExecutable,
      arguments: validatedArguments,
      environment: validatedEnvironment,
      timeout: timeout,
      terminationGracePeriod: terminationGracePeriod,
      stdoutLimitBytes: stdoutLimitBytes,
      stderrLimitBytes: stderrLimitBytes,
      includeParentEnvironment: includeParentEnvironment,
    );
  }

  const LinuxProcessRequest._({
    required this.executable,
    required this.arguments,
    required this.environment,
    required this.timeout,
    required this.terminationGracePeriod,
    required this.stdoutLimitBytes,
    required this.stderrLimitBytes,
    required this.includeParentEnvironment,
  });

  static const int minimumOutputLimitBytes = 2 * 1024;
  static const int defaultOutputLimitBytes = 256 * 1024;

  static final RegExp _executablePattern = RegExp(r'^[A-Za-z0-9_./+-]+$');

  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final Duration timeout;
  final Duration terminationGracePeriod;
  final int stdoutLimitBytes;
  final int stderrLimitBytes;
  final bool includeParentEnvironment;

  static String _validateExecutable(String value) {
    if (value.isEmpty ||
        value.trim() != value ||
        value.contains('\u0000') ||
        !_executablePattern.hasMatch(value) ||
        value == '.' ||
        value == '..' ||
        value == '/') {
      throw ArgumentError.value(
        value,
        'executable',
        'must be one safe executable name or path',
      );
    }

    return value;
  }

  static List<String> _snapshotArguments(List<String> values) {
    final snapshot = List<String>.of(values);

    for (var index = 0; index < snapshot.length; index++) {
      if (snapshot[index].contains('\u0000')) {
        throw ArgumentError.value(
          snapshot[index],
          'arguments[$index]',
          'must not contain NUL',
        );
      }
    }

    return List<String>.unmodifiable(snapshot);
  }

  static Map<String, String> _snapshotEnvironment(Map<String, String> values) {
    final snapshot = Map<String, String>.of(values);

    for (final entry in snapshot.entries) {
      if (entry.key.isEmpty ||
          entry.key.contains('=') ||
          entry.key.contains('\u0000')) {
        throw ArgumentError.value(
          entry.key,
          'environment key',
          'must be non-empty and contain neither "=" nor NUL',
        );
      }

      if (entry.value.contains('\u0000')) {
        throw ArgumentError.value(
          entry.value,
          'environment[${entry.key}]',
          'must not contain NUL',
        );
      }
    }

    return Map<String, String>.unmodifiable(snapshot);
  }
}
