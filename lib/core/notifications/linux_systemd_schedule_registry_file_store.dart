import 'linux_systemd_file_system.dart';
import 'linux_systemd_schedule_registry.dart';
import 'linux_systemd_schedule_registry_codec.dart';
import 'linux_systemd_schedule_registry_exception.dart';
import 'linux_systemd_schedule_registry_store.dart';
import 'linux_systemd_user_unit_path_resolver.dart';

/// File-backed registry inventory stored beside app-owned systemd user units.
final class LinuxSystemdScheduleRegistryFileStore
    implements LinuxSystemdScheduleRegistryStore {
  const LinuxSystemdScheduleRegistryFileStore({
    required this.pathResolver,
    required this.fileSystem,
    required this.codec,
    required this.transactionIdFactory,
  });

  static const String registryFileName =
      'dashboard-shakhsi-notification-registry.json';
  static const int registryFileMode = 0x180;

  final LinuxSystemdUserUnitPathResolver pathResolver;
  final LinuxSystemdFileSystem fileSystem;
  final LinuxSystemdScheduleRegistryCodec codec;
  final LinuxSystemdRegistryTransactionIdFactory transactionIdFactory;

  @override
  Future<LinuxSystemdScheduleRegistry> load() async {
    final directory = _resolveDirectory();
    final registryPath = '$directory/$registryFileName';
    final entryType = await _filesystemStep(
      registryPath,
      () => fileSystem.typeOf(registryPath),
    );

    switch (entryType) {
      case LinuxSystemdEntryType.missing:
        return LinuxSystemdScheduleRegistry.empty();
      case LinuxSystemdEntryType.regularFile:
        break;
      case LinuxSystemdEntryType.directory:
      case LinuxSystemdEntryType.symbolicLink:
      case LinuxSystemdEntryType.other:
        throw LinuxSystemdScheduleRegistryException(
          operation: LinuxSystemdScheduleRegistryOperation.load,
          failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
          path: registryPath,
        );
    }

    final length = await _filesystemStep(
      registryPath,
      () => fileSystem.fileLength(registryPath),
    );

    if (length > LinuxSystemdScheduleRegistryCodec.maximumFileBytes) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.load,
        failure: LinuxSystemdScheduleRegistryFailure.oversizedRegistry,
        path: registryPath,
      );
    }

    final bytes = await _filesystemStep(
      registryPath,
      () => fileSystem.readBytes(registryPath),
    );
    final mode = await _filesystemStep(
      registryPath,
      () => fileSystem.readMode(registryPath),
    );

    if (mode != registryFileMode) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.load,
        failure: LinuxSystemdScheduleRegistryFailure.insecureRegistryMode,
        path: registryPath,
      );
    }

    try {
      return codec.decodeBytes(bytes);
    } on LinuxSystemdScheduleRegistryException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LinuxSystemdScheduleRegistryException(
          operation: LinuxSystemdScheduleRegistryOperation.load,
          failure: error.failure,
          path: registryPath,
          field: error.field,
          cause: error,
          causeStackTrace: stackTrace,
          rollbackFailures: error.rollbackFailures,
        ),
        stackTrace,
      );
    }
  }

  String _resolveDirectory() {
    try {
      return pathResolver.resolve();
    } catch (error, stackTrace) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.load,
        failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  Future<T> _filesystemStep<T>(
    String registryPath,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.load,
        failure: LinuxSystemdScheduleRegistryFailure.unsafeRegistryPath,
        path: registryPath,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }
}
