# Linux systemctl User Command Driver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Linux-only, shell-free `systemctl --user` command driver with bounded process output, real timeout termination, typed unit status, mandatory mutation postconditions, and deterministic concurrency control.

**Architecture:** All process execution is isolated behind an injectable `LinuxProcessRunner`. The production runner uses `Process.start`, concurrently drains bounded stdout/stderr, and terminates timed-out or cancelled processes through SIGTERM then SIGKILL. The systemctl driver validates application timer names, parses one machine-readable `show` query, serializes same-unit mutations, permits independent-unit concurrency, and verifies every mutation through a final status query.

**Tech Stack:** Dart 3, Flutter test, `dart:io`, `dart:async`, existing Task 10.1 systemd unit-name models, existing Task 10.2 Linux storage primitives.

## Global Constraints

- Linux-specific production code only; Android, iOS, macOS, Windows, and web behavior remains unchanged.
- No automated test may execute a real `systemctl`.
- Use `Process.start`; do not use `Process.run`.
- Every production process uses `runInShell: false`.
- Executable and arguments remain separate structured values.
- Default command timeout is exactly 15 seconds.
- Default termination grace period is exactly 2 seconds.
- Timeout and cancellation terminate the real child process.
- Termination sequence is SIGTERM, grace period, then SIGKILL when still running.
- stdout and stderr are drained concurrently through completion.
- Default stdout and stderr limits are exactly 256 KiB each.
- Truncated output retains 128 KiB prefix and 128 KiB suffix.
- Invalid UTF-8 is decoded safely and marked.
- Child environment overrides `LC_ALL=C`, `LANG=C`, `SYSTEMD_COLORS=0`, `SYSTEMD_PAGER=cat`, and `SYSTEMD_PAGERSECURE=1`.
- Every command includes `--no-pager`.
- Public unit operations accept only renderer-generated application timer names.
- Status uses one `systemctl --user show` request.
- Enable and disable mutations have mandatory postcondition verification.
- Mutation commands are never blindly retried.
- Ambiguous mutation outcomes receive exactly one reconciliation status query.
- Explicit caller cancellation remains cancellation.
- Same-unit operations are serialized.
- Independent units may execute concurrently.
- Daemon reload is globally exclusive.
- Global reader/writer locking is writer-preferring after a writer queues.
- Per-unit mutex waiters are FIFO.
- Locks and process resources are released on every failure path.
- Do not print process output from production classes.
- Do not log full inherited environments or unbounded child output.
- Follow RED → verify correct failure → GREEN → focused test → analyze → full test → Linux build → commit.

---

## File Map

### Process primitives

- Create `lib/core/notifications/linux_process_request.dart`
  - immutable executable, arguments, environment, timeout, grace period, and limits
- Create `lib/core/notifications/linux_bounded_output.dart`
  - immutable bounded-output value model in Task 1; streaming collector added in Task 2
- Create `lib/core/notifications/linux_process_result.dart`
  - immutable completed-process result
- Create `lib/core/notifications/linux_cancellation_token.dart`
  - one-shot cancellation source and token
- Create `lib/core/notifications/linux_process_exception.dart`
  - start, timeout, cancellation, stream, and termination exceptions
- Create `lib/core/notifications/linux_process_runner.dart`
  - injectable runner contract
- Create `lib/core/notifications/dart_io_linux_process_runner.dart`
  - production process lifecycle implementation

### Driver primitives

- Create `lib/core/notifications/linux_systemd_timer_name.dart`
  - strict application timer-name model
- Create `lib/core/notifications/linux_systemd_unit_status.dart`
  - typed load, enablement, activity, and diagnostic state
- Create `lib/core/notifications/linux_systemd_status_parser.dart`
  - strict `key=value` parser
- Create `lib/core/notifications/linux_systemd_command_exception.dart`
  - command, parse, unit-name, and postcondition errors
- Create `lib/core/notifications/linux_async_read_write_lock.dart`
  - writer-preferring global lock
- Create `lib/core/notifications/linux_keyed_mutex.dart`
  - FIFO per-unit mutex with cleanup
