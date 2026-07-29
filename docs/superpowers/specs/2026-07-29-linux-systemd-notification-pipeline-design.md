# Linux systemd Notification Pipeline — Design

Date: 2026-07-29  
Phase: 1  
Tasks: 10.4, 10.5, 10.6  
Status: Approved architecture; ready for implementation planning

## Objective

Complete the Linux notification scheduling pipeline by adding:

1. a persistent, versioned registry of app-owned systemd schedules;
2. a production `NotificationScheduler` implementation that orchestrates the
   existing unit renderer, transactional unit store, hardened command driver,
   and registry;
3. a hidden notification-delivery application entry point and Linux-only
   scheduler wiring.

The design keeps Drift as the desired-state source of truth and treats the
registry as a bounded inventory of platform state. It preserves Android, iOS,
macOS, and Windows behavior.

## Existing foundation

The current codebase already contains:

- immutable `NotificationRequest` and `NotificationOwner` models;
- the platform-independent `NotificationScheduler` contract;
- Drift-backed desired notification schedules;
- a coordinator that persists desired state before calling the scheduler;
- deterministic systemd service/timer rendering;
- an injectable, link-aware systemd filesystem;
- transactional two-file unit installation and removal;
- a hardened `systemctl --user` process runner and typed status parser;
- mandatory mutation postconditions and one reconciliation attempt;
- writer-preferring global coordination and per-unit FIFO serialization.

Tasks 10.4–10.6 compose these pieces. They do not replace them.

## Design decisions

### Desired state and platform inventory

- Drift remains the authoritative desired schedule set.
- The Linux registry records what the application believes is installed.
- systemd unit files and `systemctl show` represent observed platform state.
- `reconcile(expected)` compares all three and repairs differences.

### No cross-resource atomicity claim

A single atomic transaction cannot span:

- two systemd unit files;
- the systemd user manager;
- the registry file;
- the Drift database.

The implementation therefore guarantees:

- in-process rollback for every observed failure;
- original-error preservation with attached rollback failures;
- deterministic restart reconciliation after process termination;
- no claim of power-loss atomicity across all resources.

### Privacy

The registry never stores:

- notification title;
- notification body;
- notification payload;
- rendered service or timer contents.

It stores only identifiers, owner identity, unit names, schedule time, schema
metadata, and a one-way request fingerprint. The registry file mode is `0600`.

### Unit command payload

systemd unit arguments contain only the schedule identifier and hidden delivery
mode, not the notification title, body, or encoded payload.

The delivery entry point resolves the complete request from the persisted
notification repository at execution time.

## File layout

The existing user-unit directory remains:

```text
$XDG_CONFIG_HOME/systemd/user
```

or:

```text
$HOME/.config/systemd/user
```

App-owned files are:

```text
dashboard-shakhsi-notification-<16 lowercase hex>.service
dashboard-shakhsi-notification-<16 lowercase hex>.timer
dashboard-shakhsi-notification-registry.json
```

Transaction-owned registry files use same-directory names:

```text
.dashboard-shakhsi-notification-registry.<transaction-id>.tmp
.dashboard-shakhsi-notification-registry.<transaction-id>.bak
```

Only exact app-owned names may be listed, replaced, quarantined, or removed.

---

# Task 10.4 — Persistent Linux Schedule Registry

## Scope

Task 10.4 adds a strict, versioned registry and the filesystem capabilities
needed to persist and inspect app-owned Linux scheduling state.

It does not call `systemctl`, render notification units, or implement
`NotificationScheduler`.

## Registry model

```dart
final class LinuxSystemdScheduleRegistry {
  const LinuxSystemdScheduleRegistry({
    required int schemaVersion,
    required int generation,
    required List<LinuxSystemdScheduleRegistryEntry> entries,
  });
}

final class LinuxSystemdScheduleRegistryEntry {
  const LinuxSystemdScheduleRegistryEntry({
    required String scheduleId,
    required NotificationOwner owner,
    required LinuxSystemdTimerName timerName,
    required String serviceFileName,
    required DateTime scheduledAtUtc,
    required String requestFingerprint,
  });
}
```

Required invariants:

- `schemaVersion` is exactly `1`;
- `generation` is a non-negative integer;
- entries are immutable and sorted by `scheduleId`;
- `scheduleId` is unique;
- timer names are unique;
- service names are unique;
- `scheduledAtUtc` is UTC;
- `requestFingerprint` is exactly 64 lowercase hexadecimal characters;
- service and timer names share the same app-generated base name;
- the timer name equals the stable name derived from `scheduleId`;
- owner type is a known `NotificationOwnerType`;
- owner ID and schedule ID use the existing validated domain models.

## JSON schema

Canonical version 1 representation:

```json
{
  "schemaVersion": 1,
  "generation": 7,
  "entries": [
    {
      "scheduleId": "task-42-reminder",
      "ownerType": "task",
      "ownerId": "task-42",
      "timerName": "dashboard-shakhsi-notification-0123456789abcdef.timer",
      "serviceFileName": "dashboard-shakhsi-notification-0123456789abcdef.service",
      "scheduledAtUtc": "2026-07-30T05:30:00.000Z",
      "requestFingerprint": "64-lowercase-hex-characters"
    }
  ]
}
```

Codec rules:

- UTF-8 only;
- exact top-level keys only;
- exact entry keys only;
- unknown keys are rejected;
- duplicate keys are rejected by the strict decoder layer;
- unsupported schema versions are rejected explicitly;
- numeric values must be JSON integers;
- timestamps must use a UTC ISO-8601 representation ending in `Z`;
- entries are encoded in ascending `scheduleId` order;
- object field ordering is deterministic;
- output ends with exactly one newline;
- blank or whitespace-only files are invalid;
- malformed UTF-8 is invalid;
- registry size is limited to 1 MiB;
- entry count is limited to 10,000.

A corrupt registry is never silently interpreted as empty.

## Request fingerprint

`LinuxNotificationRequestFingerprint` computes SHA-256 over canonical UTF-8
JSON containing:

- a fingerprint schema version;
- schedule ID;
- owner type and owner ID;
- title;
- body;
- UTC schedule timestamp;
- privacy mode;
- payload entries sorted by key;
- delivery command schema version.

The resulting lowercase hexadecimal digest is stored in the registry.

The fingerprint:

- detects request changes without storing notification content;
- lets reconciliation avoid unnecessary file replacement;
- changes when delivery-command compatibility changes;
- is deterministic across process restarts.

The existing `cryptography` package may be used. No new crypto dependency is
required.

## Filesystem contract extensions

`LinuxSystemdFileSystem` gains narrowly scoped operations:

```dart
Future<int> fileLength(String path);
Future<List<String>> listNames(String directoryPath);
```

Rules:

- `fileLength` operates only on regular files and rejects symlinks;
- `listNames` returns direct child names, not recursive paths;
- production listing does not follow symlinks;
- callers still validate every returned name;
- fake filesystem support remains deterministic and records operations.

The registry reads length before reading bytes so an oversized file is rejected
without allocating its full contents.

## Registry store contract

```dart
abstract interface class LinuxSystemdScheduleRegistryStore {
  Future<LinuxSystemdScheduleRegistry> load();
  Future<void> replace(LinuxSystemdScheduleRegistry next);
  Future<void> quarantineCorruptRegistry();
  Future<Set<LinuxSystemdUnitNames>> discoverAppUnitPairs();
}
```

A production implementation uses the existing path resolver and extended
filesystem.

### `load`

- missing registry returns an empty version-1 registry with generation `0`;
- a regular file is size-checked, read, decoded, and validated;
- symlinks, directories, and special files are rejected;
- malformed content raises a typed corruption exception;
- no automatic deletion occurs during `load`.

### `replace`

1. Validate the complete next model.
2. Increment generation from the loaded state before calling `replace`.
3. Encode canonical UTF-8 bytes.
4. Create the user-unit directory recursively.
5. Reject unsafe final, temp, or backup entry types.
6. Write the temp file with flush enabled.
7. Apply mode `0600`.
8. Rename the existing registry to backup when present.
9. Rename temp to final.
10. Re-apply mode `0600` to final.
11. Delete backup.
12. On failure, restore the previous file and attach rollback failures.

