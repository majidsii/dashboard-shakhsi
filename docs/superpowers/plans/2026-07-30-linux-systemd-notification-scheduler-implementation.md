# Linux systemd Notification Scheduler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a production-grade Linux `NotificationScheduler` that delivers due reminders immediately, manages future reminders through systemd user timers, maintains the Task 10.4 registry, and restores confirmed prior platform state on failure.

**Architecture:** Extend the current Linux unit store with retained install and remove transactions, then compose those transactions with the existing renderer, systemd command driver, registry store, gateway, clock, fingerprint service, and orchestration locks. The scheduler holds global/keyed locks across complete cross-component operations, uses typed systemd status as the only health evidence, updates the registry only for confirmed platform state, and performs best-effort rollback without hiding the primary failure.

**Tech Stack:** Dart 3.12+, Flutter test, existing `AppClock`, `NativeNotificationGateway`, `LinuxSystemdUnitRenderer`, `LinuxSystemdUserUnitStore`, `LinuxSystemdUserDriver`, `LinuxSystemdScheduleRegistryStore`, `LinuxNotificationRequestFingerprint`, `AsyncWriterPreferringRwLock`, `AsyncFifoKeyedMutex<String>`, and injected fakes.

## Global Constraints

- Implement only Task 10.5 from `docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md`.
- Do not add application-provider selection or the hidden delivery entry point; those belong to Task 10.6.
- The scheduler never imports `dart:io`, starts `Process`, invokes a shell, or calls `systemctl` directly.
- Use `LinuxSystemdUserDriver` for every daemon reload, status query, enable/start, and disable/stop operation.
- Use typed `LinuxSystemdTimerStatus`; do not parse command output in the scheduler.
- Drift remains desired state. The Task 10.4 registry remains confirmed Linux platform inventory.
- Every registry replacement increments generation by exactly one.
- Rollback restores the previous registry **entries** with a new monotonically increasing generation; generation never decreases.
- Due or past `schedule()` requests first remove stale Linux state, then use `NotificationDeliveryPolicy.contentFor`, `NotificationPayloadCodec.encode`, and `NativeNotificationGateway.showNow`.
- `reconcile()` never immediately delivers due or past notifications.
- Stable unit names always derive from `LinuxSystemdUnitNames.forScheduleKey(scheduleId)`.
- Future scheduling success requires matching unit files, a healthy typed timer status, and a matching registry entry.
- A healthy timer means installed, enabled, active, waiting, and successful.
- Unit-file changes use retained transactions. `apply()` keeps rollback material, `finalize()` deletes transaction-owned rollback material, and `rollback()` restores the exact previous partial or complete pair.
- Transaction `apply`, `finalize`, and `rollback` are idempotent after successful completion.
- Current `install()` and `remove()` remain convenience wrappers.
- The original scheduler failure remains primary. Rollback failures are attached in encounter order.
- No cross-resource power-loss atomicity is claimed across unit files, the registry, the systemd user manager, and Drift; Task 10.5 guarantees only in-process rollback plus deterministic reconciliation.
- A `LinuxProcessCancellationException` is rethrown unchanged when rollback succeeds. When rollback itself fails, a typed scheduler exception retains the cancellation object as its primary cause.
- `schedule(scheduleId)` and `cancel(scheduleId)` hold a global read lock plus the keyed FIFO mutex for the full operation.
- `cancelByOwner(owner)` and `reconcile(expected)` hold the global write lock for the full batch.
- `cancelByOwner` uses exact `NotificationOwner` equality and deterministic `scheduleId` ordering.
- `reconcile` deduplicates desired requests by `scheduleId` with last value winning, then sorts by `scheduleId`.
- Registry corruption during reconciliation is quarantined; exact discovered app-owned units are removed; unrelated files are untouched.
- Scheduler errors and verifier output never include title, body, payload, rendered unit contents, or raw registry bytes.
- Tests never access the real HOME, real XDG systemd directory, real notification plugin, or real systemd user manager.
- Follow RED → observe the expected failure → GREEN → focused tests → `flutter analyze` → full `flutter test` → Linux debug build → `git diff --check` → commit → push.
- Remove each RED-only verifier before its Gate commit and retain the GREEN verifier.
- Task 10.5 uses eleven review Gates and eleven commits.

## Implementation Clarifications

### Testability boundary

Add a narrow unit-store interface while retaining the concrete production name:

```dart
abstract interface class LinuxSystemdUnitStore {
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  );

  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  );

  Future<void> install(LinuxSystemdRenderedUnits units);

  Future<void> remove(LinuxSystemdUnitNames names);
}

final class LinuxSystemdUserUnitStore implements LinuxSystemdUnitStore {
  // Existing production filesystem implementation.
}
```

Scheduler tests inject a fake `LinuxSystemdUnitStore`. Unit-store transaction tests continue to use the production store with `FakeLinuxSystemdFileSystem`.

### Monotonic logical registry restoration

