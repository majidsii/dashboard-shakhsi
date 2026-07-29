# Linux systemctl User Command Driver — Design

Date: 2026-07-29  
Phase: 1  
Task: 10.3  
Status: Approved for implementation planning

## Objective

Build a Linux-only command driver that safely controls the current user's
systemd manager through `systemctl --user`.

The driver provides:

- daemon reload
- typed unit status inspection
- idempotent enable-and-start
- idempotent disable-and-stop
- mandatory mutation postcondition verification
- timeout, cancellation, bounded output, and process termination
- deterministic concurrency control
- test doubles that never execute a real `systemctl`

This task does not write unit files, update Drift, schedule notifications, or
change Android, iOS, macOS, or Windows behavior.

## Design priorities

Decisions in this design optimize for:

1. production safety
2. deterministic behavior
3. command-injection resistance
4. complete process cleanup
5. bounded memory usage
6. testability without systemd
7. explicit state and error models
8. long-term maintainability

Convenience and minimal code size are secondary.

## Platform boundary

The production driver is Linux-specific.

- It is not constructed by non-Linux scheduler paths.
- It never executes on Android, iOS, macOS, Windows, or web.
- Tests use injected runners and do not require a user systemd session.
- Task 10.3 does not wire the driver into the application scheduler.

## Process architecture

### LinuxProcessRunner

All process execution is hidden behind an injectable contract.

```dart
abstract interface class LinuxProcessRunner {
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  });
}
```

The contract accepts a structured executable and argument list. It never accepts
a shell command string.

### DartIoLinuxProcessRunner

Production implementation backed by `Process.start`.

Required spawn settings:

```dart
Process.start(
  request.executable,
  request.arguments,
  environment: request.environment,
  includeParentEnvironment: request.includeParentEnvironment,
  runInShell: false,
  mode: ProcessStartMode.normal,
);
```

`Process.run` is not used because timeout escalation, cancellation, PID
reporting, bounded streaming capture, and explicit signals require a live
`Process` instance.

The runner must subscribe to stdout and stderr immediately and drain both
streams through completion, including after process exit or forced termination.

### FakeLinuxProcessRunner

A deterministic test double that:

- returns queued results
- throws queued start, timeout, cancellation, and stream failures
- supports delayed completion
- exposes explicit completion controls for concurrency tests
- never accesses the real process table
- never invokes `systemctl`

### RecordingLinuxProcessRunner

A recording wrapper or test double that stores immutable copies of:

- executable
- ordered arguments
- environment overrides
- timeout
- termination grace period
- output limits
- cancellation association
- invocation order

It may delegate to a fake runner. Recorded requests must not be mutable after
the call.

## Process request

```dart
final class LinuxProcessRequest {
  LinuxProcessRequest({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required Duration timeout,
    required Duration terminationGracePeriod,
    required int stdoutLimitBytes,
    required int stderrLimitBytes,
    bool includeParentEnvironment = true,
  });
}
```

Validation requirements:

- executable is non-empty
- arguments are copied into an immutable list
- environment is copied into an immutable map
- timeout is positive
- grace period is non-negative
- each output limit is at least 2 KiB
- no NUL characters are permitted
- the runner always uses `runInShell: false`

## Executable resolution

The default executable is:

```text
systemctl
```

This allows normal Linux `PATH` resolution across distributions.

The driver constructor permits an executable override for:

- tests
- sandboxed installations
- non-standard systemd locations

The override remains a single executable string. It cannot contain arguments,
shell operators, whitespace-separated command fragments, or NUL characters.

## Hardened child environment

The child inherits the parent environment, with these overrides:

```text
LC_ALL=C
LANG=C
SYSTEMD_COLORS=0
SYSTEMD_PAGER=cat
SYSTEMD_PAGERSECURE=1
```

Every command also includes `--no-pager`.

This makes output locale-independent, disables ANSI coloring and paging, and
avoids pager subprocess behavior.

The complete inherited environment must never be included in exceptions,
records intended for application logs, or telemetry.

## Timeout and cancellation

Defaults:

```text
command timeout: 15 seconds
termination grace period: 2 seconds
```

Both values are configurable through the production constructor and immutable
after construction.

### Timeout termination sequence

1. mark the result as timed out
2. send `SIGTERM`
3. record whether signal delivery succeeded
4. wait up to the termination grace period
5. if still running, send `SIGKILL`
6. record whether signal delivery succeeded
7. wait for the process exit future
8. drain stdout and stderr to completion
9. release all subscriptions and timers
10. throw a structured timeout exception