The original failure remains primary.

### `quarantineCorruptRegistry`

- validates that the registry is a regular file;
- renames it to an exact transaction-owned `.corrupt` name;
- never follows a symlink;
- never overwrites another quarantine file;
- preserves bytes for diagnosis;
- does not interpret corrupt content.

### `discoverAppUnitPairs`

- lists only direct child names;
- accepts only exact app-generated `.service` and `.timer` patterns;
- groups by the 16-character identity;
- ignores unrelated files;
- reports complete pairs and partial pairs separately;
- rejects an app-owned name that resolves to a symlink or unsafe entry;
- does not read unit contents.

Partial pairs are observable recovery data, not valid installed schedules.

## Error model

Typed failures distinguish:

- unsupported schema version;
- malformed JSON;
- malformed UTF-8;
- oversized registry;
- excessive entry count;
- duplicate schedule or unit identity;
- invalid owner or timestamp;
- invalid fingerprint;
- unsafe registry path;
- unsafe app-owned unit path;
- atomic replacement failure;
- rollback failure;
- quarantine failure;
- directory discovery failure.

Exceptions include paths and operation names, but never registry bytes or
notification content.

## Task 10.4 tests

Tests use `FakeLinuxSystemdFileSystem` only.

Required coverage:

- empty state for missing registry;
- exact canonical round trip;
- strict unknown-key rejection;
- unsupported-version rejection;
- duplicate-entry rejection;
- malformed UTF-8 and JSON rejection;
- 1 MiB boundary and oversized rejection;
- 10,000-entry boundary and overflow rejection;
- exact UTC timestamp validation;
- exact fingerprint validation;
- deterministic ordering;
- regular-file and mode checks;
- symlink rejection;
- successful atomic replacement;
- rollback from every replacement step;
- original error preserved when rollback also fails;
- corrupt registry quarantine;
- exact unit discovery;
- unrelated file ignoring;
- partial-pair reporting;
- fake and Dart IO filesystem extensions;
- no test touches the real user systemd directory.

---

# Task 10.5 — Linux systemd Notification Scheduler

## Scope

Task 10.5 implements `LinuxSystemdNotificationScheduler`, composing the current
domain, renderer, unit store, command driver, registry, clock, and an injected
delivery-command factory.

It does not select the platform implementation in application providers and
does not implement the hidden application entry point.

## New components

### LinuxNotificationDeliveryCommandFactory

```dart
abstract interface class LinuxNotificationDeliveryCommandFactory {
  LinuxSystemdNotificationUnit create(NotificationRequest request);
}
```

The factory isolates executable-path and hidden-argument construction from the
scheduler. Task 10.5 tests use a deterministic fake. Task 10.6 supplies the
production implementation.

### LinuxSystemdNotificationScheduler

```dart
final class LinuxSystemdNotificationScheduler
    implements NotificationScheduler {
  // injected dependencies
}
```

Dependencies:

- `AppClock`;
- `NativeNotificationGateway` for immediate delivery;
- `LinuxNotificationDeliveryCommandFactory`;
- `LinuxSystemdUnitRenderer`;
- transactional `LinuxSystemdUserUnitStore`;
- `LinuxSystemdUserDriver`;
- `LinuxSystemdScheduleRegistryStore`;
- `LinuxNotificationRequestFingerprint`;
- orchestration `AsyncWriterPreferringRwLock`;
- orchestration `AsyncFifoKeyedMutex<String>`.

The scheduler never invokes `dart:io` or `Process` directly.

## Store transaction extension

The existing unit store gains retained rollback transactions so scheduler-level
failures can restore the previous unit pair after file installation succeeds.

Conceptual contracts:

```dart
abstract interface class LinuxSystemdUnitInstallTransaction {
  LinuxSystemdUnitNames get names;
  Future<void> apply();
  Future<void> finalize();
  Future<void> rollback();
}

abstract interface class LinuxSystemdUnitRemoveTransaction {
  LinuxSystemdUnitNames get names;
  Future<void> apply();
  Future<void> finalize();
  Future<void> rollback();
}
```

