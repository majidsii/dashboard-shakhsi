import 'dart:async';

abstract interface class LinuxCancellationToken {
  bool get isCancelled;

  Future<void> get whenCancelled;
}

final class LinuxCancellationSource {
  final _LinuxCancellationToken _token = _LinuxCancellationToken();

  LinuxCancellationToken get token => _token;

  bool cancel() => _token.cancel();
}

final class _LinuxCancellationToken implements LinuxCancellationToken {
  final Completer<void> _completer = Completer<void>.sync();

  @override
  bool get isCancelled => _completer.isCompleted;

  @override
  Future<void> get whenCancelled => _completer.future;

  bool cancel() {
    if (_completer.isCompleted) {
      return false;
    }

    _completer.complete();
    return true;
  }
}