The timeout Future must not simply abandon the running process.

### Explicit cancellation sequence

Cancellation uses the same `SIGTERM` → grace period → `SIGKILL` sequence.

A cancellation token is one-shot and idempotent:

- cancellation before spawn prevents process creation
- cancellation after spawn terminates the process
- repeated cancellation does not send repeated signal sequences
- cancellation after normal completion has no effect

Cancellation and timeout races resolve through a single atomic terminal reason.
The first terminal reason wins.

### Signal support

The driver is Linux-only and uses:

```dart
ProcessSignal.sigterm
ProcessSignal.sigkill
```

A false return from `Process.kill()` is recorded and does not itself replace
the primary timeout or cancellation reason.

## Bounded stdout and stderr

Each stream has an independent default limit of:

```text
256 KiB
```

When output does not exceed the limit, all bytes are retained.

When output exceeds the limit, retain:

```text
128 KiB prefix
+
128 KiB suffix
```

The dropped middle section is not retained.

```dart
final class LinuxBoundedOutput {
  final String text;
  final int totalBytes;
  final int retainedBytes;
  final int droppedBytes;
  final bool truncated;
  final bool malformedUtf8;
}
```

Requirements:

- byte counting occurs before decoding
- stdout and stderr are captured concurrently
- invalid UTF-8 is decoded with replacement characters
- `malformedUtf8` becomes true when strict decoding would fail
- output is immutable
- stream subscriptions are always drained
- capture memory remains bounded regardless of child output size

## Process result

```dart
final class LinuxProcessResult {
  final String executable;
  final List<String> arguments;
  final int pid;
  final int exitCode;
  final Duration duration;
  final LinuxBoundedOutput stdout;
  final LinuxBoundedOutput stderr;
}
```

A normally completed process returns a result even when its exit code is
non-zero. Command-specific policy belongs to the systemctl driver.

Start failures, timeout, cancellation, and runner infrastructure failures throw
typed exceptions.

## Unit name model

Public mutation and status APIs accept a validated timer-name type, not an
arbitrary string.

```dart
final class LinuxSystemdTimerName {
  factory LinuxSystemdTimerName.fromUnitNames(
    LinuxSystemdUnitNames names,
  );

  final String value;
}
```

The accepted value must match the Task 10.1 renderer naming contract:

```text
dashboard-shakhsi-notification-<16 lowercase hex>.timer
```

Rejected values include:

- service names
- absolute paths
- separators
- traversal segments
- shell operators
- whitespace
- NUL or control characters
- arbitrary system units

This prevents the driver from becoming a general-purpose systemctl interface.

## Public driver API

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

Production implementation:

```dart
final class ProcessLinuxSystemdUserCommandDriver
    implements LinuxSystemdUserCommandDriver
```

## Commands

### Daemon reload

```text
systemctl --user --no-pager daemon-reload
```

Success requires exit code `0`.

There is no blind retry. Timeout, cancellation, start failure, or non-zero exit
produces a typed command exception.

### Machine-readable status

```text
systemctl
  --user
  --no-pager
  show
  <timer-name>
  --property=LoadState
  --property=UnitFileState
  --property=ActiveState
  --property=SubState
```

Arguments are passed as an ordered `List<String>` with no shell.

The parser consumes `key=value` lines.

Required keys:

- `LoadState`
- `UnitFileState`
- `ActiveState`
- `SubState`

Parsing rules:

- blank lines may be ignored
- each non-blank line must contain the first `=`
- unknown keys are ignored but may be retained in diagnostic metadata
- required keys must occur exactly once
- duplicate required keys are rejected
- missing required keys are rejected
- key names are case-sensitive
- values are trimmed only for a trailing carriage return
- arbitrary control characters are rejected
- unknown state values map to typed `unknown`
- raw bounded stdout and stderr remain available in diagnostics

A complete parseable status may be returned even when `systemctl show` uses a
non-zero exit code for a legitimate not-found state. An incomplete or
contradictory response is an error.

## Typed unit status

```dart
enum SystemdLoadState {
  loaded,
  notFound,
  error,
  masked,
  stub,
  merged,
  badSetting,
  unknown,
}

enum SystemdEnablementState {
  enabled,
  enabledRuntime,
  linked,
  linkedRuntime,
  alias,
  staticUnit,
  indirect,
  generated,
  transient,
  disabled,
  masked,
  maskedRuntime,
  notFound,
  unknown,
}

enum SystemdActivityState {
  active,
  reloading,
  inactive,
  failed,
  activating,
  deactivating,
  maintenance,
  refreshing,
  unknown,
}

final class LinuxSystemdUnitStatus {
  final LinuxSystemdTimerName timer;
  final SystemdLoadState loadState;
  final SystemdEnablementState enablementState;
  final SystemdActivityState activityState;
  final String subState;
  final int exitCode;
  final Duration duration;
  final LinuxBoundedOutput stdout;
  final LinuxBoundedOutput stderr;
}
```

