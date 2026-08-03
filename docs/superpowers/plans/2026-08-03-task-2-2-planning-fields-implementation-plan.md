# Task 2.2 Planning Fields Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add complete, persistent, Jalali-aware description, start/due time, and estimated-duration support to Tasks while preserving the existing Task 2.1 guarantees and Liquid Glass experience.

**Architecture:** Extend `TaskItem` with four canonical optional planning fields, migrate Drift schema 3 to 4, and keep `TaskRepository` method signatures stable while expanding mapping. Introduce a pure form-draft/controller layer for normalization and local-time-to-UTC conversion, then build one reusable adaptive Liquid Glass create/edit dialog with custom Jalali date/time controls and integrate it alongside the existing quick-add flow.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Riverpod, Drift, SQLite, `shamsi_date`, existing Original/Liquid Glass design system, Flutter widget tests, Python semantic verifiers.

## Global Constraints

- Repository: `https://github.com/majidsii/dashboard-shakhsi`
- Worktree: `~/projects/personal/dashboard-shakhsi-v2-integration`
- Branch: `feat/v2-complete-dashboard`
- Task 2.1 checkpoint must remain green before and after every Gate.
- Canonical persisted timestamps are UTC.
- User-facing task dates are Jalali and user-facing times use device-local wall-clock time.
- Existing quick add remains available.
- A complete add-with-details path and a complete edit-details path are required.
- The create and edit paths use one shared form implementation.
- The existing Liquid Glass design language is a hard acceptance criterion.
- No generic Material dialog, generic Gregorian date picker, or unrelated redesign is allowed.
- Description is nullable plain text, trimmed, and blank values normalize to `null`.
- `startAtUtc` and `dueAtUtc` are nullable and independent.
- If both times exist, `dueAtUtc` must be equal to or later than `startAtUtc`.
- `estimatedDurationMinutes` is nullable and must be positive when present.
- Reminder, recurrence, calendar view, Kanban/List v2, timer, actual time, tags, subtasks, goal/challenge links, trash, and audit history remain outside Task 2.2.
- Do not use `set -e` in pasteable commands.
- Every Gate follows RED → observed valid failure → GREEN → focused tests → analyze → full tests → Linux build → `git diff --check` → focused commit/push.
- Verifiers must use semantic/whitespace-tolerant checks and must not depend on `dart format` line wrapping.
- Stage only files belonging to the current Gate.
- Never claim test, analyze, build, or push success without observed output.

---

## File Structure and Responsibility Map

### Existing files modified

- `lib/features/tasks/domain/task_item.dart`
  - Canonical planning fields, normalization, validation, equality, `copyWith`.
- `lib/core/database/app_database.dart`
  - Schema version 4, new task columns, database constraints, 3→4 migration.
- `lib/core/database/app_database.g.dart`
  - Drift-generated schema and companions.
- `lib/features/tasks/data/drift_task_repository.dart`
  - Task planning-field mapping on create, update, watch, and get.
- `lib/features/dashboard/presentation/widgets/tasks_panel.dart`
  - Keep quick add, add detailed-entry action, open shared edit dialog, render concise planning metadata.
- `test/features/tasks/domain/task_item_test.dart`
  - Canonical domain tests.
- `test/features/tasks/data/drift_task_repository_test.dart`
  - Persistence and clearing tests.
- `test/features/tasks/data/drift_task_repository_transition_test.dart`
  - Transition/reorder preservation tests.
- `test/core/database/database_restart_test.dart`
  - Schema-4 and planning-field restart proof.
- `test/features/dashboard/tasks_panel_test.dart`
  - Real-Drift UI integration.
- `test/features/dashboard/tasks_panel_persistence_test.dart`
  - Repository interaction and compatibility tests.
- `docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md`
  - Link Task 2.2 implementation checkpoint after completion only.

### New production files

- `lib/features/tasks/presentation/task_details/task_details_draft.dart`
  - Pure editable form state, field normalization, validation, local/Jalali selection to UTC conversion, `TaskItem` creation/update projection.
- `lib/features/tasks/presentation/task_details/task_details_dialog.dart`
  - Shared adaptive Liquid Glass create/edit shell and save orchestration.
- `lib/features/tasks/presentation/task_details/task_details_form.dart`
  - Reusable form content and field composition.
- `lib/features/tasks/presentation/task_details/task_jalali_date_time_field.dart`
  - Liquid Glass Jalali date and local-time picker field with explicit clear.
- `lib/features/tasks/presentation/task_details/task_duration_field.dart`
  - Hours/minutes input normalized to total minutes.
- `lib/features/tasks/presentation/task_details/task_planning_labels.dart`
  - Concise RTL Jalali/local metadata labels for task rows.

### New test files

- `test/core/database/task_planning_migration_test.dart`
- `test/features/tasks/presentation/task_details/task_details_draft_test.dart`
- `test/features/tasks/presentation/task_details/task_jalali_date_time_field_test.dart`
- `test/features/tasks/presentation/task_details/task_duration_field_test.dart`
- `test/features/tasks/presentation/task_details/task_details_dialog_test.dart`
- `test/features/tasks/presentation/task_details/task_planning_labels_test.dart`

### New stable verification files

- `tool/verify_phase2_task2_2_1_green.py`
- `tool/verify_phase2_task2_2_2_green.py`
- `tool/verify_phase2_task2_2_3_green.py`
- `tool/verify_phase2_task2_2_4_green.py`
- `tool/verify_phase2_task2_2_5_green.py`
- `tool/verify_phase2_task2_2_6_green.py`
- `tool/verify_phase2_task2_2_7_green.py`
- `tool/verify_phase2_task2_2_complete.py`
- `docs/superpowers/checkpoints/2026-08-03-task-2-2-planning-fields-checkpoint.md`

---

