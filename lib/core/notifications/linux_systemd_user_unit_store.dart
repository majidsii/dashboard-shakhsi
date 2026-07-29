import 'dart:convert';

import 'linux_systemd_file_system.dart';
import 'linux_systemd_notification_unit.dart';
import 'linux_systemd_unit_renderer.dart';
import 'linux_systemd_user_unit_path_resolver.dart';
import 'linux_systemd_user_unit_store_exception.dart';

typedef LinuxSystemdTransactionIdFactory = String Function();

/// Installs matching systemd user service and timer files atomically.
///
/// The transaction snapshots old bytes and modes, prepares both new files,
/// commits through same-directory renames, and performs full in-process
/// rollback while preserving the original failure as the primary cause.
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
    final state = _InstallTransactionState();

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

      final serviceType = await _validateFinalPath(paths.service.finalPath);
      final timerType = await _validateFinalPath(paths.timer.finalPath);

      await _requireMissing(paths.service.tempPath);
      await _requireMissing(paths.timer.tempPath);
      await _requireMissing(paths.service.backupPath);
      await _requireMissing(paths.timer.backupPath);

      state.service.previous = await _snapshotExisting(
        paths.service.finalPath,
        serviceType,
      );
      state.timer.previous = await _snapshotExisting(
        paths.timer.finalPath,
        timerType,
      );

      await _fileSystem.writeBytes(
        paths.service.tempPath,
        utf8.encode(units.serviceContents),
      );
      state.service.tempExists = true;

      await _fileSystem.writeBytes(
        paths.timer.tempPath,
        utf8.encode(units.timerContents),
      );
      state.timer.tempExists = true;

      await _fileSystem.chmod(paths.service.tempPath, _unitFileMode);
      await _fileSystem.chmod(paths.timer.tempPath, _unitFileMode);

      if (state.service.previous != null) {
        await _fileSystem.rename(
          paths.service.finalPath,
          paths.service.backupPath,
        );
        state.service.backupExists = true;
      }

      if (state.timer.previous != null) {
        await _fileSystem.rename(paths.timer.finalPath, paths.timer.backupPath);
        state.timer.backupExists = true;
      }

      await _fileSystem.rename(paths.service.tempPath, paths.service.finalPath);
      state.service
        ..tempExists = false
        ..installed = true;

      await _fileSystem.rename(paths.timer.tempPath, paths.timer.finalPath);
      state.timer
        ..tempExists = false
        ..installed = true;

      await _fileSystem.chmod(paths.service.finalPath, _unitFileMode);
      await _fileSystem.chmod(paths.timer.finalPath, _unitFileMode);

      if (state.service.backupExists) {
        await _fileSystem.deleteFile(paths.service.backupPath);
        state.service.backupExists = false;
      }

      if (state.timer.backupExists) {
        await _fileSystem.deleteFile(paths.timer.backupPath);
        state.timer.backupExists = false;
      }
    } catch (error, stackTrace) {
      final rollbackFailures = <LinuxSystemdRollbackFailure>[];

      if (paths != null) {
        await _rollback(paths, state, rollbackFailures);
      }

      throw LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.install,
        serviceFileName: units.serviceFileName,
        timerFileName: units.timerFileName,
        cause: error,
        causeStackTrace: stackTrace,
        rollbackFailures: rollbackFailures,
      );
    }
  }

  Future<void> remove(LinuxSystemdUnitNames names) {
    throw UnsupportedError('Unit removal is implemented by Task 10.2.6.');
  }

  Future<_ExistingUnitSnapshot?> _snapshotExisting(
    String path,
    LinuxSystemdEntryType type,
  ) async {
    if (type == LinuxSystemdEntryType.missing) {
      return null;
    }

    return _ExistingUnitSnapshot(
      bytes: await _fileSystem.readBytes(path),
      mode: await _fileSystem.readMode(path),
    );
  }

  Future<void> _rollback(
    _InstallPaths paths,
    _InstallTransactionState state,
    List<LinuxSystemdRollbackFailure> failures,
  ) async {
    await _deleteInstalledUnit(
      label: 'timer',
      paths: paths.timer,
      state: state.timer,
      failures: failures,
    );
    await _deleteInstalledUnit(
      label: 'service',
      paths: paths.service,
      state: state.service,
      failures: failures,
    );

    await _restorePreviousUnit(
      label: 'service',
      paths: paths.service,
      state: state.service,
      failures: failures,
    );
    await _restorePreviousUnit(
      label: 'timer',
      paths: paths.timer,
      state: state.timer,
      failures: failures,
    );

    await _deleteTempUnit(
      label: 'service',
      paths: paths.service,
      state: state.service,
      failures: failures,
    );
    await _deleteTempUnit(
      label: 'timer',
      paths: paths.timer,
      state: state.timer,
      failures: failures,
    );
  }

  Future<void> _deleteInstalledUnit({
    required String label,
    required _UnitPaths paths,
    required _UnitTransactionState state,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    if (!state.installed) {
      return;
    }

    final deleted = await _attemptRollback(
      step: 'delete-new-$label',
      action: () => _fileSystem.deleteFile(paths.finalPath),
      failures: failures,
    );

    if (deleted) {
      state.installed = false;
    }
  }

  Future<void> _restorePreviousUnit({
    required String label,
    required _UnitPaths paths,
    required _UnitTransactionState state,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    final previous = state.previous;
    if (previous == null) {
      return;
    }

    var restored = false;

    if (state.backupExists) {
      restored = await _attemptRollback(
        step: 'restore-$label-backup',
        action: () => _fileSystem.rename(paths.backupPath, paths.finalPath),
        failures: failures,
      );

      if (restored) {
        state
          ..backupExists = false
          ..installed = false;
      }
    }

    if (!restored) {
      final bytesRestored = await _attemptRollback(
        step: 'restore-$label-snapshot-write',
        action: () => _fileSystem.writeBytes(paths.finalPath, previous.bytes),
        failures: failures,
      );

      if (bytesRestored) {
        final modeRestored = await _attemptRollback(
          step: 'restore-$label-snapshot-mode',
          action: () => _fileSystem.chmod(paths.finalPath, previous.mode),
          failures: failures,
        );

        if (modeRestored) {
          restored = true;
          state.installed = false;
        }
      }
    }

    if (restored && state.backupExists) {
      final deleted = await _attemptRollback(
        step: 'delete-$label-backup-after-restore',
        action: () => _fileSystem.deleteFile(paths.backupPath),
        failures: failures,
      );

      if (deleted) {
        state.backupExists = false;
      }
    }
  }

  Future<void> _deleteTempUnit({
    required String label,
    required _UnitPaths paths,
    required _UnitTransactionState state,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    if (!state.tempExists) {
      return;
    }

    final deleted = await _attemptRollback(
      step: 'delete-$label-temp',
      action: () => _fileSystem.deleteFile(paths.tempPath),
      failures: failures,
    );

    if (deleted) {
      state.tempExists = false;
    }
  }

  Future<bool> _attemptRollback({
    required String step,
    required Future<void> Function() action,
    required List<LinuxSystemdRollbackFailure> failures,
  }) async {
    try {
      await action();
      return true;
    } catch (error, stackTrace) {
      failures.add(
        LinuxSystemdRollbackFailure(
          step: step,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return false;
    }
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
}

final class _ExistingUnitSnapshot {
  _ExistingUnitSnapshot({required List<int> bytes, required this.mode})
    : bytes = List<int>.unmodifiable(bytes);

  final List<int> bytes;
  final int mode;
}

final class _UnitTransactionState {
  _ExistingUnitSnapshot? previous;
  bool tempExists = false;
  bool backupExists = false;
  bool installed = false;
}

final class _InstallTransactionState {
  final _UnitTransactionState service = _UnitTransactionState();
  final _UnitTransactionState timer = _UnitTransactionState();
}

final class _UnitPaths {
  const _UnitPaths({
    required this.finalPath,
    required this.tempPath,
    required this.backupPath,
  });

  final String finalPath;
  final String tempPath;
  final String backupPath;
}

final class _InstallPaths {
  _InstallPaths({
    required String directory,
    required String serviceFileName,
    required String timerFileName,
    required String transactionId,
  }) : service = _UnitPaths(
         finalPath: '$directory/$serviceFileName',
         tempPath: '$directory/.$serviceFileName.$transactionId.tmp',
         backupPath: '$directory/.$serviceFileName.$transactionId.bak',
       ),
       timer = _UnitPaths(
         finalPath: '$directory/$timerFileName',
         tempPath: '$directory/.$timerFileName.$transactionId.tmp',
         backupPath: '$directory/.$timerFileName.$transactionId.bak',
       );

  final _UnitPaths service;
  final _UnitPaths timer;
}