Unknown values are preserved through an optional raw-state field or diagnostic
map so future systemd state additions do not lose observability.

## State predicates

### Loaded

A unit is available when load state is `loaded`.

`notFound`, `error`, and `badSetting` are not loaded.

### Enabled postcondition

Enable-and-start succeeds only when:

- load state is `loaded`
- enablement is one of:
  - `enabled`
  - `enabledRuntime`
  - `linked`
  - `linkedRuntime`
  - `alias`
  - `staticUnit`, only when the timer is active and systemd reports no
    installable enablement state
- activity is:
  - `active`
  - `reloading`

`activating` is not accepted as a final state.

### Disabled postcondition

Disable-and-stop succeeds when:

- the unit is not found, or
- enablement is one of:
  - `disabled`
  - `masked`
  - `maskedRuntime`
  - `notFound`
- and activity is one of:
  - `inactive`
  - `failed`

A failed but stopped unit is accepted as disabled-and-stopped; its failure state
remains visible to the caller.

## Mutating commands

### Enable and start

Mutation command:

```text
systemctl --user --no-pager enable --now <timer-name>
```

Flow:

1. acquire concurrency locks
2. query status
3. if enabled postcondition already holds, return status
4. execute mutation once
5. query status again regardless of mutation exit code
6. if enabled postcondition holds, return reconciled status
7. otherwise throw `LinuxSystemdPostconditionException`

There is no blind mutation retry.

A timeout, cancellation, non-zero exit, or ambiguous mutation result triggers
one status reconciliation unless the caller cancellation token is already
cancelled.

Explicit caller cancellation remains cancellation even if a later status would
match. Timeout may reconcile to success because the child may have completed
after the timeout boundary but before termination.

### Disable and stop

Mutation command:

```text
systemctl --user --no-pager disable --now <timer-name>
```

Flow:

1. acquire concurrency locks
2. query status
3. if disabled postcondition already holds, return status
4. execute mutation once
5. query status again regardless of mutation exit code
6. if disabled postcondition holds, return reconciled status
7. otherwise throw `LinuxSystemdPostconditionException`

There is no blind mutation retry.

## Postcondition failure

```dart
final class LinuxSystemdPostconditionException implements Exception {
  final LinuxSystemdOperation operation;
  final LinuxProcessResult? mutationResult;
  final Object? mutationFailure;
  final LinuxSystemdUnitStatus finalStatus;
}
```

The original mutation result or failure remains attached. The final status is
the decisive evidence for postcondition failure.

## Concurrency model

The driver uses:

```text
global async read/write lock
+
per-unit keyed async mutex
```

### Lock rules

- `reloadDaemon` acquires the global write lock.
- `status` acquires the global read lock.
- `enableAndStart` and `disableAndStop` acquire:
  1. global read lock
  2. keyed mutex for the timer
- locks are released in reverse order
- all release paths use `finally`
- distinct timers may run concurrently
- operations for the same timer are serialized
- daemon reload is exclusive against every status and mutation operation
- queued cancellation removes the waiter without acquiring the lock
- keyed mutex entries are removed after the last holder and waiter leave
- fixed lock acquisition order prevents deadlock

The status calls inside a mutation reuse the already-held lock scope and must
not recursively reacquire a non-reentrant keyed mutex.

## Error model

### Runner errors

```dart
LinuxProcessStartException
LinuxProcessTimeoutException
LinuxProcessCancellationException
LinuxProcessStreamException
LinuxProcessTerminationException
```

### Driver errors

```dart
LinuxSystemdCommandException
LinuxSystemdStatusParseException
LinuxSystemdPostconditionException
LinuxSystemdUnitNameException
```

Common diagnostic fields:

- operation
- executable
- immutable arguments
- PID when available
- exit code when available
- duration
- timeout
- grace period
- bounded stdout and stderr
- SIGTERM attempted and delivered
- SIGKILL attempted and delivered
- final reconciled status when available
- original cause and stack trace

The following must not be included:

- full inherited environment
- arbitrary application secrets
- unbounded process output
- unit file contents

## Logging safety

The driver itself exposes structured results and exceptions. It does not print
to stdout or stderr.