# Gate 2.2.1 — Canonical Task Planning Domain

**Deliverable:** `TaskItem` owns normalized and validated description, start, due, and estimated-duration state without changing Task 2.1 identity/status behavior.

**Files:**
- Modify: `lib/features/tasks/domain/task_item.dart`
- Modify: `test/features/tasks/domain/task_item_test.dart`
- Create: `tool/verify_phase2_task2_2_1_green.py`

**Interfaces:**
- Produces:
  ```dart
  final String? description;
  final DateTime? startAtUtc;
  final DateTime? dueAtUtc;
  final int? estimatedDurationMinutes;
  ```
- Produces `copyWith` explicit-clear flags:
  ```dart
  bool clearDescription = false,
  bool clearStartAt = false,
  bool clearDueAt = false,
  bool clearEstimatedDuration = false,
  ```
- Preserves all existing constructor call sites by keeping every new constructor parameter optional.

- [ ] **Step 1: Confirm clean Task 2.1 baseline**

Run:

```bash
cd ~/projects/personal/dashboard-shakhsi-v2-integration
git status --short
python3 tool/verify_phase2_task2_1_complete.py
```

Expected:

```text
working tree has no changes
Task 2.1 verifier prints OK
```

- [ ] **Step 2: Write failing domain tests**

Add tests to `test/features/tasks/domain/task_item_test.dart` that construct:

```dart
final task = TaskItem(
  id: 'planning-task',
  displayNumber: 12,
  title: '  برنامه‌ریزی انتشار  ',
  description: '  توضیح چندخطی\nبرای انتشار  ',
  priority: 2,
  status: TaskStatus.planned,
  positionInStatus: 0,
  startAtUtc: DateTime.utc(2026, 8, 4, 8),
  dueAtUtc: DateTime.utc(2026, 8, 4, 10),
  estimatedDurationMinutes: 90,
  createdAtUtc: DateTime.utc(2026, 8, 3, 12),
  updatedAtUtc: DateTime.utc(2026, 8, 3, 12),
);
```

Assert:

```dart
expect(task.description, 'توضیح چندخطی\nبرای انتشار');
expect(task.startAtUtc, DateTime.utc(2026, 8, 4, 8));
expect(task.dueAtUtc, DateTime.utc(2026, 8, 4, 10));
expect(task.estimatedDurationMinutes, 90);
```

Add separate tests for:

```dart
description: '   ' // canonical value must be null
```

```dart
startAtUtc: DateTime(2026, 8, 4, 8) // must throw ValidationFailure
```

```dart
dueAtUtc: DateTime(2026, 8, 4, 10) // must throw ValidationFailure
```

```dart
startAtUtc: DateTime.utc(2026, 8, 4, 10),
dueAtUtc: DateTime.utc(2026, 8, 4, 9), // must throw
```

```dart
estimatedDurationMinutes: 0 // must throw
estimatedDurationMinutes: -1 // must throw
```

Verify equality changes when each new field changes.

Verify explicit clearing:

```dart
final cleared = task.copyWith(
  clearDescription: true,
  clearStartAt: true,
  clearDueAt: true,
  clearEstimatedDuration: true,
  updatedAtUtc: DateTime.utc(2026, 8, 3, 13),
);
expect(cleared.description, isNull);
expect(cleared.startAtUtc, isNull);
expect(cleared.dueAtUtc, isNull);
expect(cleared.estimatedDurationMinutes, isNull);
```

- [ ] **Step 3: Run RED**

Run:

```bash
flutter test test/features/tasks/domain/task_item_test.dart
```

Expected: compile failures for missing constructor parameters/getters, proving Task 2.2 domain state is absent.

- [ ] **Step 4: Implement canonical fields**

In `TaskItem`:

```dart
TaskItem({
  required this.id,
  required this.displayNumber,
  required String title,
  String? description,
  required this.priority,
  required this.status,
  required this.positionInStatus,
  this.startAtUtc,
  this.dueAtUtc,
  this.estimatedDurationMinutes,
  required this.createdAtUtc,
  required this.updatedAtUtc,
  this.completedAtUtc,
  this.canceledAtUtc,
}) : title = title.trim(),
     description = _normalizeOptionalText(description) {
  // existing validation

  final startAt = startAtUtc;
  if (startAt != null) {
    _validateUtc(startAt);
  }

  final dueAt = dueAtUtc;
  if (dueAt != null) {
    _validateUtc(dueAt);
  }

  if (startAt != null && dueAt != null && dueAt.isBefore(startAt)) {
    throw const ValidationFailure(
      'زمان سررسید نمی‌تواند قبل از زمان شروع باشد.',
    );
  }

  final estimatedDuration = estimatedDurationMinutes;
  if (estimatedDuration != null && estimatedDuration <= 0) {
    throw const ValidationFailure('مدت تخمینی کار باید بیشتر از صفر باشد.');
  }
}
```

Add:

```dart
String? _normalizeOptionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
```

Extend `copyWith`, equality, `hashCode`, and diagnostics with the exact new fields.

Do not modify Task 2.1 terminal timestamp rules.

- [ ] **Step 5: Format and run GREEN**

Run:

```bash
dart format \
  lib/features/tasks/domain/task_item.dart \
  test/features/tasks/domain/task_item_test.dart

flutter test test/features/tasks/domain/task_item_test.dart
```

Expected: all domain tests pass.

- [ ] **Step 6: Add semantic Gate verifier**

`tool/verify_phase2_task2_2_1_green.py` must:

- parse `task_item.dart`;
- find all four canonical field declarations with whitespace-tolerant regex;
- verify constructor accepts all four;
- verify `_validateUtc` is applied to both planning timestamps;
- verify due-before-start rejection is present;
- verify positive estimated-duration validation;
- verify description normalization;
- verify clear flags exist;
- verify the focused test file contains valid/invalid/clear/equality coverage.

