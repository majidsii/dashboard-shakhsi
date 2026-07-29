enum LinuxProcessSignal { sigterm, sigkill }

abstract interface class LinuxStartedProcess {
  int get pid;

  Stream<List<int>> get stdout;

  Stream<List<int>> get stderr;

  Future<int> get exitCode;

  bool kill(LinuxProcessSignal signal);
}