`LinuxSystemdScheduleRegistryStore.replace()` requires `next.generation == current.generation + 1`. Scheduler rollback therefore restores prior entries using the current generation plus one:

```dart
LinuxSystemdScheduleRegistry logicalRestore({
  required LinuxSystemdScheduleRegistry current,
  required LinuxSystemdScheduleRegistry previous,
}) {
  return LinuxSystemdScheduleRegistry(
    schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
    generation: current.generation + 1,
    entries: previous.entries,
  );
}
```

This restores confirmed prior inventory without violating the monotonic generation contract.

### Cancellation rule

When the primary failure is `LinuxProcessCancellationException`:

- run every required rollback step;
- when rollback succeeds, rethrow the original cancellation with its original stack trace;
- when rollback has failures, throw `LinuxSystemdNotificationSchedulerException` with:
  - `failure == rollbackFailed`;
  - `cause` equal to the original cancellation object;
  - all rollback failures attached in order.

---

## File Map

### New production files

- `lib/core/notifications/linux_systemd_unit_transaction.dart`
  - unit-store interface, retained install/remove transaction interfaces, lifecycle state
- `lib/core/notifications/linux_notification_delivery_command_factory.dart`
  - Task 10.5 delivery-command abstraction
- `lib/core/notifications/linux_systemd_notification_scheduler_exception.dart`
  - operation/failure enums, primary cause, confirmed status, partial progress, rollback failures
- `lib/core/notifications/linux_systemd_notification_scheduler.dart`
  - immediate delivery, future schedule, cancel, owner batch, reconciliation, locks, rollback

### Modified production files

- `lib/core/notifications/linux_systemd_user_unit_store.dart`
  - implement `LinuxSystemdUnitStore`, retained install/remove transactions, convenience wrappers
- `lib/core/notifications/linux_systemd_user_unit_store_exception.dart`
  - transaction lifecycle operations and safe state failures
- `docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md`
  - mark Task 10.5 implemented only in Gate 10.5.11

### New test support

- `test/support/fake_linux_systemd_unit_store.dart`
- `test/support/fake_linux_systemd_schedule_registry_store.dart`
- `test/support/fake_linux_notification_delivery_command_factory.dart`
- `test/support/recording_native_notification_gateway.dart`
- `test/support/controlled_linux_process_runner.dart`

Existing test support may be reused where its API already satisfies these responsibilities. Do not duplicate an equivalent fake.

### New tests

- `test/core/notifications/linux_systemd_unit_transaction_model_test.dart`
- `test/core/notifications/linux_systemd_user_unit_install_transaction_test.dart`
- `test/core/notifications/linux_systemd_user_unit_remove_transaction_test.dart`
- `test/core/notifications/linux_systemd_notification_scheduler_model_test.dart`
- `test/core/notifications/linux_systemd_notification_scheduler_schedule_test.dart`
- `test/core/notifications/linux_systemd_notification_scheduler_schedule_rollback_test.dart`
- `test/core/notifications/linux_systemd_notification_scheduler_cancel_test.dart`
- `test/core/notifications/linux_systemd_notification_scheduler_concurrency_test.dart`
- `test/core/notifications/linux_systemd_notification_scheduler_reconcile_inventory_test.dart`
- `test/core/notifications/linux_systemd_notification_scheduler_reconcile_repair_test.dart`
- `test/core/notifications/linux_systemd_notification_scheduler_final_checkpoint_test.dart`

### Documentation

- Create `docs/superpowers/checkpoints/2026-07-30-linux-systemd-notification-scheduler-checkpoint.md`
- Update Task 10.5 status in the shared design only after Gate 10.5.11 passes

---

# Gate 10.5.1 — Retained Unit Transaction Contracts

**Files:**
- Create: `lib/core/notifications/linux_systemd_unit_transaction.dart`
- Modify: `lib/core/notifications/linux_systemd_user_unit_store_exception.dart`
- Test: `test/core/notifications/linux_systemd_unit_transaction_model_test.dart`
- Create: `tool/verify_phase1_task10_5_1_green.py`

**Interfaces:**

```dart
enum LinuxSystemdUnitTransactionState {
  pending,
  applied,
  finalized,
  rolledBack,
}

abstract interface class LinuxSystemdUnitInstallTransaction {
  LinuxSystemdUnitNames get names;
  LinuxSystemdUnitTransactionState get state;

  Future<void> apply();
  Future<void> finalize();
  Future<void> rollback();
}

abstract interface class LinuxSystemdUnitRemoveTransaction {
  LinuxSystemdUnitNames get names;
  LinuxSystemdUnitTransactionState get state;

  Future<void> apply();
  Future<void> finalize();
  Future<void> rollback();
}

abstract interface class LinuxSystemdUnitStore {
  Future<LinuxSystemdUnitInstallTransaction> beginInstall(
    LinuxSystemdRenderedUnits units,
  );

  Future<LinuxSystemdUnitRemoveTransaction> beginRemove(
    LinuxSystemdUnitNames names,
  );

  Future<void> install(LinuxSystemdRenderedUnits units);
  Future<void> remove(LinuxSystemdUnitNames names);
}
```

