// Public named constructor parameters intentionally initialize private dependencies.
// ignore_for_file: prefer_initializing_formals

enum LinuxExecutablePathFailure {
  resolutionFailed,
  invalidPath,
  verificationFailed,
  notFound,
  notRegularFile,
  notExecutable,
}

final class LinuxExecutablePathException implements Exception {
  const LinuxExecutablePathException({
    required this.failure,
    this.cause,
    this.causeStackTrace,
  });

  final LinuxExecutablePathFailure failure;
  final Object? cause;
  final StackTrace? causeStackTrace;

  @override
  String toString() {
    return 'LinuxExecutablePathException('
        'failure=${failure.name}, '
        'causeType=${cause?.runtimeType ?? 'none'}'
        ')';
  }
}

abstract interface class LinuxExecutablePathSource {
  Future<String> resolve();
}

abstract interface class LinuxExecutableFileVerifier {
  Future<LinuxExecutableFileStatus> status(String path);
}

final class LinuxExecutableFileStatus {
  const LinuxExecutableFileStatus({
    required this.exists,
    required this.isRegularFile,
    required this.isExecutable,
  });

  final bool exists;
  final bool isRegularFile;
  final bool isExecutable;
}

final class ValidatedLinuxExecutablePathSource
    implements LinuxExecutablePathSource {
  const ValidatedLinuxExecutablePathSource({
    required LinuxExecutablePathSource source,
    LinuxExecutableFileVerifier? verifier,
  }) : _source = source,
       _verifier = verifier;

  final LinuxExecutablePathSource _source;
  final LinuxExecutableFileVerifier? _verifier;

  @override
  Future<String> resolve() async {
    final String path;
    try {
      path = await _source.resolve();
    } on LinuxExecutablePathException {
      rethrow;
    } catch (error, stackTrace) {
      throw LinuxExecutablePathException(
        failure: LinuxExecutablePathFailure.resolutionFailed,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }

    if (!_isValidAbsolutePath(path)) {
      throw const LinuxExecutablePathException(
        failure: LinuxExecutablePathFailure.invalidPath,
      );
    }

    final verifier = _verifier;
    if (verifier == null) {
      return path;
    }

    final LinuxExecutableFileStatus fileStatus;
    try {
      fileStatus = await verifier.status(path);
    } on LinuxExecutablePathException {
      rethrow;
    } catch (error, stackTrace) {
      throw LinuxExecutablePathException(
        failure: LinuxExecutablePathFailure.verificationFailed,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }

    if (!fileStatus.exists) {
      throw const LinuxExecutablePathException(
        failure: LinuxExecutablePathFailure.notFound,
      );
    }
    if (!fileStatus.isRegularFile) {
      throw const LinuxExecutablePathException(
        failure: LinuxExecutablePathFailure.notRegularFile,
      );
    }
    if (!fileStatus.isExecutable) {
      throw const LinuxExecutablePathException(
        failure: LinuxExecutablePathFailure.notExecutable,
      );
    }

    return path;
  }

  static bool _isValidAbsolutePath(String value) {
    return value.isNotEmpty &&
        value.trim() == value &&
        value.startsWith('/') &&
        !value.contains('\u0000') &&
        !value.contains('\n') &&
        !value.contains('\r');
  }
}
