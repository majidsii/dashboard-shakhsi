import 'dart:io';

import 'linux_process_request.dart';
import 'linux_started_process.dart';

abstract interface class LinuxProcessStarter {
  Future<LinuxStartedProcess> start(LinuxProcessRequest request);
}

final class DartIoLinuxProcessStarter implements LinuxProcessStarter {
  const DartIoLinuxProcessStarter();

  @override
  Future<LinuxStartedProcess> start(LinuxProcessRequest request) async {
    final process = await Process.start(
      request.executable,
      request.arguments,
      environment: request.environment,
      includeParentEnvironment: request.includeParentEnvironment,
      runInShell: false,
      mode: ProcessStartMode.normal,
    );

    return _DartIoLinuxStartedProcess(process);
  }
}

final class _DartIoLinuxStartedProcess implements LinuxStartedProcess {
  const _DartIoLinuxStartedProcess(this._process);

  final Process _process;

  @override
  int get pid => _process.pid;

  @override
  Stream<List<int>> get stdout => _process.stdout;

  @override
  Stream<List<int>> get stderr => _process.stderr;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  bool kill(LinuxProcessSignal signal) {
    return _process.kill(switch (signal) {
      LinuxProcessSignal.sigterm => ProcessSignal.sigterm,
      LinuxProcessSignal.sigkill => ProcessSignal.sigkill,
    });
  }
}