Extend the store operation enum:

```dart
enum LinuxSystemdUserUnitStoreOperation {
  beginInstall,
  beginRemove,
  applyInstall,
  finalizeInstall,
  rollbackInstall,
  applyRemove,
  finalizeRemove,
  rollbackRemove,
}
```

Add a non-sensitive lifecycle failure:

```dart
enum LinuxSystemdUserUnitTransactionFailure {
  invalidState,
  filesystemFailure,
}
```

- [ ] **Step 1: Write RED model and contract tests**

The RED tests instantiate deterministic fake transactions and verify:

```dart
expect(transaction.state, LinuxSystemdUnitTransactionState.pending);
await transaction.apply();
expect(transaction.state, LinuxSystemdUnitTransactionState.applied);
await transaction.apply();
expect(transaction.applyCalls, 1);

await transaction.finalize();
await transaction.finalize();
expect(transaction.state, LinuxSystemdUnitTransactionState.finalized);
expect(transaction.finalizeCalls, 1);
```

Also verify install/remove interfaces expose matching stable names and that exception `toString()` contains operation and file names but never nested cause text.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test test/core/notifications/linux_systemd_unit_transaction_model_test.dart" \
  /tmp/task10-5-1-red.log
```

Expected: compilation failure because `linux_systemd_unit_transaction.dart` and the new operations do not exist.

- [ ] **Step 3: Implement only contracts and safe models**

Do not modify filesystem behavior in this Gate. Keep transaction interfaces free of title, body, payload, rendered text, and raw bytes.

- [ ] **Step 4: Run GREEN and project verification**

```bash
python3 tool/verify_phase1_task10_5_1_green.py
script -qefc \
  "flutter --color test test/core/notifications/linux_systemd_unit_transaction_model_test.dart" \
  /tmp/task10-5-1-green.log
flutter analyze
script -qefc "flutter --color test" /tmp/task10-5-1-full.log
flutter build linux --debug
git diff --check
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_unit_transaction.dart \
  lib/core/notifications/linux_systemd_user_unit_store_exception.dart \
  test/core/notifications/linux_systemd_unit_transaction_model_test.dart \
  tool/verify_phase1_task10_5_1_green.py
git commit -m "feat: define retained systemd unit transactions"
```

---

# Gate 10.5.2 — Retained Install Transaction

**Files:**
- Modify: `lib/core/notifications/linux_systemd_user_unit_store.dart`
- Test: `test/core/notifications/linux_systemd_user_unit_install_transaction_test.dart`
- Create: `tool/verify_phase1_task10_5_2_green.py`

**Behavior:**

`beginInstall()` validates names, transaction ID, directory, final paths, temp paths, and backup paths, then returns a pending transaction without mutating unit files.

`apply()`:

1. creates the directory;
2. snapshots existing service and timer bytes/modes;
3. writes and chmods both temp files to `0644`;
4. moves existing files to retained backups;
5. publishes both new files;
6. chmods both final files to `0644`;
7. leaves backups intact.

`finalize()` deletes retained backups and transaction artifacts.

`rollback()`:

1. deletes newly published timer then service;
2. restores prior service then timer from backup;
3. falls back to exact snapshot bytes/mode if backup rename fails;
4. deletes remaining temp/backup artifacts;
5. aggregates failures in encounter order.

- [ ] **Step 1: Write RED tests**

Cover missing, service-only, timer-only, and complete prior pairs. The happy-path assertion for a complete pair must verify:

```dart
final transaction = await store.beginInstall(renderedUnits);
expect(transaction.state, LinuxSystemdUnitTransactionState.pending);

await transaction.apply();

expect(fileSystem.textOf(servicePath), renderedUnits.serviceContents);
expect(fileSystem.textOf(timerPath), renderedUnits.timerContents);
expect(fileSystem.containsPath(serviceBackupPath), isTrue);
expect(fileSystem.containsPath(timerBackupPath), isTrue);

await transaction.finalize();

expect(fileSystem.containsPath(serviceBackupPath), isFalse);
expect(fileSystem.containsPath(timerBackupPath), isFalse);
expect(transaction.state, LinuxSystemdUnitTransactionState.finalized);
```

Write failure-injection tests for every apply and finalize filesystem step. Verify exact previous partial/complete pair restoration and idempotence.

- [ ] **Step 2: Run RED**

Expected: `LinuxSystemdUserUnitStore` does not implement `LinuxSystemdUnitStore.beginInstall`.

- [ ] **Step 3: Refactor current install logic into a retained transaction**

`install()` becomes:

```dart
Future<void> install(LinuxSystemdRenderedUnits units) async {
  final transaction = await beginInstall(units);
  try {
    await transaction.apply();
    await transaction.finalize();
  } catch (error, stackTrace) {
    final rollbackFailures = await _rollbackAndCollect(transaction);
    throw _storeException(
      operation: LinuxSystemdUserUnitStoreOperation.applyInstall,
      error: error,
      stackTrace: stackTrace,
      rollbackFailures: rollbackFailures,
    );
  }
}
```

Do not delete backups inside `apply()`.

- [ ] **Step 4: Run GREEN plus existing install/rollback suites**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_systemd_user_unit_install_transaction_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart" \
  /tmp/task10-5-2-focused.log
```