It must not assert exact line wrapping or local-variable names.

Run:

```bash
python3 -m py_compile tool/verify_phase2_task2_2_1_green.py
python3 tool/verify_phase2_task2_2_1_green.py
```

Expected: `OK`.

- [ ] **Step 7: Full Gate verification**

Run:

```bash
flutter analyze
flutter test
flutter build linux --debug
git diff --check
```

Record exact outputs for the Gate checkpoint.

- [ ] **Step 8: Commit and push Gate 2.2.1**

Run:

```bash
git add \
  lib/features/tasks/domain/task_item.dart \
  test/features/tasks/domain/task_item_test.dart \
  tool/verify_phase2_task2_2_1_green.py

git diff --cached --check
git diff --cached --name-only
git commit -m "feat: add canonical task planning fields"
git push
```

---

# Gate 2.2.2 — Schema Version 4 and Deterministic Migration

**Deliverable:** Drift schema 4 stores all planning fields, migrates schema 3 deterministically, preserves all Task 2.1 data, and enforces persistence constraints.

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/core/database/app_database.g.dart`
- Create: `test/core/database/task_planning_migration_test.dart`
- Modify: `test/core/database/database_restart_test.dart`
- Create: `tool/verify_phase2_task2_2_2_green.py`

**Interfaces:**
- Produces Drift row/companion columns:
  ```dart
  description
  startAtUtc
  dueAtUtc
  estimatedDurationMinutes
  ```
- Advances:
  ```dart
  int get schemaVersion => 4;
  ```

- [ ] **Step 1: Write schema-3 fixture migration test**

Create `test/core/database/task_planning_migration_test.dart`.

The fixture must create the exact schema-3 `tasks` table currently represented by Task 2.1, insert at least:

- one planned task;
- one in-progress task;
- one completed task with completion timestamp;
- one canceled task with cancellation timestamp;
- nontrivial display numbers and status-local positions.

Set:

```sql
PRAGMA user_version = 3;
```

After opening with `AppDatabase`, assert:

```dart
expect(database.schemaVersion, 4);
expect(userVersion, 4);
```

Assert all legacy fields are unchanged and all new fields are `null`.

Assert `PRAGMA table_info(tasks)` contains:

```text
description
start_at_utc
due_at_utc
estimated_duration_minutes
```

Close and reopen the same file and compare a deterministic snapshot.

Add direct constraint tests:

```sql
INSERT ... estimated_duration_minutes = 0
```

must fail.

```sql
INSERT ... start_at_utc > due_at_utc
```

must fail when both are present.

- [ ] **Step 2: Run RED**

Run:

```bash
flutter test test/core/database/task_planning_migration_test.dart
```

Expected: schema version/column failures because schema 4 does not exist.

- [ ] **Step 3: Extend `TaskRows` and migration**

Add nullable columns:

```dart
TextColumn get description => text().nullable()();
DateTimeColumn get startAtUtc => dateTime().nullable()();
DateTimeColumn get dueAtUtc => dateTime().nullable()();
IntColumn get estimatedDurationMinutes => integer().nullable()();
```

Add constraints:

```dart
'estimated_duration_minutes IS NULL '
    'OR estimated_duration_minutes > 0',
'start_at_utc IS NULL OR due_at_utc IS NULL '
    'OR due_at_utc >= start_at_utc',
```

Advance schema version to 4.

Implement the 3→4 migration using deterministic table reconstruction so the final table owns all required checks:

```text
ALTER TABLE tasks RENAME TO tasks_v3_legacy
create schema-4 tasks
INSERT legacy columns plus NULL planning columns
DROP tasks_v3_legacy
```

The `INSERT ... SELECT` must preserve every Task 2.1 column without recomputing display numbers, status, or positions.

Keep existing `from < 2` and `from < 3` migration behavior intact so 1→4 and 2→4 upgrades run in sequence.

- [ ] **Step 4: Regenerate Drift code**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` contains nullable generated columns and companion values for all four fields.

- [ ] **Step 5: Format and run focused migration tests**

Run:

```bash
dart format \
  lib/core/database/app_database.dart \
  test/core/database/task_planning_migration_test.dart \
  test/core/database/database_restart_test.dart

flutter test \
  test/core/database/task_planning_migration_test.dart \
  test/core/database/task_status_migration_test.dart \
  test/core/database/notification_schedule_migration_test.dart \
  test/core/database/database_restart_test.dart
```

Expected: all migration/restart tests pass.

- [ ] **Step 6: Add semantic verifier**

The verifier must check:

- schema version is exactly 4;
- four nullable columns exist;
- positive-duration and start/due constraints exist semantically;
- `from < 4` branch exists;
- migration copies every Task 2.1 column unchanged;
- migration assigns `NULL` to all new columns;
- migration test creates a schema-3 fixture and reopens it;
- generated Drift file contains all four generated columns.

Avoid exact multiline SQL string matching; normalize whitespace before semantic checks.

- [ ] **Step 7: Full Gate verification**

Run:

```bash
python3 -m py_compile tool/verify_phase2_task2_2_2_green.py
python3 tool/verify_phase2_task2_2_2_green.py
flutter analyze
flutter test
flutter build linux --debug
git diff --check
```

- [ ] **Step 8: Commit and push Gate 2.2.2**

Run:

```bash
git add \
  lib/core/database/app_database.dart \
  lib/core/database/app_database.g.dart \
  test/core/database/task_planning_migration_test.dart \
  test/core/database/database_restart_test.dart \
  tool/verify_phase2_task2_2_2_green.py

git diff --cached --check
git diff --cached --name-only
git commit -m "feat: migrate tasks to planning schema"
git push
```

---

# Gate 2.2.3 — Repository Mapping and Restart Persistence

