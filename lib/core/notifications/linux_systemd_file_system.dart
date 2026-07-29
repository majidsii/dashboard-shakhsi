/// Link-aware filesystem entry type used by the Linux systemd store.
enum LinuxSystemdEntryType {
  missing,
  regularFile,
  directory,
  symbolicLink,
  other,
}

/// Raised when a filesystem operation would touch an unsafe entry type.
final class LinuxSystemdUnsafeEntryException implements Exception {
  const LinuxSystemdUnsafeEntryException({
    required this.path,
    required this.entryType,
    required this.operation,
  });

  final String path;
  final LinuxSystemdEntryType entryType;
  final String operation;

  @override
  String toString() {
    return 'LinuxSystemdUnsafeEntryException: cannot $operation '
        '$entryType entry at $path';
  }
}

/// Injectable, link-aware filesystem contract for systemd user units.
abstract interface class LinuxSystemdFileSystem {
  Future<void> createDirectory(String path);

  Future<LinuxSystemdEntryType> typeOf(String path);

  Future<List<int>> readBytes(String path);

  Future<void> writeBytes(String path, List<int> bytes);

  Future<void> rename(String sourcePath, String destinationPath);

  Future<void> deleteFile(String path);

  Future<void> chmod(String path, int mode);
}
