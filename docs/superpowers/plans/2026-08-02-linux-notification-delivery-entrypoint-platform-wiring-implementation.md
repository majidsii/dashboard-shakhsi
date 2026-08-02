# Linux Notification Delivery Entrypoint and Platform Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Task 10.6 by adding exact persisted-request lookup, a shell-free hidden Linux delivery command, validated executable resolution, minimal hidden-process delivery bootstrap, Linux-only scheduler selection, startup reconciliation wiring, and an integrated checkpoint without changing non-Linux notification behavior.

**Architecture:** Keep command parsing, delivery orchestration, platform composition, and application bootstrap in separate units. The hidden process parses one exact command before UI startup, opens only the repository and notification gateway it needs, loads one persisted request, applies existing privacy and payload rules, displays it, closes resources, and returns a typed exit result. Riverpod platform selection remains lazy so non-Linux branches never construct Linux filesystem, registry, executable-path, process, or systemd dependencies.

**Tech Stack:** Dart 3.12+, Flutter, Riverpod, Drift, existing `NotificationScheduleRepository`, `NotificationDeliveryPolicy`, `NotificationPayloadCodec`, `NativeNotificationGateway`, `NotificationHostPlatform`, `NotificationStartupService`, `LinuxSystemdNotificationScheduler`, Task 10.4 registry/store, Task 10.5 scheduler/transactions, injected process/filesystem/environment abstractions, Flutter test, and Python structural verifiers.

## Global Constraints

- Implement only Task 10.6 from `docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md`.
- Task 10.4 and Task 10.5 public contracts remain stable unless this plan explicitly extends them.
- The hidden command is exactly `<absolute-executable> --deliver-notification <schedule-id>`.
- Hidden mode accepts exactly two application arguments: the flag and one schedule ID.
- Reject missing, extra, repeated, empty, whitespace-only, NUL-containing, CR-containing, LF-containing, and other control-character arguments.
- The hidden parser is pure Dart and does not import `dart:io`, Flutter plugins, Drift, Riverpod, or UI code.
- Normal UI startup remains unchanged when the hidden flag is absent.
- The systemd unit file contains only the executable path, hidden flag, and schedule ID; it never contains title, body, payload, privacy mode, or owner data.
- The executable path is injected into the command factory.
- Production executable resolution is isolated behind an infrastructure interface.
- The validated executable path must be absolute and must not contain NUL, CR, or LF.
- When platform file verification is available, the path must identify a regular executable file.
- Tests use deterministic executable paths and never depend on the test runner executable.
- `NotificationScheduleRepository` gains `Future<NotificationRequest?> getById(String scheduleId)`.
- Drift lookup uses exact `scheduleId` equality and `getSingleOrNull`.
- Memory and test repositories implement identical exact lookup semantics.
- Hidden delivery loads the request from `NotificationScheduleRepository.getById`.
- A missing request is a benign stale timer and returns exit code zero without display.
- Hidden delivery applies `NotificationDeliveryPolicy.contentFor`.
- Hidden delivery preserves the existing encoded navigation payload through `NotificationPayloadCodec.encode`.
- Hidden delivery calls `NativeNotificationGateway.showNow` with `StableNotificationId.fromScheduleId`.
- Hidden delivery does not delete or mutate Drift desired state.
- Hidden delivery does not open the dashboard, router, routing queue, normal startup widget tree, or scheduled-reconciliation provider.
- Only minimum database and local-notification resources are initialized in hidden mode.
- Resource-close failures are retained without replacing the primary parsing, initialization, lookup, or display failure.
- Exception strings, logs, tests, and verifier output never expose notification title, body, payload, rendered units, raw registry JSON, or database row contents.
- Platform selection uses the existing injected `NotificationHostPlatform` abstraction, not direct `Platform.isLinux` checks in domain or provider-selection code.
- Linux selection creates `LinuxSystemdNotificationScheduler`.
- Android, macOS, and Windows retain the existing `PlatformNotificationScheduler` behavior.
- Existing unsupported/no-op behavior remains unchanged for unsupported hosts.
- Non-Linux provider tests prove no Linux executable source, filesystem, registry, process runner, path resolver, unit store, command factory, or scheduler is created.
- Linux normal startup initializes notification infrastructure and calls `NotificationCoordinator.reconcileFromPersistence`.
- Startup reconciliation remains single-flight for one provider scope.
- A typed reconciliation failure is reported without replacing or permanently blocking the dashboard widget tree.
- Failed startup reconciliation remains retryable on a new service/provider scope or explicit schedule mutation.
- No automated test invokes real `systemctl`.
- No automated test accesses the real user systemd directory.
- No automated test displays a real desktop notification.
- Follow RED → observe intended failure → GREEN → focused tests → `flutter analyze` → full `flutter test` → `flutter build linux --debug` → `git diff --check` → commit → push.
- Remove each RED-only verifier before its Gate commit and retain the GREEN verifier.
- Task 10.6 uses nine review Gates and nine commits.

---

## File Map

### Repository lookup

- Modify: `lib/core/notifications/notification_schedule_repository.dart`
- Modify: `lib/core/notifications/drift_notification_schedule_repository.dart`
- Modify: `test/support/memory_notification_schedule_repository.dart`
- Modify: `test/core/notifications/drift_notification_schedule_repository_test.dart`
- Modify: repository/coordinator fakes that implement `NotificationScheduleRepository`

