import 'dart:io';

import 'linux_executable_path_source.dart';

final class DartIoLinuxExecutablePathSource
    implements LinuxExecutablePathSource {
  const DartIoLinuxExecutablePathSource();

  @override
  Future<String> resolve() async => Platform.resolvedExecutable;
}

final class DartIoLinuxExecutableFileVerifier
    implements LinuxExecutableFileVerifier {
  const DartIoLinuxExecutableFileVerifier();

  @override
  Future<LinuxExecutableFileStatus> status(String path) async {
    final stat = await File(path).stat();
    final isRegularFile = stat.type == FileSystemEntityType.file;

    return LinuxExecutableFileStatus(
      exists: stat.type != FileSystemEntityType.notFound,
      isRegularFile: isRegularFile,
      isExecutable: isRegularFile && (stat.mode & 0x49) != 0,
    );
  }
}