- Create `lib/core/notifications/linux_systemd_user_command_driver.dart`
  - public API and process-backed implementation

### Test support

- Create `test/support/fake_linux_process_runner.dart`
- Create `test/support/recording_linux_process_runner.dart`
- Create `test/support/process_test_helper.dart`

### Focused tests

- Create `test/core/notifications/linux_process_request_test.dart`
- Create `test/core/notifications/linux_bounded_output_test.dart`
- Create `test/core/notifications/linux_process_test_doubles_test.dart`
- Create `test/core/notifications/dart_io_linux_process_runner_test.dart`
- Create `test/core/notifications/linux_systemd_timer_name_test.dart`
- Create `test/core/notifications/linux_systemd_status_parser_test.dart`
- Create `test/core/notifications/linux_systemd_locks_test.dart`
- Create `test/core/notifications/linux_systemd_user_command_driver_test.dart`
- Create `test/core/notifications/linux_systemd_user_command_mutation_test.dart`

### Completion artifacts

- Create `tool/verify_phase1_task10_3_structure.py`
- Create `tool/finalize_phase1_task10_3_checkpoint.py`
- Create `tool/verify_phase1_task10_3_complete.py`
- Create `docs/superpowers/checkpoints/2026-07-29-linux-systemctl-user-command-driver-checkpoint.md`
- Modify `docs/superpowers/specs/2026-07-29-linux-systemctl-user-command-driver-design.md`

---

### Task 1: Immutable Process Request, Result, Cancellation, and Error Models

**Files:**
- Create: `lib/core/notifications/linux_process_request.dart`
- Create: `lib/core/notifications/linux_bounded_output.dart`
- Create: `lib/core/notifications/linux_process_result.dart`
- Create: `lib/core/notifications/linux_cancellation_token.dart`
- Create: `lib/core/notifications/linux_process_exception.dart`
- Create: `lib/core/notifications/linux_process_runner.dart`
- Test: `test/core/notifications/linux_process_request_test.dart`

**Interfaces:**
- Produces:

```dart
abstract interface class LinuxProcessRunner {
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  });
}

final class LinuxProcessRequest {
  factory LinuxProcessRequest({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    Duration timeout = const Duration(seconds: 15),
    Duration terminationGracePeriod = const Duration(seconds: 2),
    int stdoutLimitBytes = 256 * 1024,
    int stderrLimitBytes = 256 * 1024,
    bool includeParentEnvironment = true,
  });
}

final class LinuxBoundedOutput {
  const LinuxBoundedOutput({
    required String text,
    required int totalBytes,
    required int retainedBytes,
    required int droppedBytes,
    required bool truncated,
    required bool malformedUtf8,
  });
}

final class LinuxCancellationSource {
  LinuxCancellationToken get token;
  bool cancel();
}

abstract interface class LinuxCancellationToken {
  bool get isCancelled;
  Future<void> get whenCancelled;
}
```

- [ ] **Step 1: Write RED tests for request validation and immutability**

Test exact defaults, immutable argument/environment copies, executable trimming rejection, NUL rejection, positive timeout, non-negative grace period, and output limits of at least 2048 bytes.

```dart
test('uses production-safe defaults', () {
  final request = LinuxProcessRequest(
    executable: 'systemctl',
    arguments: const <String>['--user'],
    environment: const <String, String>{},
  );

  expect(request.timeout, const Duration(seconds: 15));
  expect(
    request.terminationGracePeriod,
    const Duration(seconds: 2),
  );
  expect(request.stdoutLimitBytes, 256 * 1024);
  expect(request.stderrLimitBytes, 256 * 1024);
  expect(request.includeParentEnvironment, isTrue);
});
```

Test immutable process results and bounded-output metadata snapshots.

Test one-shot cancellation:

```dart
test('cancellation source completes once', () async {
  final source = LinuxCancellationSource();

  expect(source.cancel(), isTrue);
  expect(source.cancel(), isFalse);
  await expectLater(source.token.whenCancelled, completes);
  expect(source.token.isCancelled, isTrue);
});
```