Then run full verification.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_user_unit_store.dart \
  test/core/notifications/linux_systemd_user_unit_install_transaction_test.dart \
  tool/verify_phase1_task10_5_2_green.py
git commit -m "feat: retain Linux unit install rollback state"
```

---

# Gate 10.5.3 — Retained Remove Transaction

**Files:**
- Modify: `lib/core/notifications/linux_systemd_user_unit_store.dart`
- Test: `test/core/notifications/linux_systemd_user_unit_remove_transaction_test.dart`
- Create: `tool/verify_phase1_task10_5_3_green.py`

**Behavior:**

`beginRemove()` validates stable names and snapshots the current exact pair without deleting anything.

`apply()` deletes timer first and service second. Missing files are valid.

`finalize()` releases in-memory snapshots and becomes idempotent.

`rollback()` restores each previously existing file with exact bytes and mode. A previously missing half remains missing.

- [ ] **Step 1: Write RED tests**

Cover missing, service-only, timer-only, and complete pairs:

```dart
final transaction = await store.beginRemove(names);
await transaction.apply();

expect(fileSystem.containsPath(timerPath), isFalse);
expect(fileSystem.containsPath(servicePath), isFalse);

await transaction.rollback();

expect(fileSystem.bytesOf(servicePath), previousServiceBytes);
expect(fileSystem.modeOf(servicePath), previousServiceMode);
expect(fileSystem.bytesOf(timerPath), previousTimerBytes);
expect(fileSystem.modeOf(timerPath), previousTimerMode);
```

Inject failures at timer delete, service delete, snapshot write, and mode restoration. Verify primary error preservation and ordered rollback failures.

- [ ] **Step 2: Run RED**

Expected: missing `beginRemove()` and retained remove transaction.

- [ ] **Step 3: Implement remove transaction and wrapper**

`remove()` uses `beginRemove → apply → finalize`, rolling back on any failure after apply begins.

- [ ] **Step 4: Run GREEN plus existing remove tests and full verification**

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_user_unit_store.dart \
  test/core/notifications/linux_systemd_user_unit_remove_transaction_test.dart \
  tool/verify_phase1_task10_5_3_green.py
git commit -m "feat: retain Linux unit removal snapshots"
```

---

# Gate 10.5.4 — Delivery Factory and Scheduler Error Model

**Files:**
- Create: `lib/core/notifications/linux_notification_delivery_command_factory.dart`
- Create: `lib/core/notifications/linux_systemd_notification_scheduler_exception.dart`
- Create: `test/support/fake_linux_notification_delivery_command_factory.dart`
- Test: `test/core/notifications/linux_systemd_notification_scheduler_model_test.dart`
- Create: `tool/verify_phase1_task10_5_4_green.py`

**Interfaces:**

```dart
abstract interface class LinuxNotificationDeliveryCommandFactory {
  LinuxSystemdNotificationUnit create(NotificationRequest request);
}
```

```dart
enum LinuxSystemdNotificationSchedulerOperation {
  schedule,
  cancel,
  cancelByOwner,
  reconcile,
}

enum LinuxSystemdNotificationSchedulerFailure {
  commandFactoryFailed,
  renderFailed,
  unitTransactionFailed,
  daemonReloadFailed,
  mutationFailed,
  registryFailed,
  rollbackFailed,
  partialOwnerCancellation,
  partialReconciliation,
}
```

```dart
final class LinuxSystemdSchedulerRollbackFailure {
  const LinuxSystemdSchedulerRollbackFailure({
    required String step,
    required Object error,
    required StackTrace stackTrace,
  });
}
```

```dart
final class LinuxSystemdNotificationSchedulerException
    implements Exception {
  factory LinuxSystemdNotificationSchedulerException({
    required LinuxSystemdNotificationSchedulerOperation operation,
    required LinuxSystemdNotificationSchedulerFailure failure,
    String? scheduleId,
    NotificationOwner? owner,
    LinuxSystemdUnitNames? names,
    Object? cause,
    StackTrace? causeStackTrace,
    List<LinuxSystemdSchedulerRollbackFailure> rollbackFailures =
        const <LinuxSystemdSchedulerRollbackFailure>[],
    LinuxSystemdTimerStatus? confirmedStatus,
    Iterable<String> completedScheduleIds = const <String>[],
  });
}
```

- [ ] **Step 1: Write RED tests**

Verify immutable rollback/completed lists, exact operation/failure metadata, equality-independent owner retention, and safe `toString()`:

```dart
expect(error.toString(), contains('operation=schedule'));
expect(error.toString(), contains('failure=registryFailed'));
expect(error.toString(), contains('scheduleId=task-42-reminder'));
expect(error.toString(), isNot(contains('TOP_SECRET_CAUSE')));
expect(error.toString(), isNot(contains('notification body')));
```

- [ ] **Step 2: Run RED**

Expected: missing factory and scheduler exception files.

- [ ] **Step 3: Implement models only**

No scheduler orchestration in this Gate.

- [ ] **Step 4: Run GREEN and full verification**

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_notification_delivery_command_factory.dart \
  lib/core/notifications/linux_systemd_notification_scheduler_exception.dart \
  test/support/fake_linux_notification_delivery_command_factory.dart \
  test/core/notifications/linux_systemd_notification_scheduler_model_test.dart \
  tool/verify_phase1_task10_5_4_green.py
git commit -m "feat: define Linux scheduler contracts"
```

---

# Gate 10.5.5 — Immediate and Future Schedule Flow

**Files:**
- Create: `lib/core/notifications/linux_systemd_notification_scheduler.dart`
- Create or extend: `test/support/fake_linux_systemd_unit_store.dart`
- Create or extend: `test/support/fake_linux_systemd_schedule_registry_store.dart`
- Create or extend: `test/support/recording_native_notification_gateway.dart`
- Create or extend: `test/support/controlled_linux_process_runner.dart`
- Test: `test/core/notifications/linux_systemd_notification_scheduler_schedule_test.dart`
- Create: `tool/verify_phase1_task10_5_5_green.py`

**Constructor:**

```dart
final class LinuxSystemdNotificationScheduler
    implements NotificationScheduler {
  LinuxSystemdNotificationScheduler({
    required AppClock clock,
    required NativeNotificationGateway gateway,
    required LinuxNotificationDeliveryCommandFactory commandFactory,
    required LinuxSystemdUnitRenderer renderer,
    required LinuxSystemdUnitStore unitStore,
    required LinuxSystemdUserDriver driver,
    required LinuxSystemdScheduleRegistryStore registryStore,
    required LinuxNotificationRequestFingerprint fingerprint,
    AsyncWriterPreferringRwLock? globalLock,
    AsyncFifoKeyedMutex<String>? scheduleMutex,
  });
}
```

**Due flow:**

```dart
if (!request.scheduledAtUtc.isAfter(clock.nowUtc().toUtc())) {
  await _cancelUnlocked(request.scheduleId);
  final content = NotificationDeliveryPolicy.contentFor(request);
  await gateway.showNow(
    id: StableNotificationId.fromScheduleId(request.scheduleId),
    title: content.title,
    body: content.body,
    payload: NotificationPayloadCodec.encode(request),
  );
  return;
}
```

**Future flow order:**

```text
fingerprint
derive names
load registry
optional healthy same-fingerprint status check
command factory
render
begin install
apply
daemon reload
enable and start
replace registry
finalize
```

- [ ] **Step 1: Write RED tests**

Required cases:

1. future happy path with exact component-operation order;
2. due request removes stale state before `showNow`;
3. due request uses privacy content and encoded payload;
4. same fingerprint plus healthy status performs no render/install/reload/registry write;
5. same fingerprint plus unhealthy status repairs;
6. changed fingerprint replaces;
7. first future schedule creates generation one;
8. successful registry entry contains owner, UTC time, stable names, and fingerprint.

- [ ] **Step 2: Run RED**

Expected: `LinuxSystemdNotificationScheduler` missing.

- [ ] **Step 3: Implement schedule only**

`cancel`, `cancelByOwner`, and `reconcile` may throw `UnimplementedError` only during RED construction, but the GREEN verifier forbids placeholders. Before committing Gate 10.5.5, implement private cancellation support required by due scheduling and make public unsupported methods return typed `UnsupportedError` only if tests prove the temporary behavior. Prefer implementing public `cancel` in Gate 10.5.7 without committing placeholder code by keeping Gate 10.5.5 on a feature branch patch package that includes only tested public schedule behavior and private helpers.

Concrete rule for this project: the Gate 10.5.5 GREEN file must compile all `NotificationScheduler` methods. Use minimal safe no-op implementations for `cancelByOwner` and `reconcile` only when their inputs are empty; otherwise throw a typed scheduler exception with `failure == partialOwnerCancellation` or `partialReconciliation`. Gate 10.5.8 and 10.5.9 replace those temporary typed paths and their tests ensure they are not retained.

- [ ] **Step 4: Run GREEN and full verification**

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_notification_scheduler.dart \
  test/support/fake_linux_systemd_unit_store.dart \
  test/support/fake_linux_systemd_schedule_registry_store.dart \
  test/support/recording_native_notification_gateway.dart \
  test/support/controlled_linux_process_runner.dart \
  test/core/notifications/linux_systemd_notification_scheduler_schedule_test.dart \
  tool/verify_phase1_task10_5_5_green.py
git commit -m "feat: schedule Linux systemd notifications"
```