### Hidden command and typed exit model

- Create: `lib/core/notifications/linux_notification_delivery_invocation.dart`
- Create: `lib/core/notifications/linux_notification_delivery_result.dart`
- Create: `test/core/notifications/linux_notification_delivery_invocation_test.dart`
- Create: `test/core/notifications/linux_notification_delivery_result_test.dart`

### Executable resolution and systemd command factory

- Modify: `lib/core/notifications/linux_notification_delivery_command_factory.dart`
- Create: `lib/core/notifications/linux_executable_path_source.dart`
- Create: `lib/core/notifications/dart_io_linux_executable_path_source.dart`
- Create: `lib/core/notifications/resolved_linux_notification_delivery_command_factory.dart`
- Create: `test/core/notifications/linux_executable_path_source_test.dart`
- Create: `test/core/notifications/resolved_linux_notification_delivery_command_factory_test.dart`

### Hidden delivery orchestration

- Create: `lib/core/notifications/linux_notification_delivery_service.dart`
- Create: `lib/core/notifications/linux_notification_delivery_exception.dart`
- Create: `test/core/notifications/linux_notification_delivery_service_test.dart`

### Hidden process bootstrap

- Create: `lib/app/bootstrap/linux_notification_delivery_bootstrap.dart`
- Create: `lib/app/bootstrap/application_entrypoint.dart`
- Modify: `lib/main.dart`
- Create: `test/app/bootstrap/linux_notification_delivery_bootstrap_test.dart`
- Create: `test/app/bootstrap/application_entrypoint_test.dart`

### Platform composition and startup

- Create: `lib/core/notifications/notification_platform_providers.dart`
- Create: `lib/app/bootstrap/notification_startup_bootstrap.dart`
- Modify: the existing root application bootstrap/widget to include `NotificationStartupBootstrap`
- Create: `test/core/notifications/notification_platform_providers_test.dart`
- Create: `test/app/bootstrap/notification_startup_bootstrap_test.dart`
- Modify: `test/core/notifications/notification_startup_service_test.dart`

### Integrated checkpoint and documentation

- Create: `test/core/notifications/linux_notification_pipeline_integration_test.dart`
- Create: `docs/superpowers/checkpoints/2026-08-02-linux-notification-delivery-platform-wiring-checkpoint.md`
- Modify: `docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md`
- Create: `tool/verify_phase1_task10_6_complete.py`

---

# Gate 10.6.1 — Repository Lookup Contract

**Commit:** `feat: add notification schedule lookup`

**Files:**
- Modify: `lib/core/notifications/notification_schedule_repository.dart`
- Modify: `lib/core/notifications/drift_notification_schedule_repository.dart`
- Modify: `test/support/memory_notification_schedule_repository.dart`
- Modify: all test fakes implementing `NotificationScheduleRepository`
- Test: `test/core/notifications/drift_notification_schedule_repository_test.dart`
- Test: `test/support/memory_notification_schedule_repository_test.dart`
- Create: `tool/verify_phase1_task10_6_1_green.py`

**Interfaces:**

```dart
abstract interface class NotificationScheduleRepository {
  Stream<List<NotificationRequest>> watchAll();

  Future<List<NotificationRequest>> getAll();

  Future<NotificationRequest?> getById(String scheduleId);

  Future<void> upsert(NotificationRequest request);

  Future<void> delete(String scheduleId);

  Future<void> deleteByOwner(NotificationOwner owner);

  Future<void> replaceAll(List<NotificationRequest> expected);
}
```

The Drift implementation is exact and returns null when absent:

```dart
@override
Future<NotificationRequest?> getById(String scheduleId) async {
  final row =
      await (_database.select(_database.notificationScheduleRows)
            ..where((item) => item.scheduleId.equals(scheduleId)))
          .getSingleOrNull();

  return row == null ? null : _requestFromRow(row);
}
```

The memory implementation reads one immutable snapshot and performs exact case-sensitive matching:

```dart
@override
Future<NotificationRequest?> getById(String scheduleId) async {
  return _requestsById[scheduleId];
}
```

- [ ] **Step 1: Write RED tests**

Add tests proving:

```dart
final stored = request(scheduleId: 'task-exact');
await repository.upsert(stored);

expect(await repository.getById('task-exact'), stored);
expect(await repository.getById('TASK-EXACT'), isNull);
expect(await repository.getById('task-exact '), isNull);
expect(await repository.getById('missing'), isNull);
```

For Drift, also verify payload, privacy mode, owner, title, body, and UTC timestamp map through the existing `_requestFromRow` path exactly.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/drift_notification_schedule_repository_test.dart \
  test/support/memory_notification_schedule_repository_test.dart" \
  /tmp/task10-6-1-red.log
```

Expected: compilation failure because `getById` is not defined.

- [ ] **Step 3: Implement the interface and exact lookups**

Update every implementation and fake. Do not provide a default implementation in the interface because missing support must fail at compile time.

- [ ] **Step 4: Run focused GREEN**

```bash
python3 tool/verify_phase1_task10_6_1_green.py

script -qefc \
  "flutter --color test \
  test/core/notifications/drift_notification_schedule_repository_test.dart \
  test/support/memory_notification_schedule_repository_test.dart \
  test/core/notifications/notification_coordinator_test.dart" \
  /tmp/task10-6-1-green.log