**Deliverable:** Drift repository round-trips, updates, clears, and preserves planning fields through transitions, reorders, and restart.

**Files:**
- Modify: `lib/features/tasks/data/drift_task_repository.dart`
- Modify: `test/features/tasks/data/drift_task_repository_test.dart`
- Modify: `test/features/tasks/data/drift_task_repository_transition_test.dart`
- Modify: `test/core/database/database_restart_test.dart`
- Modify as required for constructor compatibility:
  - `test/core/providers/persistence_providers_test.dart`
  - `test/features/dashboard/tasks_panel_test.dart`
  - `test/features/dashboard/tasks_panel_persistence_test.dart`
- Create: `tool/verify_phase2_task2_2_3_green.py`

**Interfaces:**
- Keeps `TaskRepository` method signatures unchanged.
- Produces exact row mapping of the four new fields.

- [ ] **Step 1: Write failing repository round-trip tests**

Create a task with all fields populated, call `create`, then `getById`.

Assert exact canonical values.

Update it to different values and assert:

- `displayNumber` unchanged;
- `createdAtUtc` unchanged;
- planning fields changed;
- status and position unchanged unless explicitly changed by existing behavior.

Clear all optional fields through `copyWith(clear...)`, call `update`, and assert all stored fields are null.

- [ ] **Step 2: Write preservation tests**

In transition tests:

1. Create a planned task with all planning fields.
2. Transition it to completed.
3. Reopen it to planned.
4. Reorder it.
5. Assert every planning field remains unchanged.

In restart test:

1. Persist planning values.
2. Close database.
3. Reopen.
4. Assert exact values and UTC instants.

- [ ] **Step 3: Run RED**

Run:

```bash
flutter test \
  test/features/tasks/data/drift_task_repository_test.dart \
  test/features/tasks/data/drift_task_repository_transition_test.dart \
  test/core/database/database_restart_test.dart
```

Expected: stored values are null or mapping compilation fails.

- [ ] **Step 4: Extend repository mapping**

In `_taskFromRow`:

```dart
description: row.description,
startAtUtc: row.startAtUtc?.toUtc(),
dueAtUtc: row.dueAtUtc?.toUtc(),
estimatedDurationMinutes: row.estimatedDurationMinutes,
```

In `_companionFromTask`:

```dart
description: Value<String?>(task.description),
startAtUtc: Value<DateTime?>(task.startAtUtc),
dueAtUtc: Value<DateTime?>(task.dueAtUtc),
estimatedDurationMinutes: Value<int?>(task.estimatedDurationMinutes),
```

In `update` add nullable writes using `Value<T?>`.

Do not add a new repository method.

Do not alter display-number allocation, status-position allocation, transition logic, reorder logic, delete compaction, or terminal timestamps.

- [ ] **Step 5: Format and run focused tests**

Run:

```bash
dart format \
  lib/features/tasks/data/drift_task_repository.dart \
  test/features/tasks/data/drift_task_repository_test.dart \
  test/features/tasks/data/drift_task_repository_transition_test.dart \
  test/core/database/database_restart_test.dart

flutter test \
  test/features/tasks/data/drift_task_repository_test.dart \
  test/features/tasks/data/drift_task_repository_transition_test.dart \
  test/core/database/database_restart_test.dart
```

Expected: all pass.

- [ ] **Step 6: Add verifier**

Check semantically:

- row-to-domain mapping for all fields;
- companion mapping for all fields;
- update mapping for all fields;
- UTC normalization on read;
- tests for create/update/clear/restart/transition preservation;
- `TaskRepository` has not gained Task-2.2-only methods;
- Task 2.1 allocation and transition helper tokens remain present.

- [ ] **Step 7: Full Gate verification**

Run:

```bash
python3 -m py_compile tool/verify_phase2_task2_2_3_green.py
python3 tool/verify_phase2_task2_2_3_green.py
python3 tool/verify_phase2_task2_1_complete.py
flutter analyze
flutter test
flutter build linux --debug
git diff --check
```

- [ ] **Step 8: Commit and push Gate 2.2.3**

Run:

```bash
git add \
  lib/features/tasks/data/drift_task_repository.dart \
  test/features/tasks/data/drift_task_repository_test.dart \
  test/features/tasks/data/drift_task_repository_transition_test.dart \
  test/core/database/database_restart_test.dart \
  test/core/providers/persistence_providers_test.dart \
  test/features/dashboard/tasks_panel_test.dart \
  test/features/dashboard/tasks_panel_persistence_test.dart \
  tool/verify_phase2_task2_2_3_green.py

git diff --cached --check
git diff --cached --name-only
git commit -m "feat: persist task planning details"
git push
```

Only stage compatibility test files if they actually changed.

---

# Gate 2.2.4 — Pure Task Details Draft and Validation

**Deliverable:** A UI-independent form draft owns normalization, validation, local-time conversion, duration conversion, and create/update projection.

**Files:**
- Create: `lib/features/tasks/presentation/task_details/task_details_draft.dart`
- Create: `test/features/tasks/presentation/task_details/task_details_draft_test.dart`
- Create: `tool/verify_phase2_task2_2_4_green.py`

**Interfaces:**
- Produces:
  ```dart
  final class TaskDetailsDraft
  ```
- Required factories:
  ```dart
  TaskDetailsDraft.create({
    required DateTime nowLocal,
    int priority = 0,
  });

  TaskDetailsDraft.fromTask(TaskItem task);
  ```
- Required normalized projection methods:
  ```dart
  TaskItem buildNewTask({
    required String id,
    required DateTime savedAtUtc,
  });

  TaskItem applyTo({
    required TaskItem task,
    required DateTime savedAtUtc,
  });
  ```
- Required pure validation result:
  ```dart
  Map<TaskDetailsField, String> validate();
  ```
