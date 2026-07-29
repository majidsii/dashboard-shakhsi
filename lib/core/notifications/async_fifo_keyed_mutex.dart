import 'dart:async';
import 'dart:collection';

final class AsyncFifoKeyedMutex<K> {
  final Map<K, _KeyQueue> _entries = <K, _KeyQueue>{};

  int get activeKeyCount => _entries.length;

  bool containsKey(K key) => _entries.containsKey(key);

  Future<T> synchronized<T>(K key, FutureOr<T> Function() action) {
    final result = Completer<T>.sync();
    final cleanup = Completer<void>.sync();
    final entry = _entries.putIfAbsent(key, _KeyQueue.new);

    entry.jobs.addLast(
      _KeyedJob(
        run: () async {
          try {
            result.complete(await Future<T>.sync(action));
          } catch (error, stackTrace) {
            result.completeError(error, stackTrace);
          }
        },
        cleanup: cleanup,
      ),
    );

    if (!entry.running) {
      entry.running = true;

      scheduleMicrotask(() {
        _drain(key, entry);
      });
    }

    // The caller does not observe completion until any final
    // idle-key cleanup for this job has also completed.
    return result.future.whenComplete(() => cleanup.future);
  }

  Future<void> _drain(K key, _KeyQueue entry) async {
    while (entry.jobs.isNotEmpty) {
      final job = entry.jobs.removeFirst();

      await job.run();

      final isFinalJob = entry.jobs.isEmpty;

      if (isFinalJob && identical(_entries[key], entry)) {
        entry.running = false;
        _entries.remove(key);
      }

      job.cleanup.complete();

      if (isFinalJob) {
        return;
      }
    }

    entry.running = false;

    if (identical(_entries[key], entry)) {
      _entries.remove(key);
    }
  }
}

final class _KeyQueue {
  final Queue<_KeyedJob> jobs = Queue<_KeyedJob>();

  bool running = false;
}

final class _KeyedJob {
  const _KeyedJob({required this.run, required this.cleanup});

  final Future<void> Function() run;
  final Completer<void> cleanup;
}