```

- [ ] **Step 5: Run the standard verification chain and commit**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task10-6-1-full.log
flutter build linux --debug
git diff --check
git add \
  lib/core/notifications/notification_schedule_repository.dart \
  lib/core/notifications/drift_notification_schedule_repository.dart \
  test/support/memory_notification_schedule_repository.dart \
  test/core/notifications/drift_notification_schedule_repository_test.dart \
  test/support/memory_notification_schedule_repository_test.dart \
  tool/verify_phase1_task10_6_1_green.py
git commit -m "feat: add notification schedule lookup"
git push
```

---

# Gate 10.6.2 — Exact Hidden Command Parser and Exit Model

**Commit:** `feat: parse Linux notification delivery command`

**Files:**
- Create: `lib/core/notifications/linux_notification_delivery_invocation.dart`
- Create: `lib/core/notifications/linux_notification_delivery_result.dart`
- Test: `test/core/notifications/linux_notification_delivery_invocation_test.dart`
- Test: `test/core/notifications/linux_notification_delivery_result_test.dart`
- Create: `tool/verify_phase1_task10_6_2_green.py`

**Interfaces:**

```dart
sealed class LinuxNotificationDeliveryInvocation {
  const LinuxNotificationDeliveryInvocation();

  factory LinuxNotificationDeliveryInvocation.parse(
    List<String> arguments,
  );
}

final class LinuxNormalApplicationInvocation
    extends LinuxNotificationDeliveryInvocation {
  const LinuxNormalApplicationInvocation();
}

final class LinuxHiddenNotificationDeliveryInvocation
    extends LinuxNotificationDeliveryInvocation {
  const LinuxHiddenNotificationDeliveryInvocation({
    required this.scheduleId,
  });

  final String scheduleId;
}
```

Parsing rules:

```dart
if (!arguments.contains('--deliver-notification')) {
  return const LinuxNormalApplicationInvocation();
}

if (arguments.length != 2 ||
    arguments.first != '--deliver-notification') {
  throw const LinuxNotificationDeliveryArgumentException(
    LinuxNotificationDeliveryArgumentFailure.invalidShape,
  );
}
```

Validate the schedule ID through one shared helper that rejects empty/trim-changing/control-character values but preserves valid Unicode and punctuation as one argument.

Typed exit result:

```dart
enum LinuxNotificationDeliveryExitKind {
  normalApplication,
  delivered,
  missingRequest,
  invalidArguments,
  initializationFailed,
  lookupFailed,
  displayFailed,
}

final class LinuxNotificationDeliveryResult {
  const LinuxNotificationDeliveryResult({
    required this.kind,
    required this.exitCode,
    this.cause,
    this.causeStackTrace,
    this.closeFailures = const <LinuxNotificationDeliveryCloseFailure>[],
  });

  final LinuxNotificationDeliveryExitKind kind;
  final int exitCode;
  final Object? cause;
  final StackTrace? causeStackTrace;
  final List<LinuxNotificationDeliveryCloseFailure> closeFailures;
}
```

`toString()` may include only kind, exit code, cause runtime type, and close-failure count.

- [ ] **Step 1: Write RED parser/model tests**

Cover:

```dart
expect(
  LinuxNotificationDeliveryInvocation.parse(const <String>[]),
  isA<LinuxNormalApplicationInvocation>(),
);

final delivery = LinuxNotificationDeliveryInvocation.parse(
  const <String>['--deliver-notification', 'task-42'],
);
expect(
  (delivery as LinuxHiddenNotificationDeliveryInvocation).scheduleId,
  'task-42',
);
```

Reject:

```dart
const <String>['--deliver-notification'];
const <String>['--deliver-notification', 'task-42', 'extra'];
const <String>['prefix', '--deliver-notification', 'task-42'];
const <String>['--deliver-notification', '--deliver-notification'];
const <String>['--deliver-notification', ''];
const <String>['--deliver-notification', ' task-42'];
const <String>['--deliver-notification', 'task\n42'];
const <String>['--deliver-notification', 'task\u000042'];
const <String>['--deliver-notification', 'task\u001f42'];
```

Also verify ordinary arguments without the hidden flag remain normal startup arguments.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_notification_delivery_invocation_test.dart \
  test/core/notifications/linux_notification_delivery_result_test.dart" \
  /tmp/task10-6-2-red.log
```

Expected: missing-file compilation failure.

- [ ] **Step 3: Implement pure models**

Use immutable/unmodifiable close failure lists:

```dart
closeFailures = List<LinuxNotificationDeliveryCloseFailure>.unmodifiable(
  closeFailures,
);
```

Do not import `dart:io`.

- [ ] **Step 4: Run GREEN and full verification**

```bash
python3 tool/verify_phase1_task10_6_2_green.py
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_notification_delivery_invocation_test.dart \
  test/core/notifications/linux_notification_delivery_result_test.dart" \
  /tmp/task10-6-2-green.log
flutter analyze
script -qefc "flutter --color test" /tmp/task10-6-2-full.log
flutter build linux --debug
git diff --check
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_notification_delivery_invocation.dart \
  lib/core/notifications/linux_notification_delivery_result.dart \
  test/core/notifications/linux_notification_delivery_invocation_test.dart \
  test/core/notifications/linux_notification_delivery_result_test.dart \
  tool/verify_phase1_task10_6_2_green.py