---

# Gate 10.5.6 — Schedule Rollback and Cancellation Preservation

**Files:**
- Modify: `lib/core/notifications/linux_systemd_notification_scheduler.dart`
- Test: `test/core/notifications/linux_systemd_notification_scheduler_schedule_rollback_test.dart`
- Create: `tool/verify_phase1_task10_5_6_green.py`

**Rollback sequence after unit apply begins:**

```text
disable new timer when systemd may have observed it
rollback retained install transaction
daemon reload after unit restoration
logically restore previous registry entries with monotonic generation
re-enable previous timer when a previous registry entry existed
```

- [ ] **Step 1: Write RED tests**

Inject primary failures at:

- command factory;
- render;
- begin install;
- install apply;
- daemon reload;
- enable/start;
- registry replace;
- install finalize.

For failures after apply, test rollback to missing, service-only, timer-only, and complete prior pairs.

Test registry restoration:

```dart
expect(registryStore.current.entries, previousRegistry.entries);
expect(
  registryStore.current.generation,
  greaterThan(previousRegistry.generation),
);
```

Test cancellation:

```dart
await expectLater(
  scheduler.schedule(request),
  throwsA(same(cancellation)),
);
expect(unitTransaction.rollbackCalls, 1);
```

When rollback also fails:

```dart
expect(error.failure, LinuxSystemdNotificationSchedulerFailure.rollbackFailed);
expect(error.cause, same(cancellation));
expect(error.rollbackFailures, isNotEmpty);
```

- [ ] **Step 2: Run RED**

Expected: forward failures leave applied state or do not preserve cancellation correctly.

- [ ] **Step 3: Implement rollback state tracking**

Track booleans for transaction applied, daemon observed, registry replaced, and previous entry present. Capture the primary stack trace before rollback.

- [ ] **Step 4: Run GREEN and all schedule tests plus full verification**

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_notification_scheduler.dart \
  test/core/notifications/linux_systemd_notification_scheduler_schedule_rollback_test.dart \
  tool/verify_phase1_task10_5_6_green.py
git commit -m "feat: rollback failed Linux schedules"
```

---

# Gate 10.5.7 — Cancel Flow and Cancel Rollback

**Files:**
- Modify: `lib/core/notifications/linux_systemd_notification_scheduler.dart`
- Test: `test/core/notifications/linux_systemd_notification_scheduler_cancel_test.dart`
- Create: `tool/verify_phase1_task10_5_7_green.py`

**Cancel order:**

```text
derive stable names
load registry
begin retained remove
disable and stop
apply removal
daemon reload
replace registry without matching entry when present
finalize removal
```

Missing registry entry and missing files are allowed. Driver evidence must confirm the disabled state; raw command nonzero is not silently ignored.

**Rollback order:**

```text
rollback removed files
daemon reload
restore prior registry entries with monotonic generation
re-enable timer when previous registry contained the schedule
```

- [ ] **Step 1: Write RED tests**

Cover:

- completely missing state;
- registry-only state;
- unit-only state;
- complete happy path;
- already-disabled typed success;
- failure at begin remove, disable, apply, reload, registry replace, finalize;
- exact previous partial/complete file restore;
- previous registry logical restore;
- previous timer re-enabled;
- cancellation primary preservation.

- [ ] **Step 2: Run RED**

Expected: public cancel still uses the temporary Gate 10.5.5 behavior.

- [ ] **Step 3: Implement public cancel and `_cancelUnlocked`**

Do not reacquire scheduler locks from due scheduling or owner/reconcile batches.

- [ ] **Step 4: Run GREEN and full verification**

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_notification_scheduler.dart \
  test/core/notifications/linux_systemd_notification_scheduler_cancel_test.dart \
  tool/verify_phase1_task10_5_7_green.py
git commit -m "feat: cancel Linux systemd notifications"
```

---

# Gate 10.5.8 — Scheduler Locks and Owner Cancellation

**Files:**
- Modify: `lib/core/notifications/linux_systemd_notification_scheduler.dart`
- Test: `test/core/notifications/linux_systemd_notification_scheduler_concurrency_test.dart`
- Create: `tool/verify_phase1_task10_5_8_green.py`

**Lock rules:**

```dart
Future<void> schedule(NotificationRequest request) {
  return globalLock.runRead(
    () => scheduleMutex.synchronized(
      request.scheduleId,
      () => _scheduleUnlocked(request),
    ),
  );
}
```

```dart
Future<void> cancelByOwner(NotificationOwner owner) {
  return globalLock.runWrite(
    () => _cancelByOwnerUnlocked(owner),
  );
}
```

`cancelByOwner` loads the registry once, filters exact owners, sorts IDs, then calls `_cancelUnlocked` without reacquiring locks.

- [ ] **Step 1: Write controlled-concurrency RED tests**

Prove:

- same schedule ID operations run FIFO and never overlap;
- different IDs overlap under global read;
- `cancelByOwner` waits for active read operations;
- new reads wait behind an already queued writer;
- owner matching is exact;
- cancellation order is sorted by schedule ID;
- no matches is idempotent;
- first failed schedule stops the batch;
- exception contains failing schedule and immutable completed IDs.

- [ ] **Step 2: Run RED**

Expected: operations overlap incorrectly or owner batch uses temporary behavior.

- [ ] **Step 3: Implement lock wrappers and owner batch**

Use the existing writer-preferring lock and keyed FIFO mutex; do not create a second custom lock.

- [ ] **Step 4: Run GREEN and full verification**

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_notification_scheduler.dart \
  test/core/notifications/linux_systemd_notification_scheduler_concurrency_test.dart \
  tool/verify_phase1_task10_5_8_green.py
git commit -m "feat: serialize Linux scheduler mutations"
```

---

# Gate 10.5.9 — Reconciliation Normalization and Inventory Recovery

**Files:**
- Modify: `lib/core/notifications/linux_systemd_notification_scheduler.dart`
- Test: `test/core/notifications/linux_systemd_notification_scheduler_reconcile_inventory_test.dart`
- Create: `tool/verify_phase1_task10_5_9_green.py`

**Normalization:**

```dart
final desiredById = <String, NotificationRequest>{};
for (final request in expected) {
  desiredById[request.scheduleId] = request;
}

final desired = desiredById.values
    .where((request) => request.scheduledAtUtc.isAfter(nowUtc))
    .toList()
  ..sort((left, right) => left.scheduleId.compareTo(right.scheduleId));
```

Do not call `showNow` for removed due requests.

**Corrupt recovery:**

1. `load()` raises a typed registry corruption failure;
2. call `quarantineCorruptRegistry()`;
3. treat registry as empty;
4. call `discoverAppUnitPairs()`;
5. remove complete and partial exact app-owned units;
6. reload daemon;
7. continue rebuilding desired future requests.

**Stale cleanup:**

Remove stale registry entries, orphan complete pairs, partial pairs, and entries whose names do not equal `forScheduleKey(scheduleId)`.

- [ ] **Step 1: Write RED tests**

Cover last-value-wins, sorted processing, due cleanup without delivery, stale registry removal, orphan complete removal, partial removal, mismatched-name removal, corrupt quarantine, exact app-owned scope, one discovery call, and empty no-op.

- [ ] **Step 2: Run RED**

Expected: public reconcile still uses temporary behavior.

- [ ] **Step 3: Implement normalization and cleanup batch**

Stage retained removals, disable known timers, apply file removals, perform one coherent daemon reload when files changed, and update registry to confirmed cleanup state.

- [ ] **Step 4: Run GREEN and full verification**

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_notification_scheduler.dart \
  test/core/notifications/linux_systemd_notification_scheduler_reconcile_inventory_test.dart \
  tool/verify_phase1_task10_5_9_green.py
git commit -m "feat: recover Linux notification inventory"
```

---

# Gate 10.5.10 — Reconciliation Repair and Partial Reporting

**Files:**
- Modify: `lib/core/notifications/linux_systemd_notification_scheduler.dart`
- Test: `test/core/notifications/linux_systemd_notification_scheduler_reconcile_repair_test.dart`
- Create: `tool/verify_phase1_task10_5_10_green.py`

**Repair classification per desired request:**

```text
matching fingerprint + healthy typed status => preserve
matching fingerprint + unhealthy status => repair
changed fingerprint => replace
missing registry or unit pair => create
```

**Batch behavior:**

1. begin/apply retained install transactions in schedule-ID order;
2. reload daemon once for the coherent install batch;
3. enable timers in schedule-ID order;
4. add only confirmed successes to the final registry;
5. finalize successful transactions;
6. rollback the failing transaction;
7. preserve already-confirmed successes;
8. write a registry matching confirmed platform state;
9. throw `partialReconciliation` with failing ID and completed IDs.

- [ ] **Step 1: Write RED tests**

Cover healthy preservation, changed repair, unhealthy repair, missing creation, deterministic order, bounded reload count, no-op with zero reloads, failure at render/apply/reload/enable/registry/finalize, confirmed-success registry, failed-item rollback, and safe partial exception.

- [ ] **Step 2: Run RED**

Expected: reconcile performs cleanup only and does not repair desired items.

- [ ] **Step 3: Implement repair batch**

Correctness takes priority over reload minimization. Never write an entry before enable/start returns a healthy typed status.

- [ ] **Step 4: Run GREEN and all scheduler tests plus full verification**

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_notification_scheduler.dart \
  test/core/notifications/linux_systemd_notification_scheduler_reconcile_repair_test.dart \
  tool/verify_phase1_task10_5_10_green.py
