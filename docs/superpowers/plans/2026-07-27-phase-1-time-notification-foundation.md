# Phase 1 Time and Notification Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a platform-independent time and notification foundation that Tasks, Habits, Routines, Challenges, installments, debts, recurring transactions, and daily summaries can share.

**Architecture:** Domain objects and scheduler contracts stay independent from Flutter notification plugins. Drift stores the expected notification schedule, while a coordinator reconciles persisted expectations with the platform adapter. All instants are UTC; local-day calculations use an explicit configurable boundary.

**Tech Stack:** Dart 3.12, Flutter 3.44, Drift 2.34, Riverpod 2.6, flutter_local_notifications 22, timezone 0.11.

## Global Constraints

- No notification page is added to navigation.
- Notification controls live inside the owning feature, such as Task or Habit.
- Persisted instants are UTC.
- Migration from schema version 1 to 2 is non-destructive.
- Reconciliation is idempotent by `scheduleId`.
- Multiple notifications may belong to one owner.
- The domain layer does not import Flutter or plugin types.
- Existing visual behavior is unchanged in Phase 1.

---

## File Map

### Create

- `lib/core/date_time/local_day_boundary.dart`: maps local instants to logical app dates.
- `lib/core/notifications/notification_owner.dart`: owner identity and supported owner types.
- `lib/core/notifications/notification_request.dart`: immutable request for one notification occurrence.
- `lib/core/notifications/notification_scheduler.dart`: platform-independent scheduling contract.
- `lib/core/notifications/notification_schedule.dart`: persisted schedule state.
- `lib/core/notifications/notification_schedule_repository.dart`: persistence contract.
- `lib/core/notifications/drift_notification_schedule_repository.dart`: Drift implementation.
- `lib/core/notifications/notification_coordinator.dart`: persists and reconciles expected schedules.
- `test/support/fake_notification_scheduler.dart`: deterministic scheduler for tests.
- `test/core/date_time/local_day_boundary_test.dart`
- `test/core/notifications/notification_request_test.dart`
- `test/core/notifications/fake_notification_scheduler_test.dart`
- `test/core/notifications/drift_notification_schedule_repository_test.dart`
- `test/core/notifications/notification_coordinator_test.dart`
- `test/core/database/schema_v1_to_v2_migration_test.dart`

### Modify

- `lib/core/database/app_database.dart`: add `NotificationScheduleRows`, schema version 2, and migration.
- `lib/core/database/app_database.g.dart`: regenerate with build_runner.
- `lib/core/providers/persistence_providers.dart`: expose clock, scheduler, repository, and coordinator providers.
- `test/core/database/app_database_test.dart`: expect schema version 2 and notification table.
- `test/core/database/database_restart_test.dart`: verify schedules survive restart.
- `test/core/providers/persistence_providers_test.dart`: verify notification providers use overrides.

---

### Task 1: Local Day Boundary and Notification Domain

**Interfaces produced:**

```dart
final class LocalDayBoundary {
  const LocalDayBoundary({required this.startHour, this.startMinute = 0});
  LocalDate dateFor(DateTime localInstant);
  DateTime nextBoundaryAfter(DateTime localInstant);
}

enum NotificationOwnerType {
  task,
  habit,
  routine,
  challenge,
  installment,
  debt,
  recurringTransaction,
  dailySummary,
}

final class NotificationOwner {
  const NotificationOwner({required this.type, required this.id});
  final NotificationOwnerType type;
  final String id;
}

enum NotificationPrivacyMode { full, private }

final class NotificationRequest {
  NotificationRequest({
    required String scheduleId,
    required NotificationOwner owner,
    required String title,
    required String body,
    required DateTime scheduledAtUtc,
    Map<String, String> payload = const <String, String>{},
    NotificationPrivacyMode privacyMode = NotificationPrivacyMode.full,
  });
}
```

- [ ] Write the three RED domain tests.
- [ ] Run the focused tests and verify they fail because the new contracts do not exist.
- [ ] Implement the minimal domain files.
- [ ] Run focused tests and verify they pass.
- [ ] Run `flutter analyze` and the full test suite.
- [ ] Commit: `feat: add notification domain and local day boundary`

### Task 2: Deterministic Scheduler Contract

**Interface produced:**

```dart
abstract interface class NotificationScheduler {
  Future<void> schedule(NotificationRequest request);
  Future<void> cancel(String scheduleId);
  Future<void> cancelByOwner(NotificationOwner owner);
  Future<void> reconcile(List<NotificationRequest> expected);
}
```

- [ ] Add RED tests for replacement by `scheduleId`, owner cancellation, and idempotent reconciliation.
- [ ] Implement `FakeNotificationScheduler` in test support.
- [ ] Verify deterministic ordering and no duplicates.
- [ ] Commit: `test: add deterministic notification scheduler contract`

### Task 3: Drift Schema Version 2

**Table columns:** `id`, `ownerType`, `ownerId`, `title`, `body`, `scheduledAtUtc`, `payloadJson`, `privacyMode`, `status`, `lastError`, `createdAtUtc`, `updatedAtUtc`.

**Allowed statuses:** `pending`, `scheduled`, `permissionDenied`, `failed`, `canceled`.

- [ ] Add RED schema and migration tests.
- [ ] Add the table and migration from version 1.
- [ ] Regenerate Drift code.
- [ ] Verify old task and finance records remain intact.
- [ ] Commit: `feat: persist notification schedules`

### Task 4: Notification Schedule Repository

**Interface produced:**

```dart
abstract interface class NotificationScheduleRepository {
  Stream<List<NotificationSchedule>> watchAll();
  Future<List<NotificationSchedule>> getActive();
  Future<void> upsert(NotificationSchedule schedule);
  Future<void> delete(String scheduleId);
  Future<void> deleteByOwner(NotificationOwner owner);
  Future<void> replaceExpected(List<NotificationSchedule> schedules);
}
```

- [ ] Test exact round-trip conversion, update, owner deletion, and atomic replacement.
- [ ] Implement Drift repository.
- [ ] Verify restart persistence.
- [ ] Commit: `feat: add notification schedule repository`

### Task 5: Coordinator and Riverpod Providers

**Coordinator behavior:** persist expected state first, call scheduler, update status, retain failure details, and safely retry on next reconciliation.

- [ ] Add RED coordinator tests for success, permission denial, failure retention, cancellation, and retry.
- [ ] Implement coordinator.
- [ ] Add overridable Riverpod providers.
- [ ] Verify provider disposal does not close externally overridden test resources.
- [ ] Commit: `feat: coordinate persisted notification schedules`

### Task 6: Phase Verification

- [ ] Run code generation.
- [ ] Run formatting.
- [ ] Run analyze.
- [ ] Run all tests.
- [ ] Build Linux debug.
- [ ] Confirm no UI screenshot changes.
- [ ] Commit documentation updates if necessary.