Arguments are safe to record because the public API accepts only validated
application timer names. Even so, logging integrations should record the
structured argument list rather than reconstructing a shell command string.

## Test strategy

No automated test invokes a real `systemctl`.

### Process request tests

- immutable arguments and environment
- positive timeout validation
- output-limit validation
- NUL rejection
- executable override validation
- `runInShell: false`
- hardened environment overrides

### Bounded output tests

- exact retention below limit
- exact limit boundary
- prefix and suffix retention above limit
- dropped-byte count
- independent stdout and stderr limits
- invalid UTF-8 replacement
- malformed flag
- chunk boundaries splitting UTF-8 sequences
- very large simulated streams with bounded retained memory

### Dart IO runner tests

Use a controlled test executable or Dart helper process, never systemctl.

- normal exit
- non-zero exit
- concurrent stdout and stderr draining
- output after exit future but before stream completion
- timeout sends SIGTERM
- ignored SIGTERM escalates to SIGKILL
- cancellation before spawn
- cancellation after spawn
- timeout/cancellation race
- start failure
- stream failure
- cleanup after every failure
- immutable result

### Fake and recording runner tests

- queued results
- queued exceptions
- controlled delayed completion
- immutable request recording
- concurrent invocation order
- no real process execution

### Status parser tests

- every known load state
- every known enablement state
- every known activity state
- unknown state preservation
- missing required property
- duplicate required property
- malformed line
- unexpected key
- empty `SubState`
- CRLF output
- non-zero exit with valid not-found status
- contradictory or incomplete output

### Driver command tests

Assert exact ordered arguments for:

- daemon reload
- status
- enable-and-start
- disable-and-stop

Assert:

- executable override is honored
- hardened environment is present
- no shell command string exists
- arbitrary timer names are rejected
- only application timer names are accepted

### Idempotency and reconciliation tests

- already enabled and active skips mutation
- already disabled and inactive skips mutation
- not-found disable is success
- mutation exit zero but postcondition absent fails
- mutation exit non-zero but postcondition present succeeds
- mutation timeout but postcondition present succeeds
- mutation timeout and postcondition absent fails
- explicit cancellation remains cancellation
- no mutation retry
- one and only one post-mutation status reconciliation

### Concurrency tests

- same timer operations serialize
- different timer mutations overlap
- status on different timers overlaps
- daemon reload waits for active readers
- new readers do not starve a queued writer
- writer blocks new readers after queuing
- cancellation removes queued waiter
- exception releases every lock
- keyed mutex entries are cleaned up
- mutation-internal status does not deadlock

## Fairness

The global read/write lock is writer-preferring once a writer is queued.

This prevents a continuous stream of status calls from starving
`reloadDaemon`.

Per-unit mutex waiters are FIFO.

## Acceptance criteria

Task 10.3 is complete when:

- injectable process runner contract exists
- Dart IO runner uses `Process.start` and never uses a shell
- fake and recording runners exist
- default timeout is 15 seconds
- default termination grace period is 2 seconds
- timeout and cancellation terminate the actual process
- stdout and stderr are concurrently drained and bounded to 256 KiB each
- malformed UTF-8 is handled and reported
- child environment is hardened
- timer names are strongly validated
- status uses one machine-readable `systemctl show` query
- status values are typed
- enable and disable are idempotent
- mutation postconditions are mandatory
- ambiguous mutation outcomes are reconciled exactly once
- same-unit races are serialized
- independent units retain concurrency
- daemon reload is globally exclusive
- all locks and process resources are released on every failure path
- tests never invoke a real `systemctl`
- focused tests pass
- `flutter analyze` reports no issues
- full Flutter tests pass
- Linux debug build succeeds
- Android, iOS, macOS, and Windows behavior remains unchanged

## Deferred work

The following belong to later tasks:

- calling the Task 10.2 unit store and this driver as one scheduler transaction
- Drift scheduling state
- application startup reconciliation
- notification delivery entrypoint
- persistent recovery after process or power loss
- Linux integration smoke tests against a real user systemd session
- platform scheduler selection

## References

- Dart `Process.start` supports a structured executable and argument list,
  environment overrides, `runInShell: false`, normal process mode, and returns
  a live process for interaction.
- Dart requires stdout and stderr to be consumed to release process resources.
- Dart exposes PID, exit code, stdout, stderr, and POSIX signals through
  `Process` and `ProcessSignal`.
- systemd tools support `--no-pager`; systemd documentation recommends
  disabling or securing pager behavior for safe non-interactive execution.
