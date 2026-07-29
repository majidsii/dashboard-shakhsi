import 'dart:convert';

import 'linux_systemd_file_system.dart';
import 'linux_systemd_notification_unit.dart';
import 'linux_systemd_unit_renderer.dart';
import 'linux_systemd_user_unit_path_resolver.dart';
import 'linux_systemd_user_unit_store_exception.dart';

typedef LinuxSystemdTransactionIdFactory = String Function();

/// Installs matching systemd user service and timer files.
///
/// This Gate implements the validated successful transaction path. Full
/// failure rollback is added by Task 10.2.5.
final class LinuxSystemdUserUnitStore {
  factory LinuxSystemdUserUnitStore({
    required LinuxSystemdUserUnitPathResolver pathResolver,
    required LinuxSystemdFileSystem fileSystem,
    required LinuxSystemdTransactionIdFactory transactionIdFactory,
  }) {
    return LinuxSystemdUserUnitStore._(
      pathResolver,
      fileSystem,
      transactionIdFactory,
    );
  }

  LinuxSystemdUserUnitStore._(
    this._pathResolver,
    this._fileSystem,
    this._transactionIdFactory,
  );

  static final RegExp _serviceNamePattern = RegExp(
    r'^(dashboard-shakhsi-notification-[0-9a-f]{16})\.service$',
  );
  static final RegExp _timerNamePattern = RegExp(
    r'^(dashboard-shakhsi-notification-[0-9a-f]{16})\.timer$',
  );
  static final RegExp _transactionIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static const int _unitFileMode = 0x1A4;

  final LinuxSystemdUserUnitPathResolver _pathResolver;
  final LinuxSystemdFileSystem _fileSystem;
  final LinuxSystemdTransactionIdFactory _transactionIdFactory;

  Future<void> install(LinuxSystemdRenderedUnits units) async {
    _InstallPaths? paths;

    try {
      _validateUnitNames(units);

      final transactionId = _transactionIdFactory();
      _validateTransactionId(transactionId);

      final directory = _pathResolver.resolve();
      paths = _InstallPaths(
        directory: directory,
        serviceFileName: units.serviceFileName,
        timerFileName: units.timerFileName,
        transactionId: transactionId,
      );

      await _fileSystem.createDirectory(directory);

      final serviceType = await _validateFinalPath(paths.serviceFinal);
      final timerType = await _validateFinalPath(paths.timerFinal);

      await _requireMissing(paths.serviceTemp);
      await _requireMissing(paths.timerTemp);
      await _requireMissing(paths.serviceBackup);
      await _requireMissing(paths.timerBackup);

      await _fileSystem.writeBytes(
        paths.serviceTemp,
        utf8.encode(units.serviceContents),
      );
      await _fileSystem.writeBytes(
        paths.timerTemp,
        utf8.encode(units.timerContents),
      );
      await _fileSystem.chmod(paths.serviceTemp, _unitFileMode);
      await _fileSystem.chmod(paths.timerTemp, _unitFileMode);

      if (serviceType == LinuxSystemdEntryType.regularFile) {
        await _fileSystem.rename(paths.serviceFinal, paths.serviceBackup);
      }
      if (timerType == LinuxSystemdEntryType.regularFile) {
        await _fileSystem.rename(paths.timerFinal, paths.timerBackup);
      }

      await _fileSystem.rename(paths.serviceTemp, paths.serviceFinal);
      await _fileSystem.rename(paths.timerTemp, paths.timerFinal);

      await _fileSystem.chmod(paths.serviceFinal, _unitFileMode);
      await _fileSystem.chmod(paths.timerFinal, _unitFileMode);

      await _fileSystem.deleteFile(paths.serviceBackup);
      await _fileSystem.deleteFile(paths.timerBackup);
    } catch (error, stackTrace) {
      if (paths != null) {
        await _deletePreparedFileBestEffort(paths.serviceTemp);
        await _deletePreparedFileBestEffort(paths.timerTemp);
      }

      throw LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.install,
        serviceFileName: units.serviceFileName,
        timerFileName: units.timerFileName,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  Future<void> remove(LinuxSystemdUnitNames names) {
    throw UnsupportedError('Unit removal is implemented by Task 10.2.6.');
  }

  void _validateUnitNames(LinuxSystemdRenderedUnits units) {
    final serviceMatch = _serviceNamePattern.firstMatch(units.serviceFileName);
    final timerMatch = _timerNamePattern.firstMatch(units.timerFileName);

    if (serviceMatch == null || timerMatch == null) {
      throw ArgumentError(
        'Systemd unit file names must use renderer-generated names.',
      );
    }

    if (serviceMatch.group(1) != timerMatch.group(1)) {
      throw ArgumentError(
        'The service and timer must share the same unit base name.',
      );
    }
  }

  void _validateTransactionId(String transactionId) {
    if (!_transactionIdPattern.hasMatch(transactionId)) {
      throw ArgumentError.value(
        transactionId,
        'transactionId',
        'must contain only letters, digits, underscore, or hyphen',
      );
    }
  }

  Future<LinuxSystemdEntryType> _validateFinalPath(String path) async {
    final type = await _fileSystem.typeOf(path);

    if (type == LinuxSystemdEntryType.missing ||
        type == LinuxSystemdEntryType.regularFile) {
      return type;
    }

    throw LinuxSystemdUnsafeEntryException(
      path: path,
      entryType: type,
      operation: 'replace',
    );
  }

  Future<void> _requireMissing(String path) async {
    final type = await _fileSystem.typeOf(path);
    if (type == LinuxSystemdEntryType.missing) {
      return;
    }

    throw LinuxSystemdUnsafeEntryException(
      path: path,
      entryType: type,
      operation: 'reuse transaction artifact',
    );
  }

  Future<void> _deletePreparedFileBestEffort(String path) async {
    try {
      await _fileSystem.deleteFile(path);
    } on Object {
      // Full cleanup and rollback failure reporting is added in Task 10.2.5.
    }
  }
}

final class _InstallPaths {
  const _InstallPaths({
    required this.directory,
    required this.serviceFileName,
    required this.timerFileName,
    required this.transactionId,
  });

  final String directory;
  final String serviceFileName;
  final String timerFileName;
  final String transactionId;

  String get serviceFinal => '$directory/$serviceFileName';
  String get timerFinal => '$directory/$timerFileName';

  String get serviceTemp => '$directory/.$serviceFileName.$transactionId.tmp';
  String get timerTemp => '$directory/.$timerFileName.$transactionId.tmp';

  String get serviceBackup => '$directory/.$serviceFileName.$transactionId.bak';
  String get timerBackup => '$directory/.$timerFileName.$transactionId.bak';
}