Rules:

- `apply` performs the unit-file change but retains rollback material;
- `finalize` deletes transaction-owned backups;
- `rollback` restores the exact previous partial or complete pair;
- every method is idempotent after successful completion;
- current `install` and `remove` remain convenience wrappers around
  apply-plus-finalize;
- rollback failures are aggregated without hiding the primary scheduler error.

## Orchestration locks

Scheduler-level locking spans the complete multi-component operation.

- `schedule(scheduleId)`:
  - acquire global read;
  - acquire the schedule's keyed FIFO mutex;
  - keep both until file, systemd, registry, and finalize steps complete.

- `cancel(scheduleId)`:
  - same global-read and keyed-lock rule.

- `cancelByOwner(owner)`:
  - acquire global write for the complete batch.

- `reconcile(expected)`:
  - acquire global write for the complete reconciliation.

The scheduler locks are separate from the driver's internal defensive locks.
Production code does not expose the driver or unit store as alternate mutation
paths.

## Immediate scheduling behavior

When `scheduledAtUtc` is not after `clock.nowUtc()`:

1. cancel any stale Linux systemd state for the same `scheduleId`;
2. use `NotificationDeliveryPolicy.contentFor`;
3. encode the existing notification payload;
4. call `NativeNotificationGateway.showNow`;
5. do not create a timer or registry entry.

This matches current platform scheduler semantics for due requests.

## Future schedule flow

For a future request:

1. Validate and fingerprint the request.
2. Derive stable unit names from `scheduleId`.
3. Load the registry.
4. If the matching entry has the same fingerprint:
   - query typed status;
   - return when the timer is healthy;
   - otherwise continue with repair.
5. Create the delivery command and render units.
6. Begin a retained unit-install transaction.
7. Apply the unit transaction.
8. Run `daemon-reload`.
9. Run `enable --now` and require the existing typed postcondition.
10. Atomically replace the registry with the new entry.
11. Finalize the unit transaction.
12. Return.

A successful method guarantees:

- matching service and timer files exist;
- systemd reports the timer installed, enabled, and active;
- the registry contains the matching fingerprint and owner metadata.

## Schedule rollback

When any step after unit application fails:

1. preserve the primary failure and stack trace;
2. best-effort `disable --now` for the new timer when systemd may have observed
   it;
3. rollback the unit transaction;
4. run `daemon-reload` after restoration;
5. when a previous registry entry existed, restore its registry snapshot;
6. when the previous timer was expected to be active, best-effort re-enable it;
7. attach every rollback failure;
8. rethrow a typed scheduler transaction exception.

Explicit process cancellation remains cancellation as the primary failure.
Rollback still runs where needed, but cancellation is not converted into a
generic scheduling error.

## Cancel flow

For `cancel(scheduleId)`:

1. derive stable unit names without requiring a registry entry;
2. load the registry;
3. begin a retained unit-removal transaction;
4. call `disable --now`;
5. apply unit removal;
6. run `daemon-reload`;
7. atomically remove the registry entry when present;
8. finalize the removal transaction.

Cancellation is idempotent:

- missing registry entry is allowed;
- missing unit files are allowed;
- already-disabled or not-found timer state is normalized to success only when
  typed command/status evidence confirms the desired disabled state.

## Cancel rollback

If failure occurs after removal begins:

1. restore removed files;
2. reload the daemon;
3. restore the previous registry snapshot;
4. re-enable the timer when the previous registry indicated an installed
   schedule;
5. attach rollback failures to the original error.

## `cancelByOwner`

Under the global write lock:

1. load the registry;
2. select entries whose owner exactly equals the requested owner;
3. cancel them in deterministic `scheduleId` order using internal unlocked
   operations;
4. continue only while prior cancellations succeed;
5. report the failing schedule and preserve already-completed cancellations.

The operation is idempotent when no entries match.

A corrupt registry raises a typed error. The scheduler must not guess owner
membership from unit names.

## Reconciliation

`reconcile(expected)` is deterministic and fail-closed.

### Normalize desired state

- deduplicate by `scheduleId`, last value wins;
- sort by `scheduleId`;
- discard past or due requests from the future desired set;
- never show immediate notifications during startup reconciliation.