- [ ] **Step 2: Run RED**

```bash
flutter test test/core/notifications/linux_process_request_test.dart
```

Expected: compile failure because all Task 1 production files are absent.

- [ ] **Step 3: Implement minimal immutable models**

Use `List.unmodifiable` and `Map.unmodifiable`. Reject executable strings containing whitespace, control characters, shell operators, or NUL while allowing a single absolute executable path.

Create the immutable `LinuxBoundedOutput` value model needed by `LinuxProcessResult`; defer only the streaming collector algorithm to Task 2.

Create typed runner exceptions with immutable diagnostics but no inherited environment map.

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_process_request.dart \
  lib/core/notifications/linux_bounded_output.dart \
  lib/core/notifications/linux_process_result.dart \
  lib/core/notifications/linux_cancellation_token.dart \
  lib/core/notifications/linux_process_exception.dart \
  lib/core/notifications/linux_process_runner.dart \
  test/core/notifications/linux_process_request_test.dart

flutter test test/core/notifications/linux_process_request_test.dart
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_process_request.dart \
  lib/core/notifications/linux_bounded_output.dart \
  lib/core/notifications/linux_process_result.dart \
  lib/core/notifications/linux_cancellation_token.dart \
  lib/core/notifications/linux_process_exception.dart \
  lib/core/notifications/linux_process_runner.dart \
  test/core/notifications/linux_process_request_test.dart