- Required enum:
  ```dart
  enum TaskDetailsField {
    title,
    startAt,
    dueAt,
    estimatedDuration,
  }
  ```

- [ ] **Step 1: Write failing draft tests**

Tests must cover:

- create mode defaults;
- edit mode prepopulation;
- title trimming;
- blank description normalization;
- local start/due conversion to UTC;
- UTC values converted to local when loading edit mode;
- due-before-start error mapped to `TaskDetailsField.dueAt`;
- hours/minutes normalization:
  ```text
  1 hour + 30 minutes = 90
  0 hours + 0 minutes = null
  0 hours + negative minutes = validation error
  1 hour + 75 minutes is normalized or rejected by one explicit contract
  ```
  Use the recommended explicit contract: minute input range `0..59`; hours `>= 0`; both zero means null.
- create projection uses placeholder display number/position because repository owns final allocation;
- update projection preserves immutable identity and current status/order/terminal timestamps;
- explicit clear behavior.

- [ ] **Step 2: Run RED**

Run:

```bash
flutter test \
  test/features/tasks/presentation/task_details/task_details_draft_test.dart
```

Expected: missing file/type compile failure.

- [ ] **Step 3: Implement pure draft**

Use mutable form-friendly values but no Flutter widget dependency.

Recommended state:

```dart
final class TaskDetailsDraft {
  TaskDetailsDraft({
    required this.title,
    required this.description,
    required this.priority,
    required this.startLocal,
    required this.dueLocal,
    required this.estimatedHours,
    required this.estimatedMinutes,
  });

  String title;
  String description;
  int priority;
  DateTime? startLocal;
  DateTime? dueLocal;
  int estimatedHours;
  int estimatedMinutes;
}
```

Projection rules:

```dart
final startAtUtc = startLocal?.toUtc();
final dueAtUtc = dueLocal?.toUtc();
final totalMinutes = estimatedHours == 0 && estimatedMinutes == 0
    ? null
    : estimatedHours * 60 + estimatedMinutes;
```

`buildNewTask` creates:

```dart
status: TaskStatus.planned
positionInStatus: 0
displayNumber: 1
createdAtUtc: savedAtUtc
updatedAtUtc: savedAtUtc
```

Repository remains responsible for final display number and append position; TasksPanel will transition new detailed tasks to position zero after creation, matching quick add.

`applyTo` must call `copyWith` and use explicit clear flags when optional fields are absent.

- [ ] **Step 4: Format and run GREEN**

Run:

```bash
dart format \
  lib/features/tasks/presentation/task_details/task_details_draft.dart \
  test/features/tasks/presentation/task_details/task_details_draft_test.dart

flutter test \
  test/features/tasks/presentation/task_details/task_details_draft_test.dart
```

- [ ] **Step 5: Add semantic verifier**

Verify:

- file has no `material.dart` or widget import;
- create/fromTask/buildNewTask/applyTo exist;
- `.toLocal()` is used on edit initialization;
- `.toUtc()` is used on projection;
- minute range and due ordering are tested;
- Task 2.1 immutable/status fields are preserved by update projection.

- [ ] **Step 6: Full Gate verification and commit**

Run:

```bash
python3 -m py_compile tool/verify_phase2_task2_2_4_green.py
python3 tool/verify_phase2_task2_2_4_green.py
flutter analyze
flutter test
flutter build linux --debug
git diff --check

git add \
  lib/features/tasks/presentation/task_details/task_details_draft.dart \
  test/features/tasks/presentation/task_details/task_details_draft_test.dart \
  tool/verify_phase2_task2_2_4_green.py

git diff --cached --check
git diff --cached --name-only
git commit -m "feat: add task details draft validation"
git push
```

---

# Gate 2.2.5 — Liquid Glass Jalali Date/Time and Duration Controls

**Deliverable:** Reusable, tested Liquid Glass controls support Jalali date/local time selection, explicit clearing, and estimated-duration input without generic Gregorian Material pickers.

**Files:**
- Create: `lib/features/tasks/presentation/task_details/task_jalali_date_time_field.dart`
- Create: `lib/features/tasks/presentation/task_details/task_duration_field.dart`
- Create: `test/features/tasks/presentation/task_details/task_jalali_date_time_field_test.dart`
- Create: `test/features/tasks/presentation/task_details/task_duration_field_test.dart`
- Create: `tool/verify_phase2_task2_2_5_green.py`

**Interfaces:**
- Produces:
  ```dart
  final class TaskJalaliDateTimeField extends StatelessWidget
  ```
  with:
  ```dart
  String label;
  DateTime? valueLocal;
  ValueChanged<DateTime?> onChanged;
  String? errorText;
  ```
- Produces:
  ```dart
  final class TaskDurationField extends StatelessWidget
  ```
  with controlled hour/minute values and change callbacks.

- [ ] **Step 1: Write failing widget tests for date/time field**

Test:

- null state renders Persian “تنظیم نشده” label;
- selected local date renders Jalali year/month/day and local time;
- tapping date section opens a custom Liquid Glass Jalali selector, not `showDatePicker`;
- tapping time section opens a project-styled time selector;
- clear action calls `onChanged(null)`;
- selecting date preserves selected time;
- selecting time preserves selected Jalali date;
- field displays Persian inline error.

The test must search for stable semantic labels such as:

```text
انتخاب تاریخ شروع
انتخاب ساعت شروع
پاک کردن زمان شروع
```

- [ ] **Step 2: Write failing duration field tests**

Test:

- empty/zero state;
- hours input;
- minute input restricted to `0..59`;
- Persian labels;
- clear action;
- keyboard numeric input;
- narrow-width wrapping without overflow;
- inline error rendering.

- [ ] **Step 3: Run RED**

Run:

```bash
flutter test \
  test/features/tasks/presentation/task_details/task_jalali_date_time_field_test.dart \
  test/features/tasks/presentation/task_details/task_duration_field_test.dart
```