### Load and recover inventory

- load the registry;
- discover exact app-owned unit pairs and partial pairs;
- if registry corruption is detected:
  - quarantine the corrupt file;
  - treat the registry as empty;
  - remove all exact app-owned discovered units;
  - reload systemd;
  - rebuild from desired future requests.

Only exact app-prefixed validated unit names are affected.

### Remove stale state

Remove:

- registry entries absent from desired future requests;
- discovered pairs absent from both registry and desired state;
- partial pairs;
- entries whose stable unit names do not match the schedule ID.

### Repair desired state

For each desired request in sorted order:

- compute fingerprint;
- if registry fingerprint matches, verify typed status;
- leave healthy entries unchanged;
- reinstall and re-enable unhealthy or changed entries;
- create missing entries.

### Batch reload behavior

Reconciliation minimizes daemon reloads:

- file removals and installations are staged first where rollback boundaries
  allow;
- one reload is preferred per coherent batch;
- typed enable/disable postconditions remain mandatory;
- correctness takes priority over minimizing reload count.

### Reconciliation result

The final registry is exactly the desired future schedule set whose systemd
postconditions succeeded.

If one item fails:

- preserve already-reconciled successful items;
- retain precise failing item context;
- write a registry matching the platform state actually confirmed;
- throw a typed partial-reconciliation exception.

## Scheduler error model

Typed failures include:

- registry corruption;
- unit render or validation failure;
- unit transaction failure;
- daemon reload failure;
- mutation or postcondition failure;
- registry update failure;
- rollback failure;
- partial owner cancellation;
- partial reconciliation.

Errors include:

- operation;
- schedule ID when applicable;
- owner when applicable;
- unit names;
- primary cause and stack trace;
- rollback failures;
- confirmed final status when available.

They never include title, body, payload, rendered unit contents, or raw registry
bytes.

## Task 10.5 tests

All scheduler tests use fake filesystem, fake registry, fake process runner,
fake gateway, and fixed clock.

Required coverage:

- future schedule happy path and exact operation order;
- due request immediate delivery without timer creation;
- idempotent healthy same-fingerprint schedule;
- changed fingerprint replacement;
- unhealthy same-fingerprint repair;
- failure at every schedule step;
- exact rollback to missing, partial, and complete prior unit pairs;
- previous timer re-enabled after rollback;
- cancellation remains the primary error;
- idempotent cancel with no state;
- cancel happy path and failure at every step;
- cancelByOwner exact matching and deterministic order;
- same-ID FIFO serialization;
- different-ID concurrency;
- reconcile deduplication and sorting;
- stale registry removal;
- orphan pair removal;
- partial-pair removal;
- corrupt-registry quarantine and rebuild;
- healthy entry preservation;
- changed and unhealthy entry repair;
- past request cleanup without immediate delivery;
- partial reconciliation reporting;
- no real filesystem, process, or user systemd access.

---

# Task 10.6 — Delivery Entrypoint and Platform Wiring

## Scope

Task 10.6 supplies the production delivery command, hidden application mode,
and Linux-only scheduler selection.

It does not change Android, iOS, macOS, or Windows scheduling behavior.

## Hidden command

The Linux service executes the application directly:

```text
<absolute-executable> --deliver-notification <schedule-id>
```

Rules:

- no shell;
- exactly two hidden-mode arguments;
- schedule ID is passed as one quoted argument;
- title, body, payload, and owner data are not present in the unit file;
- unexpected, missing, repeated, or control-character arguments are rejected;
- normal application startup remains unchanged when the hidden flag is absent.

## Executable path

The production command factory receives an injected executable-path source.

On Linux production wiring, it uses the resolved application executable and
requires:

- an absolute path;
- no NUL or line breaks;
- a regular executable file when platform verification is available.

Tests inject a deterministic path.

## Delivery flow

Before UI bootstrap, hidden mode:

1. parse and validate the exact command;
2. initialize only the minimum required Flutter/plugin/database services;
3. load the request by `scheduleId` from
   `NotificationScheduleRepository.getById`;