git commit -m "feat: parse Linux notification delivery command"
git push
```

---

# Gate 10.6.3 — Executable Resolution and Production Command Factory

**Commit:** `feat: resolve Linux notification delivery executable`

**Files:**
- Modify: `lib/core/notifications/linux_notification_delivery_command_factory.dart`
- Create: `lib/core/notifications/linux_executable_path_source.dart`
- Create: `lib/core/notifications/dart_io_linux_executable_path_source.dart`
- Create: `lib/core/notifications/resolved_linux_notification_delivery_command_factory.dart`
- Test: `test/core/notifications/linux_executable_path_source_test.dart`
- Test: `test/core/notifications/resolved_linux_notification_delivery_command_factory_test.dart`
- Create: `tool/verify_phase1_task10_6_3_green.py`

**Interfaces:**

```dart
abstract interface class LinuxExecutablePathSource {
  Future<String> resolve();
}

abstract interface class LinuxExecutableFileVerifier {
  Future<LinuxExecutableFileStatus> status(String path);
}

final class LinuxExecutableFileStatus {
  const LinuxExecutableFileStatus({
    required this.exists,
    required this.isRegularFile,
    required this.isExecutable,
  });

  final bool exists;
  final bool isRegularFile;
  final bool isExecutable;
}
```

Production resolution stays in a `dart:io` adapter:

```dart
final class DartIoLinuxExecutablePathSource
    implements LinuxExecutablePathSource {
  @override
  Future<String> resolve() async => Platform.resolvedExecutable;
}
```

The validating source composes raw source and optional verifier:

```dart
final class ValidatedLinuxExecutablePathSource
    implements LinuxExecutablePathSource {
  ValidatedLinuxExecutablePathSource({
    required LinuxExecutablePathSource source,
    LinuxExecutableFileVerifier? verifier,
  });

  @override
  Future<String> resolve();
}
```

The production command factory caches one validated path and emits:

```dart
LinuxSystemdNotificationUnit(
  scheduleKey: request.scheduleId,
  scheduledAtUtc: request.scheduledAtUtc,
  executablePath: executablePath,
  arguments: <String>[
    '--deliver-notification',
    request.scheduleId,
  ],
);
```

Because the existing factory is synchronous, choose one explicit contract and use it consistently:

```dart
abstract interface class LinuxNotificationDeliveryCommandFactory {
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  );
}
```

Update Task 10.5 scheduler and all fakes/tests to await the factory. This is the only planned Task 10.5 signature extension.

- [ ] **Step 1: Write RED tests**

Validate:

- `/opt/dashboard-shakhsi/dashboard_shakhsi` succeeds.
- relative paths fail.
- empty/trim-changing/NUL/CR/LF paths fail.
- missing, directory, or non-executable status fails when verifier is injected.
- verifier is optional for deterministic tests.
- repeated `create` calls resolve the executable only once.
- unit arguments are exactly hidden flag + schedule ID.
- title/body/payload/owner never appear in rendered command fields.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_executable_path_source_test.dart \
  test/core/notifications/resolved_linux_notification_delivery_command_factory_test.dart" \
  /tmp/task10-6-3-red.log
```

Expected: missing contracts and synchronous-factory mismatch.

- [ ] **Step 3: Implement and update Task 10.5 call sites**

Scheduler call:

```dart
final unit = await _step<LinuxSystemdNotificationUnit>(
  operation: operation,
  failure: LinuxSystemdNotificationSchedulerFailure.commandFactoryFailed,
  scheduleId: request.scheduleId,
  owner: request.owner,
  names: names,
  action: () => _commandFactory.create(request),
);
```

Every fake factory returns `Future.value(unit)` or uses an `async` method.

- [ ] **Step 4: Run focused compatibility tests**

```bash
python3 tool/verify_phase1_task10_6_3_green.py
script -qefc \
  "flutter --color test \
  test/core/notifications/resolved_linux_notification_delivery_command_factory_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_schedule_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_schedule_rollback_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_reconcile_repair_test.dart" \
  /tmp/task10-6-3-green.log
```

- [ ] **Step 5: Run standard verification and commit**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task10-6-3-full.log
flutter build linux --debug
git diff --check
git add \
  lib/core/notifications/linux_notification_delivery_command_factory.dart \
  lib/core/notifications/linux_executable_path_source.dart \
  lib/core/notifications/dart_io_linux_executable_path_source.dart \
  lib/core/notifications/resolved_linux_notification_delivery_command_factory.dart \
  lib/core/notifications/linux_systemd_notification_scheduler.dart \
  test/core/notifications \
  test/support \
  tool/verify_phase1_task10_6_3_green.py
git commit -m "feat: resolve Linux notification delivery executable"
git push
```

---

# Gate 10.6.4 — Persisted Hidden Delivery Service

**Commit:** `feat: deliver persisted Linux notifications`

**Files:**
- Create: `lib/core/notifications/linux_notification_delivery_service.dart`
- Create: `lib/core/notifications/linux_notification_delivery_exception.dart`
- Test: `test/core/notifications/linux_notification_delivery_service_test.dart`
- Create: `tool/verify_phase1_task10_6_4_green.py`

**Interfaces:**

```dart
abstract interface class LinuxNotificationDeliveryResources {
  NotificationScheduleRepository get repository;
  NativeNotificationGateway get gateway;

  Future<void> close();
}

abstract interface class LinuxNotificationDeliveryResourcesFactory {
  Future<LinuxNotificationDeliveryResources> open();
}