Expected: missing widget files/types.

- [ ] **Step 4: Implement Jalali control**

Use `shamsi_date`.

Display conversion:

```dart
final local = valueLocal!;
final jalali = Jalali.fromDateTime(local);
```

Date selection must operate on `Jalali` values and convert selected Jalali date back to a local `DateTime` while preserving the selected local hour/minute.

Do not call Flutter’s Gregorian `showDatePicker`.

The selector must use existing project components:

```text
OriginalGlass / OriginalFieldSurface
OriginalPrimaryButton
OriginalPressable
OriginalPalette
OriginalDesignTokens
Vazirmatn typography through current theme
```

Use a month grid with previous/next month controls, weekday headers in Persian, selected-day state, today state, and keyboard-accessible semantics.

Use local `TimeOfDay` only as an in-memory interaction representation; resulting `DateTime` remains local until draft projection.

- [ ] **Step 5: Implement duration control**

Use two numeric inputs:

```text
ساعت
دقیقه
```

Rules:

- hours `>= 0`;
- minutes `0..59`;
- both zero means unset;
- explicit clear resets both to zero;
- no artificial maximum hours.

Use existing Liquid Glass fields and tokens.

- [ ] **Step 6: Run focused GREEN and overflow variants**

Run:

```bash
dart format \
  lib/features/tasks/presentation/task_details/task_jalali_date_time_field.dart \
  lib/features/tasks/presentation/task_details/task_duration_field.dart \
  test/features/tasks/presentation/task_details/task_jalali_date_time_field_test.dart \
  test/features/tasks/presentation/task_details/task_duration_field_test.dart

flutter test \
  test/features/tasks/presentation/task_details/task_jalali_date_time_field_test.dart \
  test/features/tasks/presentation/task_details/task_duration_field_test.dart
```

Tests must include widths representative of desktop and narrow screens.

- [ ] **Step 7: Add verifier**

The verifier must ensure:

- `Jalali.fromDateTime` is used;
- no `showDatePicker` call exists;
- project Liquid Glass components/tokens are imported and used;
- clear semantics exist;
- date and time are controlled independently without dropping the other component;
- duration minute bounds are tested;
- narrow widget tests exist.

- [ ] **Step 8: Full verification and commit**

Run:

```bash
python3 -m py_compile tool/verify_phase2_task2_2_5_green.py
python3 tool/verify_phase2_task2_2_5_green.py
flutter analyze
flutter test
flutter build linux --debug
git diff --check

git add \
  lib/features/tasks/presentation/task_details/task_jalali_date_time_field.dart \
  lib/features/tasks/presentation/task_details/task_duration_field.dart \
  test/features/tasks/presentation/task_details/task_jalali_date_time_field_test.dart \
  test/features/tasks/presentation/task_details/task_duration_field_test.dart \
  tool/verify_phase2_task2_2_5_green.py

git diff --cached --check
git diff --cached --name-only
git commit -m "feat: add liquid glass task planning controls"
git push
```

---

# Gate 2.2.6 — Shared Adaptive Create/Edit Dialog

**Deliverable:** One professional adaptive Liquid Glass dialog creates and edits full task details, validates inline, prevents duplicate saves, and keeps failures open and recoverable.

**Files:**
- Create: `lib/features/tasks/presentation/task_details/task_details_form.dart`
- Create: `lib/features/tasks/presentation/task_details/task_details_dialog.dart`
- Create: `test/features/tasks/presentation/task_details/task_details_dialog_test.dart`
- Create: `tool/verify_phase2_task2_2_6_green.py`

**Interfaces:**
- Produces:
  ```dart
  enum TaskDetailsDialogMode { create, edit }
  ```
- Produces:
  ```dart
  Future<TaskItem?> showTaskDetailsDialog({
    required BuildContext context,
    required TaskDetailsDialogMode mode,
    TaskItem? initialTask,
    DateTime Function()? now,
    String Function()? nextId,
  });
  ```
- The dialog returns a validated `TaskItem`; repository writes remain owned by `TasksPanel`.

- [ ] **Step 1: Write failing dialog tests**

Cover:

- create mode renders all fields;
- edit mode prepopulates title, priority, description, start, due, duration;
- title required;
- due-before-start inline error;
- duration minute-range inline error;
- save returns canonical TaskItem;
- edit save preserves identity/status/order;
- clear buttons remove optional values;
- save button disables while submission is in progress;
- repeated taps produce one result;
- desktop width renders bounded centered glass surface;
- narrow width renders full-screen/near-full-screen adaptive shell;
- no default `AlertDialog` or plain `Dialog` visual contract is used;
- escape/back/cancel returns null without mutation;
- widget remains open after injected save callback failure if save orchestration is implemented inside dialog.

- [ ] **Step 2: Run RED**

Run:

```bash
flutter test \
  test/features/tasks/presentation/task_details/task_details_dialog_test.dart
```

Expected: missing types.

- [ ] **Step 3: Implement shared form**

`TaskDetailsForm` must own controllers and update one `TaskDetailsDraft`.

Fields:

```text
عنوان
اولویت
توضیحات
زمان شروع
زمان سررسید
مدت تخمینی
```

Description uses a multi-line existing Liquid Glass text field.

Errors are keyed by `TaskDetailsField`.

Use focus order and Persian semantics.

- [ ] **Step 4: Implement adaptive dialog shell**

Use `LayoutBuilder`:

```text
wide: centered bounded glass panel
narrow: SafeArea, near-full-screen glass surface
```

Requirements:

- scrolling content;
- keyboard-safe bottom inset;
- cancel and primary save actions;
- saving progress state;
- mounted checks;
- no silent close on invalid data;
- no duplicated create/edit form implementation.

- [ ] **Step 5: Run focused GREEN**

Run:

```bash
dart format \
  lib/features/tasks/presentation/task_details/task_details_form.dart \
  lib/features/tasks/presentation/task_details/task_details_dialog.dart \
  test/features/tasks/presentation/task_details/task_details_dialog_test.dart

flutter test \
  test/features/tasks/presentation/task_details/task_details_dialog_test.dart
```

- [ ] **Step 6: Add verifier**

Verify:

- one shared form used for both modes;
- exact field set;
- existing Liquid Glass components/tokens used;
- adaptive width branch exists;
- default Material `AlertDialog` is absent;
- duplicate-save protection exists;
- all validation cases and clear actions are tested.

- [ ] **Step 7: Full verification and commit**

Run:

```bash
python3 -m py_compile tool/verify_phase2_task2_2_6_green.py
python3 tool/verify_phase2_task2_2_6_green.py
flutter analyze
flutter test
flutter build linux --debug
git diff --check

git add \
  lib/features/tasks/presentation/task_details/task_details_form.dart \
  lib/features/tasks/presentation/task_details/task_details_dialog.dart \
  test/features/tasks/presentation/task_details/task_details_dialog_test.dart \
  tool/verify_phase2_task2_2_6_green.py

git diff --cached --check
git diff --cached --name-only
git commit -m "feat: add adaptive task details dialog"
git push
```

---

# Gate 2.2.7 — Tasks Panel Integration, Metadata, and Checkpoint

**Deliverable:** Existing quick add stays intact, add-with-details and complete edit flows work through Drift, concise planning metadata renders in the current Liquid Glass row, and Task 2.2 receives a fresh checkpoint.

**Files:**
- Create: `lib/features/tasks/presentation/task_details/task_planning_labels.dart`
- Create: `test/features/tasks/presentation/task_details/task_planning_labels_test.dart`
- Modify: `lib/features/dashboard/presentation/widgets/tasks_panel.dart`
- Modify: `test/features/dashboard/tasks_panel_test.dart`
- Modify: `test/features/dashboard/tasks_panel_persistence_test.dart`
- Create: `tool/verify_phase2_task2_2_7_green.py`
- Create: `tool/verify_phase2_task2_2_complete.py`
- Create: `docs/superpowers/checkpoints/2026-08-03-task-2-2-planning-fields-checkpoint.md`
- Modify after checkpoint: `docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md`

**Interfaces:**
- Produces concise labels:
  ```dart
  String? taskStartLabel(TaskItem task);
  String? taskDueLabel(TaskItem task);
  String? taskEstimatedDurationLabel(TaskItem task);
  ```
- Integrates dialog result through existing repository methods.

- [ ] **Step 1: Write failing planning-label tests**

Cover local/Jalali formatting for:

- start only;
- due only;
- same-day start and due;
- estimated minutes under one hour;
- exact hours;
- hours plus minutes;
- null fields produce null labels.

No reminder/overdue business behavior is introduced.

- [ ] **Step 2: Write failing TasksPanel integration tests**

Real Drift tests:

1. Existing quick add still creates a minimal task and moves it to planned position zero.
2. Add-with-details opens dialog and persists all fields.
3. Remount/restart displays persisted planning metadata.
4. Existing edit button opens full form and updates all fields.
5. Clearing values persists nulls.
6. Existing completion, priority, delete, filters, canceled hiding, numbering, counts, and progress remain green.
7. Narrow panel width has no overflow.
8. Liquid Glass form action has stable Persian semantics.

Memory-repository tests must update fake repository mapping only as required by canonical `TaskItem`; do not create alternate Task 2.2 repository methods.

- [ ] **Step 3: Run RED**

Run:

```bash
flutter test \
  test/features/tasks/presentation/task_details/task_planning_labels_test.dart \
  test/features/dashboard/tasks_panel_test.dart \
  test/features/dashboard/tasks_panel_persistence_test.dart
```

Expected: missing labels/add-with-details behavior/full edit behavior.

- [ ] **Step 4: Implement planning labels**

Use local conversion and `Jalali.fromDateTime`.

Keep labels concise and RTL-safe.

Examples of accepted product form:

```text
شروع: ۱۳ مرداد، ۱۱:۳۰
سررسید: ۱۳ مرداد، ۱۵:۰۰
تخمین: ۱ ساعت و ۳۰ دقیقه
```

Use Persian digits through existing project helpers where available; do not create a competing number-formatting convention inside task details.

- [ ] **Step 5: Integrate add-with-details**

Add a visible but hierarchy-safe action near quick add.

Flow:

```dart
final result = await showTaskDetailsDialog(
  context: context,
  mode: TaskDetailsDialogMode.create,
  nextId: _idGenerator.next,
);
if (result == null) return;

await repository.create(result);
await repository.transition(
  id: result.id,
  status: TaskStatus.planned,
  targetPosition: 0,
  changedAtUtc: result.updatedAtUtc,
);
```

Catch established application failures and show the project-standard error surface. Do not clear or close unrelated quick-add state.

- [ ] **Step 6: Replace title-only edit with complete edit**

Existing edit action opens:

```dart
showTaskDetailsDialog(
  context: context,
  mode: TaskDetailsDialogMode.edit,
  initialTask: task,
)
```

On result:

```dart
await repository.update(updatedTask);
```

The dialog—not a second title-only UI—owns all edits.

- [ ] **Step 7: Render concise metadata**

Add metadata below/near title without changing row identity:

- wrap/flex layout;
- only render values that exist;
- maintain current priority/completion/edit/delete controls;
- preserve animation and numbering;
- no Task 2.3 board redesign.

- [ ] **Step 8: Run focused GREEN**

Run:

```bash
dart format \
  lib/features/tasks/presentation/task_details/task_planning_labels.dart \
  lib/features/dashboard/presentation/widgets/tasks_panel.dart \
  test/features/tasks/presentation/task_details/task_planning_labels_test.dart \
  test/features/dashboard/tasks_panel_test.dart \
  test/features/dashboard/tasks_panel_persistence_test.dart

flutter test \
  test/features/tasks/presentation/task_details/task_planning_labels_test.dart \
  test/features/dashboard/tasks_panel_test.dart \
  test/features/dashboard/tasks_panel_persistence_test.dart \
  test/features/tasks/presentation/task_details/task_details_dialog_test.dart
```

- [ ] **Step 9: Add Gate verifier**

Check semantically:

- quick add still exists;
- add-with-details action exists;
- both create and edit use shared dialog;
- repository create/update and create-position-zero transition are present;
- planning metadata labels are rendered;
- canceled hiding and existing completion transition remain;
- Liquid Glass components remain used;
- tests cover persistence, clearing, narrow layout, and legacy behaviors.

- [ ] **Step 10: Run all Gate verifiers and final fresh verification**

Run:

```bash
python3 tool/verify_phase2_task2_2_1_green.py
python3 tool/verify_phase2_task2_2_2_green.py
python3 tool/verify_phase2_task2_2_3_green.py
python3 tool/verify_phase2_task2_2_4_green.py
python3 tool/verify_phase2_task2_2_5_green.py
python3 tool/verify_phase2_task2_2_6_green.py
python3 tool/verify_phase2_task2_2_7_green.py

flutter analyze 2>&1 | tee /tmp/task-2-2-analyze.log
script -qefc "flutter --color test" /tmp/task-2-2-full.log
flutter build linux --debug 2>&1 | tee /tmp/task-2-2-build.log
git diff --check
```

Record exact focused/full counts from output; do not prefill counts in checkpoint.

- [ ] **Step 11: Commit and push Gate 2.2.7**

Run:

```bash
git add \
  lib/features/tasks/presentation/task_details/task_planning_labels.dart \
  lib/features/dashboard/presentation/widgets/tasks_panel.dart \
  test/features/tasks/presentation/task_details/task_planning_labels_test.dart \
  test/features/dashboard/tasks_panel_test.dart \
  test/features/dashboard/tasks_panel_persistence_test.dart \
  tool/verify_phase2_task2_2_7_green.py

git diff --cached --check
git diff --cached --name-only
git commit -m "feat: integrate task planning details"
git push
```

- [ ] **Step 12: Create checkpoint document**

The checkpoint must contain:

- exact seven Gate commit hashes;
- exact Design commit hash;
- exact Plan commit hash;
- focused test commands and observed counts;
- full test observed count;
- analyze output;
- Linux build output;
- `git diff --check` output;
- schema-3 migration and restart evidence;
- domain invariants;
- repository round-trip/clear/preservation evidence;
- Jalali/local/UTC evidence;
- Liquid Glass/adaptive UI evidence;
- explicit incomplete boundary for Task 2.3 onward.

- [ ] **Step 13: Create final checkpoint verifier**

`tool/verify_phase2_task2_2_complete.py` must:

- validate exact Gate hashes exist in current branch history;
- validate checkpoint contains all hashes;
- validate all seven Gate verifiers pass;
- validate Task 2.1 checkpoint still passes;
- validate schema version 4 and all four fields;
- validate explicit non-goals remain documented;
- validate recorded test/analyze/build/diff evidence;
- avoid brittle formatting checks.

- [ ] **Step 14: Link completed Task 2.2 in Phase 2 design**

Update the Task map entry to:

```markdown
2. **Task 2.2 — Description, Start/Due Time, and Estimated Duration** — **Implemented** ([checkpoint](../checkpoints/2026-08-03-task-2-2-planning-fields-checkpoint.md))
```

Do not mark Task 2.3 or later complete.

- [ ] **Step 15: Verify checkpoint**

Run:

```bash
python3 -m py_compile tool/verify_phase2_task2_2_complete.py
python3 tool/verify_phase2_task2_2_complete.py
git diff --check
```

Expected: `OK` based only on observed evidence.

- [ ] **Step 16: Commit and push checkpoint**

Run:

```bash
git add \
  docs/superpowers/checkpoints/2026-08-03-task-2-2-planning-fields-checkpoint.md \
  docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md \
  tool/verify_phase2_task2_2_complete.py

git diff --cached --check
git diff --cached --name-only
git commit -m "test: checkpoint task planning fields"
git push

git status --short
git status -sb
git log -10 --oneline --decorate
```

Expected final state:

```text
working tree clean
HEAD equals upstream
Task 2.1 checkpoint OK
Task 2.2 checkpoint OK
Next: Task 2.3 — Atomic Board Operations, List, and Kanban Views
```

---

## Plan Self-Review

### Spec coverage

- Domain fields and canonicalization: Gate 2.2.1.
- Schema version 4 and deterministic migration: Gate 2.2.2.
- Repository persistence, clearing, transition preservation, restart: Gate 2.2.3.
- Form normalization, local/UTC conversion, duration normalization: Gate 2.2.4.
- Jalali date/time and Liquid Glass duration controls: Gate 2.2.5.
- Shared create/edit adaptive form: Gate 2.2.6.
- Quick add compatibility, detailed add, complete edit, metadata, checkpoint: Gate 2.2.7.
- All explicit non-goals remain outside implementation.

### Type consistency

Canonical names used across all Gates:

```dart
String? description
DateTime? startAtUtc
DateTime? dueAtUtc
int? estimatedDurationMinutes
```

Form-local names:

```dart
DateTime? startLocal
DateTime? dueLocal
int estimatedHours
int estimatedMinutes
```

Repository method signatures remain unchanged.

### Placeholder scan

The plan contains no unresolved implementation placeholder. Test counts and Gate commit hashes are intentionally recorded only from future observed outputs and are not implementation decisions.