git commit -m "feat: reconcile Linux notification schedules"
```

---

# Gate 10.5.11 — Final Task 10.5 Checkpoint

**Files:**
- Test: `test/core/notifications/linux_systemd_notification_scheduler_final_checkpoint_test.dart`
- Create: `docs/superpowers/checkpoints/2026-07-30-linux-systemd-notification-scheduler-checkpoint.md`
- Modify: `docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md`
- Create: `tool/prepare_phase1_task10_5_checkpoint.py`
- Create: `tool/verify_phase1_task10_5_complete.py`

- [ ] **Step 1: Write final lifecycle tests**

One end-to-end fake lifecycle must prove:

```text
future schedule
healthy idempotent repeat
changed request replacement
due request stale cleanup + immediate delivery
future cancellation
owner cancellation
startup reconciliation with stale/orphan/partial cleanup
corrupt quarantine and rebuild
partial reconciliation reporting
```

A second adapter-composition test uses:

- production `LinuxSystemdUserUnitStore`;
- `FakeLinuxSystemdFileSystem`;
- production renderer;
- production driver with controlled fake process runner;
- fake registry store and gateway;
- fixed clock.

It must not access real systemd.

- [ ] **Step 2: Run all Task 10.5 focused tests**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_systemd_unit_transaction_model_test.dart \
  test/core/notifications/linux_systemd_user_unit_install_transaction_test.dart \
  test/core/notifications/linux_systemd_user_unit_remove_transaction_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_model_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_schedule_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_schedule_rollback_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_cancel_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_concurrency_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_reconcile_inventory_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_reconcile_repair_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_final_checkpoint_test.dart" \
  /tmp/task10-5-focused.log
```

- [ ] **Step 3: Run project verification**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task10-5-full.log
flutter build linux --debug
git diff --check
```

- [ ] **Step 4: Finalize checkpoint evidence**

The checkpoint records:

- exact hashes for Gates 10.5.1 through 10.5.10;
- focused and full test counts;
- analyze result;
- Linux build result;
- retained transaction semantics;
- locking guarantees;
- rollback/cancellation behavior;
- reconciliation guarantees;
- Task 10.6 still pending.

Mark Task 10.5 implemented in the shared design only after fresh verification.

- [ ] **Step 5: Commit**

```bash
git add \
  test/core/notifications/linux_systemd_notification_scheduler_final_checkpoint_test.dart \
  docs/superpowers/checkpoints/2026-07-30-linux-systemd-notification-scheduler-checkpoint.md \
  docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md \
  tool/prepare_phase1_task10_5_checkpoint.py \
  tool/verify_phase1_task10_5_complete.py
git commit -m "test: checkpoint Linux notification scheduler"
```

---

## Required Commit Sequence

1. `feat: define retained systemd unit transactions`
2. `feat: retain Linux unit install rollback state`
3. `feat: retain Linux unit removal snapshots`
4. `feat: define Linux scheduler contracts`
5. `feat: schedule Linux systemd notifications`
6. `feat: rollback failed Linux schedules`
7. `feat: cancel Linux systemd notifications`
8. `feat: serialize Linux scheduler mutations`
9. `feat: recover Linux notification inventory`
10. `feat: reconcile Linux notification schedules`
11. `test: checkpoint Linux notification scheduler`

## Final Acceptance Checklist

- [ ] Retained install transaction restores missing, partial, and complete prior pairs.
- [ ] Retained remove transaction restores missing, partial, and complete prior pairs.
- [ ] Convenience `install` and `remove` wrappers preserve existing behavior.
- [ ] Due scheduling removes stale Linux state before immediate delivery.
- [ ] Future scheduling writes registry only after healthy typed systemd confirmation.
- [ ] Healthy same-fingerprint schedules are no-ops.
- [ ] Changed or unhealthy schedules repair.
- [ ] Schedule rollback restores units, daemon view, registry entries, and previous timer intent.
- [ ] Successful cancellation is idempotent.
- [ ] Cancel rollback restores prior confirmed state.
- [ ] Same-ID operations serialize FIFO.
- [ ] Different-ID read operations can overlap.
- [ ] Owner cancellation holds the global write lock and uses exact owner equality.
- [ ] Reconciliation uses last-value-wins and deterministic sorting.
- [ ] Reconciliation never immediately delivers due requests.
- [ ] Corrupt registry is quarantined and exact app-owned inventory is rebuilt.
- [ ] Stale, orphan, partial, and mismatched units are removed.
- [ ] Healthy desired entries are preserved.
- [ ] Changed, unhealthy, and missing desired entries are repaired.
- [ ] Partial reconciliation reports failing and completed schedule IDs.
- [ ] Primary causes remain primary and rollback failures are attached.
- [ ] Cancellation is rethrown unchanged when rollback succeeds.
- [ ] No scheduler error prints sensitive notification content.
- [ ] No scheduler test touches the real user systemd manager.
- [ ] `flutter analyze` is clean.
- [ ] Full tests pass.
- [ ] Linux debug build succeeds.
- [ ] `git diff --check` is clean.