final class LinuxNotificationDeliveryService {
  LinuxNotificationDeliveryService({
    required LinuxNotificationDeliveryResourcesFactory resourcesFactory,
  });

  Future<LinuxNotificationDeliveryResult> deliver(String scheduleId);
}
```

Flow:

```dart
LinuxNotificationDeliveryResources? resources;
LinuxNotificationDeliveryResult primary;

try {
  resources = await _resourcesFactory.open();
  final request = await resources.repository.getById(scheduleId);

  if (request == null) {
    primary = LinuxNotificationDeliveryResult.missingRequest();
  } else {
    final content = NotificationDeliveryPolicy.contentFor(request);
    await resources.gateway.showNow(
      id: StableNotificationId.fromScheduleId(request.scheduleId),
      title: content.title,
      body: content.body,
      payload: NotificationPayloadCodec.encode(request),
    );
    primary = LinuxNotificationDeliveryResult.delivered();
  }
} catch (error, stackTrace) {
  primary = mapTypedFailure(error, stackTrace);
} finally {
  // Close if open succeeded and append close failures.
}
```

Use separate typed operation/failure enums:

```dart
enum LinuxNotificationDeliveryOperation {
  initialize,
  lookup,
  display,
  close,
}
```

The service must not call repository delete/replace/upsert methods.

- [ ] **Step 1: Write RED service tests**

Cover:

- exact request lookup;
- missing request returns zero and no display;
- privacy content mapping;
- payload encoding and stable ID;
- initialization failure;
- lookup failure;
- display failure;
- successful close;
- close failure after success;
- close failure attached to primary display failure;
- `toString()` privacy;
- no mutation methods invoked.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_notification_delivery_service_test.dart" \
  /tmp/task10-6-4-red.log
```

Expected: missing service/contracts.

- [ ] **Step 3: Implement minimal orchestration**

Return exit code zero only for delivered or missing request. Preserve the original cause and stack. Store close failures in encounter order.

- [ ] **Step 4: Run GREEN**

```bash
python3 tool/verify_phase1_task10_6_4_green.py
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_notification_delivery_service_test.dart \
  test/core/notifications/notification_delivery_policy_test.dart \
  test/core/notifications/notification_payload_codec_test.dart" \
  /tmp/task10-6-4-green.log
```

- [ ] **Step 5: Run standard verification and commit**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task10-6-4-full.log
flutter build linux --debug
git diff --check
git add \
  lib/core/notifications/linux_notification_delivery_service.dart \
  lib/core/notifications/linux_notification_delivery_exception.dart \
  test/core/notifications/linux_notification_delivery_service_test.dart \
  tool/verify_phase1_task10_6_4_green.py
git commit -m "feat: deliver persisted Linux notifications"
git push
```

---

# Gate 10.6.5 — Hidden Application Mode Before UI Bootstrap

**Commit:** `feat: run hidden Linux notification mode`

**Files:**
- Create: `lib/app/bootstrap/linux_notification_delivery_bootstrap.dart`
- Create: `lib/app/bootstrap/application_entrypoint.dart`
- Modify: `lib/main.dart`
- Test: `test/app/bootstrap/linux_notification_delivery_bootstrap_test.dart`
- Test: `test/app/bootstrap/application_entrypoint_test.dart`
- Create: `tool/verify_phase1_task10_6_5_green.py`

**Interfaces:**

```dart
abstract interface class NormalApplicationRunner {
  Future<void> run();
}

abstract interface class ProcessExitCodeSink {
  void setExitCode(int value);
}

final class ApplicationEntrypoint {
  ApplicationEntrypoint({
    required LinuxNotificationDeliveryInvocation Function(List<String>)
        invocationParser,
    required LinuxNotificationDeliveryService deliveryService,
    required NormalApplicationRunner normalApplicationRunner,
    required ProcessExitCodeSink exitCodeSink,
  });

  Future<void> run(List<String> arguments);
}
```

Hidden bootstrap owns only minimum initialization:

```dart
abstract interface class LinuxNotificationDeliveryBootstrap {
  Future<LinuxNotificationDeliveryResources> open();
}
```

Production resources:

- call `WidgetsFlutterBinding.ensureInitialized`;
- open `AppDatabase`;
- construct `DriftNotificationScheduleRepository`;
- initialize the local-notification plugin/gateway only;
- provide an idempotent `close()` that closes the database and any closeable plugin resource;
- do not create Riverpod root scope, router, dashboard widget, routing startup, scheduler provider, or startup reconciliation.

Main:

```dart
Future<void> main(List<String> arguments) async {
  final entrypoint = buildProductionApplicationEntrypoint();
  await entrypoint.run(arguments);
}
```

Normal runner wraps the existing bootstrap unchanged.

- [ ] **Step 1: Write RED entrypoint tests**

Prove:

- no hidden flag runs normal application exactly once;
- valid hidden command never runs normal UI;
- invalid hidden command never runs UI and sets non-zero exit;
- delivered/missing results set correct exit code;
- delivery exception does not escape main entrypoint;
- bootstrap opens only in hidden mode;
- database/plugin close is called exactly once;
- dashboard/router/startup sentinels remain untouched in hidden mode.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test \
  test/app/bootstrap/linux_notification_delivery_bootstrap_test.dart \
  test/app/bootstrap/application_entrypoint_test.dart" \
  /tmp/task10-6-5-red.log
```

