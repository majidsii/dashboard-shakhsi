import 'dart:async';
import 'dart:collection';

final class AsyncWriterPreferringRwLock {
  final Queue<Completer<void>> _waitingReaders = Queue<Completer<void>>();
  final Queue<Completer<void>> _waitingWriters = Queue<Completer<void>>();

  int _activeReaders = 0;
  bool _writerActive = false;

  int get activeReaderCount => _activeReaders;
  bool get isWriterActive => _writerActive;
  int get waitingReaderCount => _waitingReaders.length;
  int get waitingWriterCount => _waitingWriters.length;

  Future<T> runRead<T>(FutureOr<T> Function() action) async {
    await _acquireRead();

    try {
      return await Future<T>.sync(action);
    } finally {
      _releaseRead();
    }
  }

  Future<T> runWrite<T>(FutureOr<T> Function() action) async {
    await _acquireWrite();

    try {
      return await Future<T>.sync(action);
    } finally {
      _releaseWrite();
    }
  }

  Future<void> _acquireRead() {
    if (!_writerActive && _waitingWriters.isEmpty) {
      _activeReaders++;
      return Future<void>.value();
    }

    final completer = Completer<void>.sync();
    _waitingReaders.addLast(completer);
    return completer.future;
  }

  Future<void> _acquireWrite() {
    if (!_writerActive && _activeReaders == 0) {
      _writerActive = true;
      return Future<void>.value();
    }

    final completer = Completer<void>.sync();
    _waitingWriters.addLast(completer);
    return completer.future;
  }

  void _releaseRead() {
    if (_activeReaders <= 0) {
      throw StateError('No active read lock to release.');
    }

    _activeReaders--;

    if (_activeReaders == 0) {
      _drainWaiters();
    }
  }

  void _releaseWrite() {
    if (!_writerActive) {
      throw StateError('No active write lock to release.');
    }

    _writerActive = false;
    _drainWaiters();
  }

  void _drainWaiters() {
    if (_writerActive || _activeReaders != 0) {
      return;
    }

    if (_waitingWriters.isNotEmpty) {
      _writerActive = true;
      _waitingWriters.removeFirst().complete();
      return;
    }

    while (_waitingReaders.isNotEmpty) {
      _activeReaders++;
      _waitingReaders.removeFirst().complete();
    }
  }
}
