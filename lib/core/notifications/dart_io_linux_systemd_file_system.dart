import 'dart:io';

import 'package:posix/posix.dart' as posix;

import 'linux_systemd_file_system.dart';

/// Production Linux filesystem adapter backed by dart:io and POSIX FFI.
final class DartIoLinuxSystemdFileSystem implements LinuxSystemdFileSystem {
  const DartIoLinuxSystemdFileSystem();

  @override
  Future<void> createDirectory(String path) {
    return Directory(path).create(recursive: true);
  }

  @override
  Future<LinuxSystemdEntryType> typeOf(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);

    return switch (type) {
      FileSystemEntityType.notFound => LinuxSystemdEntryType.missing,
      FileSystemEntityType.file => LinuxSystemdEntryType.regularFile,
      FileSystemEntityType.directory => LinuxSystemdEntryType.directory,
      FileSystemEntityType.link => LinuxSystemdEntryType.symbolicLink,
      _ => LinuxSystemdEntryType.other,
    };
  }

  @override
  Future<int> fileLength(String path) async {
    final entryType = await typeOf(path);
    if (entryType != LinuxSystemdEntryType.regularFile) {
      throw LinuxSystemdUnsafeEntryException(
        path: path,
        entryType: entryType,
        operation: 'read length from',
      );
    }

    return File(path).length();
  }

  @override
  Future<List<String>> listNames(String directoryPath) async {
    final entryType = await typeOf(directoryPath);

    switch (entryType) {
      case LinuxSystemdEntryType.missing:
        return const <String>[];
      case LinuxSystemdEntryType.directory:
        break;
      case LinuxSystemdEntryType.regularFile:
      case LinuxSystemdEntryType.symbolicLink:
      case LinuxSystemdEntryType.other:
        throw LinuxSystemdUnsafeEntryException(
          path: directoryPath,
          entryType: entryType,
          operation: 'list',
        );
    }

    final names = <String>{};

    await for (final entity in Directory(
      directoryPath,
    ).list(recursive: false, followLinks: false)) {
      names.add(_baseName(entity.path));
    }

    final sorted = names.toList()..sort();
    return List<String>.unmodifiable(sorted);
  }

  @override
  Future<List<int>> readBytes(String path) {
    return File(path).readAsBytes();
  }

  @override
  Future<int> readMode(String path) async {
    final entryType = await typeOf(path);
    if (entryType != LinuxSystemdEntryType.regularFile) {
      throw LinuxSystemdUnsafeEntryException(
        path: path,
        entryType: entryType,
        operation: 'read mode from',
      );
    }

    final stat = await FileStat.stat(path);
    return stat.mode & 0x1FF;
  }

  @override
  Future<void> writeBytes(String path, List<int> bytes) async {
    await File(path).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> rename(String sourcePath, String destinationPath) async {
    await File(sourcePath).rename(destinationPath);
  }

  @override
  Future<void> deleteFile(String path) async {
    final entryType = await typeOf(path);

    switch (entryType) {
      case LinuxSystemdEntryType.missing:
        return;
      case LinuxSystemdEntryType.regularFile:
        await File(path).delete();
      case LinuxSystemdEntryType.directory:
      case LinuxSystemdEntryType.symbolicLink:
      case LinuxSystemdEntryType.other:
        throw LinuxSystemdUnsafeEntryException(
          path: path,
          entryType: entryType,
          operation: 'delete',
        );
    }
  }

  @override
  Future<void> chmod(String path, int mode) async {
    if (mode < 0 || mode > 0x1FF) {
      throw ArgumentError.value(
        mode,
        'mode',
        'must contain only POSIX permission bits',
      );
    }

    if (!Platform.isLinux) {
      throw UnsupportedError(
        'Linux systemd permissions are supported only on Linux.',
      );
    }

    posix.chmodWithMode(path, mode);
  }

  static String _baseName(String path) {
    final index = path.lastIndexOf('/');
    return index < 0 ? path : path.substring(index + 1);
  }
}