Expected: missing bootstrap/entrypoint files.

- [ ] **Step 3: Implement with injected boundaries**

Keep the production `dart:io` exit-code adapter in the app/bootstrap infrastructure layer, not in core parsing or delivery service.

- [ ] **Step 4: Run GREEN**

```bash
python3 tool/verify_phase1_task10_6_5_green.py
script -qefc \
  "flutter --color test \
  test/app/bootstrap/linux_notification_delivery_bootstrap_test.dart \
  test/app/bootstrap/application_entrypoint_test.dart" \
  /tmp/task10-6-5-green.log
```

- [ ] **Step 5: Run standard verification and commit**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task10-6-5-full.log
flutter build linux --debug
git diff --check
git add \
  lib/app/bootstrap/linux_notification_delivery_bootstrap.dart \
  lib/app/bootstrap/application_entrypoint.dart \
  lib/main.dart \
  test/app/bootstrap/linux_notification_delivery_bootstrap_test.dart \
  test/app/bootstrap/application_entrypoint_test.dart \
  tool/verify_phase1_task10_6_5_green.py
git commit -m "feat: run hidden Linux notification mode"
git push
```

---

# Gate 10.6.6 — Lazy Platform Scheduler Selection

**Commit:** `feat: select Linux systemd notification scheduler`

**Files:**
- Create: `lib/core/notifications/notification_platform_providers.dart`
- Test: `test/core/notifications/notification_platform_providers_test.dart`
- Modify: existing notification provider imports/call sites
- Create: `tool/verify_phase1_task10_6_6_green.py`

**Provider contracts:**

```dart
final notificationHostPlatformProvider =
    Provider<NotificationHostPlatform>((ref) {
  return detectNotificationHostPlatform(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
  );
});

final notificationSchedulerProvider =
    Provider<NotificationScheduler>((ref) {
  return switch (ref.watch(notificationHostPlatformProvider)) {
    NotificationHostPlatform.linux =>
      ref.watch(linuxSystemdNotificationSchedulerProvider),
    NotificationHostPlatform.android ||
    NotificationHostPlatform.macos ||
    NotificationHostPlatform.windows =>
      ref.watch(platformNotificationSchedulerProvider),
    NotificationHostPlatform.unsupported =>
      ref.watch(noopNotificationSchedulerProvider),
  };
});
```

Linux dependencies are separate lazy providers:

```dart
final linuxExecutablePathSourceProvider =
    Provider<LinuxExecutablePathSource>(...);

final linuxSystemdFileSystemProvider =
    Provider<LinuxSystemdFileSystem>(...);

final linuxSystemdRegistryStoreProvider =
    Provider<LinuxSystemdScheduleRegistryStore>(...);

final linuxSystemdNotificationSchedulerProvider =
    Provider<LinuxSystemdNotificationScheduler>(...);
```

Every non-Linux test overrides Linux providers with throwing factories. Reading `notificationSchedulerProvider` on non-Linux must not evaluate any throwing factory.

- [ ] **Step 1: Write RED provider tests**

Cover all host enum values and identity:

```dart
final scheduler = container.read(notificationSchedulerProvider);
expect(scheduler, isA<LinuxSystemdNotificationScheduler>());
```

For non-Linux:

```dart
var linuxConstructionCount = 0;
final container = ProviderContainer(
  overrides: <Override>[
    notificationHostPlatformProvider.overrideWithValue(
      NotificationHostPlatform.windows,
    ),
    linuxSystemdNotificationSchedulerProvider.overrideWith((ref) {
      linuxConstructionCount += 1;
      throw StateError('must stay lazy');
    }),
  ],
);

expect(
  container.read(notificationSchedulerProvider),
  isA<PlatformNotificationScheduler>(),
);
expect(linuxConstructionCount, 0);
```

Also verify existing capability-driven unsupported behavior remains unchanged.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/notification_platform_providers_test.dart \
  test/core/notifications/platform_notification_scheduler_test.dart" \
  /tmp/task10-6-6-red.log
```

Expected: provider file missing.

- [ ] **Step 3: Implement lazy branch composition**

Do not read all scheduler providers before the switch. Do not use eager records or local variables that evaluate Linux providers on non-Linux.

- [ ] **Step 4: Run GREEN**

```bash
python3 tool/verify_phase1_task10_6_6_green.py
script -qefc \
  "flutter --color test \
  test/core/notifications/notification_platform_providers_test.dart \
  test/core/notifications/platform_notification_scheduler_test.dart \
  test/core/notifications/notification_host_platform_test.dart" \
  /tmp/task10-6-6-green.log
```

- [ ] **Step 5: Run standard verification and commit**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task10-6-6-full.log
flutter build linux --debug
git diff --check
git add \
  lib/core/notifications/notification_platform_providers.dart \
  test/core/notifications/notification_platform_providers_test.dart \
  tool/verify_phase1_task10_6_6_green.py
git commit -m "feat: select Linux systemd notification scheduler"
git push
```

---

# Gate 10.6.7 — Startup Reconciliation Wiring and Reporting

**Commit:** `feat: reconcile Linux notifications at startup`

**Files:**
- Create: `lib/app/bootstrap/notification_startup_bootstrap.dart`
- Modify: root application bootstrap/widget to wrap the existing app
- Modify: `lib/core/notifications/notification_platform_providers.dart`
- Modify: `test/core/notifications/notification_startup_service_test.dart`
- Create: `test/app/bootstrap/notification_startup_bootstrap_test.dart`
- Create: `tool/verify_phase1_task10_6_7_green.py`

**Interfaces:**

```dart
abstract interface class NotificationStartupFailureReporter {
  void report(Object error, StackTrace stackTrace);
}

