import 'dart:async';
import 'dart:collection';

import 'package:dashboard_shakhsi/core/notifications/linux_process_request.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_process_starter.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_started_process.dart';

final class FakeLinuxProcessStarter implements LinuxProcessStarter {
  final Queue<_FakeLinuxProcessStartOutcome> _outcomes =
      Queue<_FakeLinuxProcessStartOutcome>();
  final List<LinuxProcessRequest> _requests = <LinuxProcessRequest>[];

  List<LinuxProcessRequest> get requests =>
      List<LinuxProcessRequest>.unmodifiable(_requests);

  int get pendingOutcomeCount => _outcomes.length;

  void enqueueProcess(LinuxStartedProcess process) {
    _outcomes.addLast(_StartedProcessOutcome(process));
  }

  void enqueueFailure(Object error, StackTrace stackTrace) {
    _outcomes.addLast(
      _StartFailureOutcome(error: error, stackTrace: stackTrace),
    );
  }

  @override
  Future<LinuxStartedProcess> start(LinuxProcessRequest request) async {
    _requests.add(request);

    if (_outcomes.isEmpty) {
      throw StateError('No fake Linux process start outcome is queued.');
    }

    return _outcomes.removeFirst().resolve();
  }
}

final class ControllableLinuxStartedProcess implements LinuxStartedProcess {
  ControllableLinuxStartedProcess({required this.pid}) {
    _stdoutController = StreamController<List<int>>(
      sync: true,
      onListen: () {
        if (!_stdoutListenedCompleter.isCompleted) {
          _stdoutListenedCompleter.complete();
        }
      },
    );
    _stderrController = StreamController<List<int>>(
      sync: true,
      onListen: () {
        if (!_stderrListenedCompleter.isCompleted) {
          _stderrListenedCompleter.complete();
        }
      },
    );
  }

  @override
  final int pid;

  late final StreamController<List<int>> _stdoutController;
  late final StreamController<List<int>> _stderrController;
  final Completer<int> _exitCodeCompleter = Completer<int>.sync();
  final Completer<void> _stdoutListenedCompleter = Completer<void>.sync();
  final Completer<void> _stderrListenedCompleter = Completer<void>.sync();
  final List<LinuxProcessSignal> _signals = <LinuxProcessSignal>[];

  Future<void> get stdoutListened => _stdoutListenedCompleter.future;
  Future<void> get stderrListened => _stderrListenedCompleter.future;

  List<LinuxProcessSignal> get signals =>
      List<LinuxProcessSignal>.unmodifiable(_signals);

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  void addStdout(List<int> bytes) {
    _stdoutController.add(List<int>.of(bytes));
  }

  void addStderr(List<int> bytes) {
    _stderrController.add(List<int>.of(bytes));
  }

  void addStdoutError(Object error, StackTrace stackTrace) {
    _stdoutController.addError(error, stackTrace);
  }

  void addStderrError(Object error, StackTrace stackTrace) {
    _stderrController.addError(error, stackTrace);
  }

  Future<void> closeStdout() => _stdoutController.close();

  Future<void> closeStderr() => _stderrController.close();

  bool completeExit(int code) {
    if (_exitCodeCompleter.isCompleted) {
      return false;
    }

    _exitCodeCompleter.complete(code);
    return true;
  }

  @override
  bool kill(LinuxProcessSignal signal) {
    _signals.add(signal);
    return true;
  }
}

sealed class _FakeLinuxProcessStartOutcome {
  const _FakeLinuxProcessStartOutcome();

  Future<LinuxStartedProcess> resolve();
}

final class _StartedProcessOutcome extends _FakeLinuxProcessStartOutcome {
  const _StartedProcessOutcome(this.process);

  final LinuxStartedProcess process;

  @override
  Future<LinuxStartedProcess> resolve() async => process;
}

final class _StartFailureOutcome extends _FakeLinuxProcessStartOutcome {
  const _StartFailureOutcome({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Future<LinuxStartedProcess> resolve() async {
    Error.throwWithStackTrace(error, stackTrace);
  }
}