4. when the request is missing, exit successfully without displaying;
5. apply `NotificationDeliveryPolicy.contentFor`;
6. encode the existing navigation payload;
7. call `NativeNotificationGateway.showNow`;
8. close initialized resources;
9. return a typed exit result.

A missing request is a benign stale timer, not a fatal error.

The hidden command does not open the dashboard window or initialize routing.

## Repository extension

`NotificationScheduleRepository` gains:

```dart
Future<NotificationRequest?> getById(String scheduleId);
```

Drift, memory, and test implementations provide exact behavior.

## Post-delivery cleanup

The hidden delivery process does not mutate Drift desired state.

Reason:

- the domain layer owns whether a request is one-shot or recurring;
- existing native delivery also does not delete desired state;
- startup reconciliation already removes past Linux timers;
- deleting Drift state inside delivery would violate coordinator ownership.

Best-effort unit cleanup may be deferred to the next normal reconciliation.
No notification is shown twice by the same single systemd timer activation.

## Platform selection

The production provider chooses:

- Linux:
  `LinuxSystemdNotificationScheduler`;
- Android, iOS, macOS, Windows:
  existing `PlatformNotificationScheduler` or existing no-op behavior according
  to current capabilities.

Selection depends on the existing injected host-platform abstraction, not
direct `Platform.isLinux` checks in domain code.

Non-Linux tests verify that:

- no systemd path is resolved;
- no registry is loaded;
- no Linux filesystem object is created;
- existing scheduler behavior is unchanged.

## Startup reconciliation

Normal Linux startup:

1. initializes notification infrastructure;
2. loads expected schedules from Drift through the existing coordinator;
3. calls `reconcileFromPersistence`;
4. reports typed reconciliation failures without blocking the main UI forever;
5. preserves retryability on the next startup or explicit schedule change.

Only one startup reconciliation runs at a time.

## Delivery and startup error handling

- malformed hidden arguments return a non-zero typed result;
- database initialization failure returns non-zero;
- missing request returns zero;
- notification display failure returns non-zero;
- resource-close failures are attached without hiding the primary error;
- no exception prints notification content or payload;
- normal UI startup errors remain governed by existing bootstrap behavior.

## Task 10.6 tests

Required coverage:

- exact hidden argument parsing;
- malformed and extra argument rejection;
- absolute executable-path validation;
- delivery request lookup;
- missing request no-op;
- privacy-mode content mapping;
- payload/navigation preservation;
- display failure;
- resource cleanup;
- no dashboard bootstrap in hidden mode;
- Linux scheduler selection;
- non-Linux existing scheduler selection;
- Linux startup reconciliation;
- reconciliation failure does not create duplicate startup work;
- repository `getById` for Drift and memory implementations;
- Linux debug build smoke test with injected fake dependencies.

---

# Cross-task verification

Tasks 10.4–10.6 are complete only when:

- all RED tests fail for the intended missing behavior;
- all focused tests pass;
- `flutter analyze` reports no issues;
- the complete Flutter test suite passes;
- Linux debug build succeeds;
- `git diff --check` is clean;
- no automated test invokes a real `systemctl`;
- no automated test writes to the real systemd user directory;
- registry permissions are `0600`;
- unit permissions remain `0644`;
- existing Android, iOS, macOS, and Windows behavior remains unchanged;
- exceptions and logs do not leak notification content;
- design and implementation checkpoints document the remaining durability
  boundary.

## Remaining durability boundary

The design provides:

- atomic same-directory replacement for individual file transactions;
- in-process rollback across scheduler steps;
- deterministic restart reconciliation.

It does not guarantee that every write survives sudden power loss unless the
underlying operating system and filesystem persist flushed data and renames.
A future hardening task may add explicit file and directory synchronization
through a narrower POSIX durability adapter if required by product risk.

## Implementation order

1. Task 10.4 registry models, codec, filesystem extensions, store, and tests.
2. Task 10.5 retained unit transactions and scheduler orchestration.
3. Task 10.6 repository lookup, hidden delivery mode, providers, and startup
   reconciliation.
4. Final integrated checkpoint covering the complete Linux notification
   lifecycle with fake dependencies.