final notificationStartupServiceProvider =
    Provider<NotificationStartupService>((ref) {
  return NotificationStartupService(
    enabled: ref.watch(notificationStartupEnabledProvider),
    initializer: ref.watch(localNotificationsInitializerProvider),
    coordinator: ref.watch(notificationCoordinatorProvider),
  );
});

final notificationStartupProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationStartupServiceProvider).initialize();
});
```

Widget behavior:

```dart
final class NotificationStartupBootstrap extends ConsumerStatefulWidget {
  const NotificationStartupBootstrap({
    required this.child,
    super.key,
  });

  final Widget child;
}
```

It starts the provider once and always renders `child`. On failure it reports through the injected reporter without replacing the UI.

The existing `NotificationStartupService` single-flight contract remains:

- concurrent initialize calls share one future;
- successful initialization remains cached;
- failure clears only the reconciliation future;
- plugin initialization does not repeat after a reconciliation failure.

If the current implementation does not separately cache plugin initialization, split the internal state into plugin-initialized and reconciliation-in-flight state without changing its public interface.

- [ ] **Step 1: Write RED startup tests**

Cover:

- Linux provider startup invokes initializer then coordinator reconciliation;
- repeated provider reads share one future;
- widget renders while pending;
- widget remains rendered after typed reconciliation failure;
- reporter receives the exact error and stack;
- no duplicate reconciliation during rebuilds;
- non-Linux startup retains existing enabled/capability behavior;
- failed reconciliation retries without reinitializing plugin.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/notification_startup_service_test.dart \
  test/app/bootstrap/notification_startup_bootstrap_test.dart" \
  /tmp/task10-6-7-red.log
```

Expected: bootstrap/provider wiring missing or retry contract failure.

- [ ] **Step 3: Implement startup providers and widget**

Wrap the normal root application only. Hidden mode returns before this widget exists.

- [ ] **Step 4: Run GREEN**

```bash
python3 tool/verify_phase1_task10_6_7_green.py
script -qefc \
  "flutter --color test \
  test/core/notifications/notification_startup_service_test.dart \
  test/app/bootstrap/notification_startup_bootstrap_test.dart \
  test/core/notifications/notification_routing_providers_test.dart" \
  /tmp/task10-6-7-green.log
```

- [ ] **Step 5: Run standard verification and commit**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task10-6-7-full.log
flutter build linux --debug
git diff --check
git add \
  lib/app/bootstrap/notification_startup_bootstrap.dart \
  lib/core/notifications/notification_platform_providers.dart \
  lib/core/notifications/notification_startup_service.dart \
  test/app/bootstrap/notification_startup_bootstrap_test.dart \
  test/core/notifications/notification_startup_service_test.dart \
  tool/verify_phase1_task10_6_7_green.py
git commit -m "feat: reconcile Linux notifications at startup"
git push
```

---

# Gate 10.6.8 — Integrated Delivery and Platform Composition

**Commit:** `test: verify Linux notification delivery composition`

**Files:**
- Create: `test/core/notifications/linux_notification_pipeline_integration_test.dart`
- Create: `tool/verify_phase1_task10_6_8_green.py`
- Modify only production files required to fix integration defects found by the RED test

**Integration matrix:**

1. Build a request in an in-memory Drift database.
2. Resolve a deterministic absolute executable.
3. Create a Task 10.5 Linux scheduler with fake filesystem and controlled process runner.
4. Schedule the request and verify rendered service arguments contain only executable, hidden flag, and schedule ID.
5. Run the hidden application entrypoint with the schedule ID.
6. Verify exact persisted lookup, privacy mapping, payload preservation, stable ID, and one display.
7. Verify hidden mode never runs normal UI/startup/router sentinels.
8. Verify desired Drift state still exists after delivery.
9. Verify missing request returns zero.
10. Verify non-Linux provider selection never constructs Linux dependencies.
11. Verify startup reconciliation uses the same persisted request and one single-flight startup.

- [ ] **Step 1: Write RED integration test**

Use:

- `AppDatabase(NativeDatabase.memory())`;
- fake Linux filesystem;
- controlled process runner;
- recording notification gateway;
- injected executable source;
- injected normal-UI sentinel;
- provider overrides.

No real process, systemd, HOME, XDG directory, or plugin.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_notification_pipeline_integration_test.dart" \
  /tmp/task10-6-8-red.log
```

Expected: fail only for an actual cross-component contract mismatch.

- [ ] **Step 3: Apply the smallest production corrections**

Do not add new features. Preserve all prior Gate contracts.

- [ ] **Step 4: Run integrated and regression GREEN**

```bash
python3 tool/verify_phase1_task10_6_8_green.py
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_notification_pipeline_integration_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_final_checkpoint_test.dart \
  test/app/bootstrap/application_entrypoint_test.dart \
  test/core/notifications/notification_platform_providers_test.dart \
  test/app/bootstrap/notification_startup_bootstrap_test.dart" \
  /tmp/task10-6-8-green.log
```