git commit -m "feat: add Linux process execution models"
```

---

### Task 2: Bounded Byte Capture and UTF-8 Diagnostics

**Files:**
- Modify: `lib/core/notifications/linux_bounded_output.dart`
- Test: `test/core/notifications/linux_bounded_output_test.dart`

**Interfaces:**
- Consumes the immutable `LinuxBoundedOutput` model created in Task 1.
- Produces:

```dart
final class LinuxBoundedOutputCollector {
  LinuxBoundedOutputCollector({required int limitBytes});
  void add(List<int> bytes);
  LinuxBoundedOutput finish();
}
```

- [ ] **Step 1: Write RED tests for all retention boundaries**

Test:

- output below limit
- output exactly at limit
- output one byte above limit
- large output retains exact prefix and suffix halves
- odd limits allocate the extra byte deterministically to the suffix
- `totalBytes`, `retainedBytes`, and `droppedBytes`
- malformed UTF-8
- a multibyte sequence split across chunks
- a very large simulated stream without retained memory exceeding the configured limit

```dart
test('retains prefix and suffix when truncated', () {
  final collector = LinuxBoundedOutputCollector(limitBytes: 8)
    ..add(<int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

  final output = collector.finish();

  expect(output.truncated, isTrue);
  expect(output.totalBytes, 10);
  expect(output.retainedBytes, 8);
  expect(output.droppedBytes, 2);
});
```

- [ ] **Step 2: Run RED**

```bash
flutter test test/core/notifications/linux_bounded_output_test.dart
```

Expected: compile failure because the collector is absent.

- [ ] **Step 3: Implement bounded collector**

Count all incoming bytes. Before truncation, retain the complete stream. After exceeding the limit, preserve an immutable prefix buffer and a circular suffix buffer. Decode once in `finish()`.

Detect malformed UTF-8 by attempting strict decoding before replacement decoding.

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_bounded_output.dart \
  test/core/notifications/linux_bounded_output_test.dart

flutter test test/core/notifications/linux_bounded_output_test.dart
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_bounded_output.dart \
  test/core/notifications/linux_bounded_output_test.dart

git commit -m "feat: bound Linux process output capture"
```

---

### Task 3: Fake and Recording Process Runners

**Files:**
- Create: `test/support/fake_linux_process_runner.dart`
- Create: `test/support/recording_linux_process_runner.dart`
- Test: `test/core/notifications/linux_process_test_doubles_test.dart`

**Interfaces:**
- Produces:

```dart
final class FakeLinuxProcessRunner implements LinuxProcessRunner {
  void enqueueResult(LinuxProcessResult result);
  void enqueueFailure(Object error, StackTrace stackTrace);
  ControlledLinuxProcessCall enqueueControlled();
  int get pendingResponseCount;
}

final class RecordingLinuxProcessRunner implements LinuxProcessRunner {
  RecordingLinuxProcessRunner(this.delegate);
  List<RecordedLinuxProcessCall> get calls;
}
```

`ControlledLinuxProcessCall` exposes `complete`, `fail`, `requestReceived`, and cancellation observation.

- [ ] **Step 1: Write RED tests**

Test queued result order, queued failure order, controlled delayed completion, cancellation propagation, concurrent calls, immutable recorded requests, and proof that no `dart:io` process API appears in test doubles.

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/linux_process_test_doubles_test.dart
```

Expected: compile failure because both runners are absent.

- [ ] **Step 3: Implement deterministic test doubles**

Use FIFO queues. Copy every recorded request. Controlled calls complete through `Completer`.

The fake must throw a descriptive state error when invoked without a queued response.

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  test/support/fake_linux_process_runner.dart \
  test/support/recording_linux_process_runner.dart \
  test/core/notifications/linux_process_test_doubles_test.dart

flutter test \
  test/core/notifications/linux_process_test_doubles_test.dart

flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add \
  test/support/fake_linux_process_runner.dart \
  test/support/recording_linux_process_runner.dart \
  test/core/notifications/linux_process_test_doubles_test.dart

git commit -m "test: add Linux process runner doubles"
```

---

### Task 4: Dart IO Runner — Normal Completion and Concurrent Stream Draining

**Files:**
- Create: `lib/core/notifications/dart_io_linux_process_runner.dart`
- Create: `test/support/process_test_helper.dart`
- Test: `test/core/notifications/dart_io_linux_process_runner_test.dart`

**Interfaces:**
- Consumes Task 1 and Task 2 primitives.
- Produces:

```dart
final class DartIoLinuxProcessRunner implements LinuxProcessRunner {
  const DartIoLinuxProcessRunner();
}
```

- [ ] **Step 1: Create a controlled Dart helper process**

The helper accepts modes through arguments:

```text
echo
exit-nonzero
interleaved-output
large-output
invalid-utf8
wait-for-signal
ignore-term
```

It must be executable through the current Dart binary and must never call systemctl.

- [ ] **Step 2: Write RED tests for normal execution**

Test:

- executable and arguments
- exit code zero
- non-zero result returned rather than thrown
- concurrent stdout/stderr capture
- output emitted near process exit
- large bounded output
- malformed UTF-8 metadata
- immutable result data
- inherited environment plus explicit override

- [ ] **Step 3: Run RED**

```bash
flutter test \
  test/core/notifications/dart_io_linux_process_runner_test.dart
```

Expected: compile failure because `DartIoLinuxProcessRunner` is absent.

- [ ] **Step 4: Implement normal process lifecycle**

Use `Process.start(..., runInShell: false, mode: ProcessStartMode.normal)`.

Subscribe to both streams immediately. Feed collectors concurrently. Await process exit and both stream completions before returning.

Wrap spawn failures in `LinuxProcessStartException` and stream failures in `LinuxProcessStreamException`.

- [ ] **Step 5: Verify GREEN**

```bash
dart format \
  lib/core/notifications/dart_io_linux_process_runner.dart \
  test/support/process_test_helper.dart \
  test/core/notifications/dart_io_linux_process_runner_test.dart

flutter test \
  test/core/notifications/dart_io_linux_process_runner_test.dart

flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add \
  lib/core/notifications/dart_io_linux_process_runner.dart \
  test/support/process_test_helper.dart \
  test/core/notifications/dart_io_linux_process_runner_test.dart

git commit -m "feat: run Linux child processes safely"
```

---

### Task 5: Timeout, Cancellation, and Two-Stage Termination

**Files:**
- Modify: `lib/core/notifications/dart_io_linux_process_runner.dart`
- Modify: `test/support/process_test_helper.dart`
- Modify: `test/core/notifications/dart_io_linux_process_runner_test.dart`

**Interfaces:**
- Timeout throws `LinuxProcessTimeoutException`.
- Cancellation throws `LinuxProcessCancellationException`.
- Both expose PID, timing, bounded outputs, and signal-attempt metadata.

- [ ] **Step 1: Write RED tests for termination behavior**

Test:

- cancellation before spawn prevents helper execution
- timeout sends SIGTERM
- helper that exits on SIGTERM never receives SIGKILL
- helper that ignores SIGTERM receives SIGKILL after grace period
- cancellation after spawn uses the same escalation
- timeout and cancellation race has exactly one terminal reason
- repeated cancellation does not repeat signal sequence
- stdout/stderr are drained after forced termination
- timers and subscriptions do not complete twice

Use short test-only durations such as 250 ms timeout and 100 ms grace.

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/dart_io_linux_process_runner_test.dart
```

Expected: behavioral failures because the current runner lacks termination control.

- [ ] **Step 3: Implement a single terminal-state coordinator**

Create a private terminal reason enum:

```dart
enum _TerminalReason {
  completed,
  timedOut,
  cancelled,
  streamFailed,
}
```

The first terminal transition wins. Store the live PID, signal attempts, and signal-delivery booleans. Await exit and stream drainage after termination.

Use `try/finally` to cancel timers and subscriptions.

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  lib/core/notifications/dart_io_linux_process_runner.dart \
  test/support/process_test_helper.dart \
  test/core/notifications/dart_io_linux_process_runner_test.dart

flutter test \
  test/core/notifications/dart_io_linux_process_runner_test.dart

flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/dart_io_linux_process_runner.dart \
  test/support/process_test_helper.dart \
  test/core/notifications/dart_io_linux_process_runner_test.dart

git commit -m "feat: terminate timed out Linux processes"
```

---

### Task 6: Validated Timer Names, Typed Status, and Strict Parser

**Files:**
- Create: `lib/core/notifications/linux_systemd_timer_name.dart`
- Create: `lib/core/notifications/linux_systemd_unit_status.dart`
- Create: `lib/core/notifications/linux_systemd_status_parser.dart`
- Create: `lib/core/notifications/linux_systemd_command_exception.dart`
- Test: `test/core/notifications/linux_systemd_timer_name_test.dart`
- Test: `test/core/notifications/linux_systemd_status_parser_test.dart`

**Interfaces:**
- Produces:

```dart
final class LinuxSystemdTimerName {
  factory LinuxSystemdTimerName.fromUnitNames(
    LinuxSystemdUnitNames names,
  );
  factory LinuxSystemdTimerName.parse(String value);
  final String value;
}

final class LinuxSystemdStatusParser {
  LinuxSystemdUnitStatus parse({
    required LinuxSystemdTimerName timer,
    required LinuxProcessResult result,
  });
}
```

- [ ] **Step 1: Write RED timer-name tests**

Accept exact renderer-generated timer names. Reject service names, uppercase hash, short or long hash, separators, traversal, whitespace, shell operators, control characters, NUL, and arbitrary system timers.

- [ ] **Step 2: Write RED status parser tests**

Cover every known enum value, unknown values with raw preservation, CRLF, blank lines, unknown keys, malformed lines, duplicate required keys, missing required keys, empty SubState, non-zero exit with valid not-found status, and contradictory output.

- [ ] **Step 3: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_timer_name_test.dart \
  test/core/notifications/linux_systemd_status_parser_test.dart
```

Expected: compile failure because name, status, and parser files are absent.

- [ ] **Step 4: Implement strict models and parser**

Map exact systemd strings to enums. Preserve raw unknown state strings in immutable diagnostics.

Require each of `LoadState`, `UnitFileState`, `ActiveState`, and `SubState` exactly once.

- [ ] **Step 5: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_systemd_timer_name.dart \
  lib/core/notifications/linux_systemd_unit_status.dart \
  lib/core/notifications/linux_systemd_status_parser.dart \
  lib/core/notifications/linux_systemd_command_exception.dart \
  test/core/notifications/linux_systemd_timer_name_test.dart \
  test/core/notifications/linux_systemd_status_parser_test.dart

flutter test \
  test/core/notifications/linux_systemd_timer_name_test.dart \
  test/core/notifications/linux_systemd_status_parser_test.dart

flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_timer_name.dart \
  lib/core/notifications/linux_systemd_unit_status.dart \
  lib/core/notifications/linux_systemd_status_parser.dart \
  lib/core/notifications/linux_systemd_command_exception.dart \
  test/core/notifications/linux_systemd_timer_name_test.dart \
  test/core/notifications/linux_systemd_status_parser_test.dart

git commit -m "feat: parse typed Linux systemd status"
```

---

### Task 7: Writer-Preferring Read/Write Lock and FIFO Keyed Mutex

**Files:**
- Create: `lib/core/notifications/linux_async_read_write_lock.dart`
- Create: `lib/core/notifications/linux_keyed_mutex.dart`
- Test: `test/core/notifications/linux_systemd_locks_test.dart`

**Interfaces:**
- Produces:

```dart
final class LinuxAsyncReadWriteLock {
  Future<T> withRead<T>(
    Future<T> Function() action, {
    LinuxCancellationToken? cancellationToken,
  });

  Future<T> withWrite<T>(
    Future<T> Function() action, {
    LinuxCancellationToken? cancellationToken,
  });
}

final class LinuxKeyedMutex<K> {
  Future<T> withLock<T>(
    K key,
    Future<T> Function() action, {
    LinuxCancellationToken? cancellationToken,
  });

  int get trackedKeyCount;
}
```

- [ ] **Step 1: Write RED fairness and cleanup tests**

Test:

- concurrent readers overlap
- writer waits for active readers
- queued writer blocks newer readers
- writers execute FIFO
- same-key actions serialize
- different keys overlap
- same-key waiters execute FIFO
- queued cancellation removes the waiter
- action exception releases lock
- tracked key count returns to zero
- fixed nesting global-read then keyed-lock does not deadlock

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_locks_test.dart
```

Expected: compile failure because lock classes are absent.

- [ ] **Step 3: Implement explicit waiter queues**

Do not build locks from a chain of Futures that cannot remove cancelled waiters. Use waiter records, FIFO queues, and `try/finally` release.

When a writer is queued, do not admit new readers.

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_async_read_write_lock.dart \
  lib/core/notifications/linux_keyed_mutex.dart \
  test/core/notifications/linux_systemd_locks_test.dart

flutter test \
  test/core/notifications/linux_systemd_locks_test.dart

flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_async_read_write_lock.dart \
  lib/core/notifications/linux_keyed_mutex.dart \
  test/core/notifications/linux_systemd_locks_test.dart

git commit -m "feat: serialize Linux systemd commands safely"
```

---

### Task 8: Daemon Reload and Machine-Readable Status Driver

**Files:**
- Create: `lib/core/notifications/linux_systemd_user_command_driver.dart`
- Test: `test/core/notifications/linux_systemd_user_command_driver_test.dart`

**Interfaces:**
- Produces:

```dart
abstract interface class LinuxSystemdUserCommandDriver {
  Future<void> reloadDaemon({
    LinuxCancellationToken? cancellationToken,
  });

  Future<LinuxSystemdUnitStatus> status(
    LinuxSystemdTimerName timer, {
    LinuxCancellationToken? cancellationToken,
  });

  Future<LinuxSystemdUnitStatus> enableAndStart(
    LinuxSystemdTimerName timer, {
    LinuxCancellationToken? cancellationToken,
  });

  Future<LinuxSystemdUnitStatus> disableAndStop(
    LinuxSystemdTimerName timer, {
    LinuxCancellationToken? cancellationToken,
  });
}
```

Production constructor defaults:

```dart
ProcessLinuxSystemdUserCommandDriver({
  required LinuxProcessRunner processRunner,
  String executable = 'systemctl',
  Duration timeout = const Duration(seconds: 15),
  Duration terminationGracePeriod = const Duration(seconds: 2),
  int stdoutLimitBytes = 256 * 1024,
  int stderrLimitBytes = 256 * 1024,
});
```

- [ ] **Step 1: Write RED command-shape tests**

Assert exact daemon reload arguments:

```dart
const <String>[
  '--user',
  '--no-pager',
  'daemon-reload',
]
```

Assert exact status arguments:

```dart
<String>[
  '--user',
  '--no-pager',
  'show',
  timer.value,
  '--property=LoadState',
  '--property=UnitFileState',
  '--property=ActiveState',
  '--property=SubState',
]
```

Assert hardened environment, executable override, timeout values, no shell string, and cancellation propagation.

- [ ] **Step 2: Write RED policy tests**

Daemon reload succeeds only on exit code zero. Status parses valid output, accepts valid not-found output, rejects incomplete output, and wraps command failures without exposing environment maps.

- [ ] **Step 3: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_user_command_driver_test.dart
```

Expected: compile failure because the driver is absent.

- [ ] **Step 4: Implement reload and status**

Use the global write lock for reload and global read lock for status.

Build each `LinuxProcessRequest` through one private factory that applies the hardened environment and immutable defaults.

Leave mutation methods throwing an internal unsupported-state exception until Task 9 tests are introduced.

- [ ] **Step 5: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_systemd_user_command_driver.dart \
  test/core/notifications/linux_systemd_user_command_driver_test.dart

flutter test \
  test/core/notifications/linux_systemd_user_command_driver_test.dart

flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_user_command_driver.dart \
  test/core/notifications/linux_systemd_user_command_driver_test.dart

git commit -m "feat: query Linux systemd user units"
```

---

### Task 9: Idempotent Mutations, Postconditions, Reconciliation, and Locking

**Files:**
- Modify: `lib/core/notifications/linux_systemd_user_command_driver.dart`
- Modify: `lib/core/notifications/linux_systemd_command_exception.dart`
- Create: `test/core/notifications/linux_systemd_user_command_mutation_test.dart`

**Interfaces:**
- `enableAndStart()` and `disableAndStop()` return final reconciled status.
- Mutation errors preserve both mutation evidence and final status.

- [ ] **Step 1: Write RED enable tests**

Cover:

- already enabled and active skips mutation
- exact `enable --now` arguments
- exit zero plus valid final status succeeds
- exit zero plus invalid final status fails
- exit non-zero plus valid final status succeeds
- timeout plus valid final status succeeds
- timeout plus invalid final status fails
- no blind retry
- exactly one post-mutation status
- `activating` is not accepted as final success
- static plus active is accepted under the documented rule

- [ ] **Step 2: Write RED disable tests**

Cover:

- not-found skips mutation
- already disabled and inactive skips mutation
- exact `disable --now` arguments
- masked plus inactive succeeds
- disabled plus failed succeeds
- active final status fails
- explicit cancellation remains cancellation without reconciliation success conversion

- [ ] **Step 3: Write RED concurrency tests at driver level**

Cover:

- same timer mutations serialize
- different timer mutations overlap
- status on independent timers overlaps
- daemon reload waits for active unit operations
- queued reload blocks later status calls
- internal status queries do not reacquire the keyed mutex
- exception releases both locks
- keyed mutex count returns to zero

- [ ] **Step 4: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_user_command_mutation_test.dart
```

Expected: behavioral failures because mutation methods are not implemented.

- [ ] **Step 5: Implement mutation scope**

Acquire global read lock then timer keyed mutex. Within that scope call a private `_statusUnlocked()` method so internal status queries do not reacquire locks.

Execute one mutation request, capture either result or failure, then perform one status reconciliation unless explicit cancellation is already terminal.

Evaluate typed postcondition predicates and throw `LinuxSystemdPostconditionException` when absent.

- [ ] **Step 6: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_systemd_user_command_driver.dart \
  lib/core/notifications/linux_systemd_command_exception.dart \
  test/core/notifications/linux_systemd_user_command_mutation_test.dart

flutter test \
  test/core/notifications/linux_systemd_user_command_mutation_test.dart

flutter test \
  test/core/notifications/linux_systemd_user_command_driver_test.dart \
  test/core/notifications/linux_systemd_user_command_mutation_test.dart

flutter analyze
```

- [ ] **Step 7: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_user_command_driver.dart \
  lib/core/notifications/linux_systemd_command_exception.dart \
  test/core/notifications/linux_systemd_user_command_mutation_test.dart

git commit -m "feat: verify Linux systemd mutation results"
```

---

### Task 10: Final Structure Audit, Evidence Checkpoint, and Design Finalization

**Files:**
- Create: `tool/verify_phase1_task10_3_structure.py`
- Create: `tool/finalize_phase1_task10_3_checkpoint.py`
- Create: `tool/verify_phase1_task10_3_complete.py`
- Create: `docs/superpowers/checkpoints/2026-07-29-linux-systemctl-user-command-driver-checkpoint.md`
- Modify: `docs/superpowers/specs/2026-07-29-linux-systemctl-user-command-driver-design.md`

**Interfaces:**
- No new runtime API.
- Completion requires fresh logs and exact test counts.

- [ ] **Step 1: Write the structure verifier**

Verify:

- every production and focused-test file exists
- `Process.start` exists
- `runInShell: false` exists
- `Process.run`, shell strings, and real-systemctl tests do not exist
- SIGTERM and SIGKILL exist
- limits are 256 KiB
- hardened environment values exist
- status uses all four required properties
- mutation postconditions and reconciliation exist
- global and keyed locks exist
- no platform scheduler wiring references the driver outside Task 10.3

- [ ] **Step 2: Run all focused Task 10.3 tests with evidence**

```bash
flutter test \
  test/core/notifications/linux_process_request_test.dart \
  test/core/notifications/linux_bounded_output_test.dart \
  test/core/notifications/linux_process_test_doubles_test.dart \
  test/core/notifications/dart_io_linux_process_runner_test.dart \
  test/core/notifications/linux_systemd_timer_name_test.dart \
  test/core/notifications/linux_systemd_status_parser_test.dart \
  test/core/notifications/linux_systemd_locks_test.dart \
  test/core/notifications/linux_systemd_user_command_driver_test.dart \
  test/core/notifications/linux_systemd_user_command_mutation_test.dart \
  2>&1 | tee /tmp/task10-3-focused.log
```

- [ ] **Step 3: Run repository verification with evidence**

```bash
python3 tool/verify_phase1_task10_3_structure.py

flutter analyze \
  2>&1 | tee /tmp/task10-3-analyze.log

flutter test \
  2>&1 | tee /tmp/task10-3-full.log

flutter build linux --debug \
  2>&1 | tee /tmp/task10-3-build.log

git diff --check
```

- [ ] **Step 4: Finalize evidence checkpoint**

```bash
python3 tool/finalize_phase1_task10_3_checkpoint.py \
  --focused-log /tmp/task10-3-focused.log \
  --analyze-log /tmp/task10-3-analyze.log \
  --full-log /tmp/task10-3-full.log \
  --build-log /tmp/task10-3-build.log

python3 tool/verify_phase1_task10_3_complete.py
```

The finalizer records actual focused and full test counts, branch, pre-checkpoint HEAD, process termination strategy, output bounds, locking semantics, and the cross-platform boundary.

Update the design status to:

```text
Status: Implemented and verified
```

- [ ] **Step 5: Commit and push**

```bash
git add -A

git commit -m "docs: verify Linux systemctl user command driver"

git push
```

---

## Review Gates

Stop for review after each commit:

1. Process request and cancellation models
2. Bounded output correctness
3. Fake and recording runners
4. Normal Dart IO process lifecycle
5. Timeout and cancellation termination
6. Timer validation and typed status parsing
7. Fair locking and keyed cleanup
8. Daemon reload and status commands
9. Mutation postconditions and reconciliation
10. Full evidence verification

Task 10.3 is complete only after Gate 10 records fresh successful evidence.