- [ ] **Step 5: Run standard verification and commit**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task10-6-8-full.log
flutter build linux --debug
git diff --check
git add \
  test/core/notifications/linux_notification_pipeline_integration_test.dart \
  tool/verify_phase1_task10_6_8_green.py
git add -u
git commit -m "test: verify Linux notification delivery composition"
git push
```

---

# Gate 10.6.9 — Final Task 10.6 and Cross-Task Checkpoint

**Commit:** `test: checkpoint Linux notification pipeline`

**Files:**
- Create: `docs/superpowers/checkpoints/2026-08-02-linux-notification-delivery-platform-wiring-checkpoint.md`
- Modify: `docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md`
- Create: `tool/prepare_phase1_task10_6_checkpoint.py`
- Create: `tool/verify_phase1_task10_6_complete.py`
- Test: all Task 10.4–10.6 focused tests

**Checkpoint requirements:**

- Record exact commit hashes for Gates 10.6.1–10.6.8.
- Record focused and full test counts from fresh logs.
- Record successful `flutter analyze`.
- Record successful Linux debug build.
- Record clean `git diff --check`.
- Record that tests use no real systemd, HOME, notification plugin, or desktop display.
- Mark Task 10.6 implemented.
- Mark Tasks 10.4–10.6 complete.
- Preserve the documented remaining power-loss durability boundary.
- Do not mark unrelated Phase 1 work complete.

- [ ] **Step 1: Run the complete focused suite**

```bash
script -qefc \
  "flutter --color test \
  test/core/notifications/linux_systemd_schedule_registry_model_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_codec_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_file_store_test.dart \
  test/core/notifications/linux_systemd_notification_scheduler_final_checkpoint_test.dart \
  test/core/notifications/drift_notification_schedule_repository_test.dart \
  test/core/notifications/linux_notification_delivery_invocation_test.dart \
  test/core/notifications/linux_notification_delivery_result_test.dart \
  test/core/notifications/linux_executable_path_source_test.dart \
  test/core/notifications/resolved_linux_notification_delivery_command_factory_test.dart \
  test/core/notifications/linux_notification_delivery_service_test.dart \
  test/app/bootstrap/linux_notification_delivery_bootstrap_test.dart \
  test/app/bootstrap/application_entrypoint_test.dart \
  test/core/notifications/notification_platform_providers_test.dart \
  test/core/notifications/notification_startup_service_test.dart \
  test/app/bootstrap/notification_startup_bootstrap_test.dart \
  test/core/notifications/linux_notification_pipeline_integration_test.dart" \
  /tmp/task10-4-to-10-6-focused.log
```

- [ ] **Step 2: Run fresh project verification**

```bash
flutter analyze 2>&1 | tee /tmp/task10-6-analyze.log
script -qefc "flutter --color test" /tmp/task10-6-full.log
flutter build linux --debug 2>&1 | tee /tmp/task10-6-build.log
git diff --check
git status --short
```

- [ ] **Step 3: Generate checkpoint evidence**

```bash
python3 tool/prepare_phase1_task10_6_checkpoint.py \
  --focused-log /tmp/task10-4-to-10-6-focused.log \
  --full-log /tmp/task10-6-full.log \
  --analyze-log /tmp/task10-6-analyze.log \
  --build-log /tmp/task10-6-build.log
```

- [ ] **Step 4: Run the final verifier**

```bash
python3 tool/verify_phase1_task10_6_complete.py
git diff --check
```

The verifier checks exact Gate hashes, test counts, implemented design status, hidden-mode privacy, lazy non-Linux selection, startup single-flight evidence, and the remaining durability boundary.

- [ ] **Step 5: Commit and push**

```bash
git add \
  docs/superpowers/checkpoints/2026-08-02-linux-notification-delivery-platform-wiring-checkpoint.md \
  docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md \
  tool/prepare_phase1_task10_6_checkpoint.py \
  tool/verify_phase1_task10_6_complete.py
git diff --cached --check
git commit -m "test: checkpoint Linux notification pipeline"
git push
git status --short
```

---

## Plan Self-Review

### Spec coverage

- Exact hidden argument parsing: Gate 10.6.2.
- Repository exact lookup: Gate 10.6.1.
- Absolute executable validation and shell-free unit command: Gate 10.6.3.
- Lookup, missing no-op, privacy, payload, display, typed failures, and close handling: Gate 10.6.4.
- No dashboard bootstrap in hidden mode: Gate 10.6.5.
- Linux and non-Linux scheduler selection: Gate 10.6.6.
- Startup reconciliation, single-flight, retry, and non-blocking reporting: Gate 10.6.7.
- Full fake Linux composition and debug-build regression: Gate 10.6.8.
- Cross-task verification and documentation: Gate 10.6.9.

### Type consistency

- `NotificationScheduleRepository.getById` is nullable and exact in every implementation.
- The command factory becomes asynchronous once and every scheduler/fake call site follows that signature.
- Hidden parser, delivery service, bootstrap, and entrypoint use separate interfaces and do not depend on Riverpod.
- Provider composition depends on the existing `NotificationHostPlatform`.
- Normal startup and hidden startup remain mutually exclusive at the application entrypoint.

### Scope

- No deletion of desired Drift state after hidden delivery.
- No direct systemd call outside the existing driver.
- No Task 10.5 scheduler redesign.
- No Android, macOS, or Windows behavior change.
- No UI redesign.
- No explicit fsync/power-loss durability expansion.
