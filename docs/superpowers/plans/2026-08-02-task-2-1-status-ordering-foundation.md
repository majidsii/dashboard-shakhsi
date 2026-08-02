# Task 2.1 Status and Ordering Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace boolean completion and global task ordering with a durable four-status model, immutable display numbers, independent per-status positions, and deterministic schema-version-3 migration while preserving the current Tasks panel.

**Architecture:** Add the TaskStatus storage contract first, then introduce the v2 TaskItem domain, rebuild the Drift tasks table in an append-only migration, map the repository to the new schema, add transactional transition/reorder operations, and finally adapt the current UI through compatibility behavior. Database and ordering changes remain isolated behind TaskRepository.

**Tech Stack:** Dart 3.12, Flutter, Drift 2.34, SQLite, Riverpod, flutter_test.

## Global Constraints

- Existing schema version 2 user data must migrate without loss.
- Database migrations are append-only after distribution to testers.
- Persisted task timestamps must be UTC.
- Persisted TaskStatus values are exactly `planned`, `inProgress`, `completed`, and `canceled`.
- `displayNumber` is positive, unique, immutable, and never reused.
- `positionInStatus` is zero-based and contiguous inside each status.
- Current Liquid Glass UI and Persian copy must remain unchanged in Task 2.1.
- Reminder, recurrence, timer, Trash, and audit behavior are outside Task 2.1.
- Every Gate uses RED, observed expected failure, minimal GREEN, focused tests, analyze, full tests, Linux debug build, diff check, commit, and push.

---

## File structure

### New files

- `lib/features/tasks/domain/task_status.dart` — canonical status and storage parser.
- `test/features/tasks/domain/task_status_test.dart` — storage contract tests.
- `test/core/database/task_status_migration_test.dart` — schema 2 to 3 migration.
- `test/features/tasks/data/drift_task_repository_transition_test.dart` — transition/reorder atomicity.
- `docs/superpowers/checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md` — final evidence.
- `tool/verify_phase2_task2_1_*.py` — Gate contract verifiers.

### Modified files

- `lib/features/tasks/domain/task_item.dart` — v2 fields and invariants.
- `lib/features/tasks/domain/task_repository.dart` — status-aware reads and writes.
- `lib/features/tasks/data/drift_task_repository.dart` — v3 mapping and transactions.
- `lib/core/database/app_database.dart` — TaskRows v3 and migration.
- `lib/core/database/app_database.g.dart` — generated Drift schema.
- `lib/features/dashboard/presentation/widgets/tasks_panel.dart` — compatibility adapter.
- existing task/domain/database/UI tests — new constructors and assertions.

---

### Gate 2.1.1: TaskStatus domain and storage serialization

**Files:**
- Create: `lib/features/tasks/domain/task_status.dart`
- Create: `test/features/tasks/domain/task_status_test.dart`
- Create: `tool/verify_phase2_task2_1_1_green.py`

**Interfaces:**
- Produces: `enum TaskStatus`
- Produces: `String TaskStatus.storageValue`
- Produces: `TaskStatus? TaskStatus.tryParseStorage(String value)`
- Produces: `TaskStatus TaskStatus.parseStorage(String value)`

- [ ] **Step 1: Write the failing status contract test**

```dart
test('uses explicit stable storage values in workflow order', () {
  expect(
    TaskStatus.values.map((status) => status.storageValue),
    <String>['planned', 'inProgress', 'completed', 'canceled'],
  );
});

test('round trips every storage value', () {
  for (final status in TaskStatus.values) {
    expect(TaskStatus.tryParseStorage(status.storageValue), same(status));
    expect(TaskStatus.parseStorage(status.storageValue), same(status));
  }
});

test('rejects unknown non-canonical storage values', () {
  for (final value in <String>[
    '',
    ' planned',
    'planned ',
    'PLANNED',
    'in_progress',
    'done',
    'cancelled',
  ]) {
    expect(TaskStatus.tryParseStorage(value), isNull);
    expect(
      () => TaskStatus.parseStorage(value),
      throwsA(isA<ValidationFailure>()),
    );
  }
});
```

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test test/features/tasks/domain/task_status_test.dart" \
  /tmp/task2-1-1-red.log
```

Expected: compile failure because `task_status.dart` and `TaskStatus` do not exist.

- [ ] **Step 3: Implement the minimal enum**

```dart
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';

enum TaskStatus {
  planned('planned'),
  inProgress('inProgress'),
  completed('completed'),
  canceled('canceled');

  const TaskStatus(this.storageValue);

  final String storageValue;

  static TaskStatus? tryParseStorage(String value) {
    for (final status in values) {
      if (status.storageValue == value) {
        return status;
      }
    }
    return null;
  }

  static TaskStatus parseStorage(String value) {
    final status = tryParseStorage(value);
    if (status == null) {
      throw const ValidationFailure('وضعیت کار نامعتبر است.');
    }
    return status;
  }
}
```

- [ ] **Step 4: Verify GREEN**

```bash
python3 tool/verify_phase2_task2_1_1_green.py

script -qefc \
  "flutter --color test test/features/tasks/domain/task_status_test.dart" \
  /tmp/task2-1-1-green.log
```

Expected: 3 tests pass.

- [ ] **Step 5: Run project verification**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task2-1-1-full.log
flutter build linux --debug
git diff --check
```

- [ ] **Step 6: Commit**

```bash
git add \
  lib/features/tasks/domain/task_status.dart \
  test/features/tasks/domain/task_status_test.dart \
  tool/verify_phase2_task2_1_1_green.py

git commit -m "feat: add task status storage contract"
git push
```

---

### Gate 2.1.2: TaskItem v2 invariants and compatibility

**Files:**
- Modify: `lib/features/tasks/domain/task_item.dart`
- Modify: `test/features/tasks/domain/task_item_test.dart`
- Modify direct TaskItem fixtures in repository/provider/restart/UI tests
- Create: `tool/verify_phase2_task2_1_2_green.py`

**Interfaces:**
- Consumes: `TaskStatus`
- Produces: canonical `TaskItem` fields:
  `displayNumber`, `status`, `positionInStatus`, `canceledAtUtc`
- Produces: compatibility getters `isDone` and `sortOrder`

- [ ] **Step 1: Add failing invariant tests**

Test exact fields, title trimming, positive display number, non-negative position,
UTC timestamps, terminal timestamp requirements, active timestamp clearing,
copyWith transitions, equality, and compatibility getters.

Core expected construction:

```dart
final task = TaskItem(
  id: 'task-1',
  displayNumber: 7,
  title: 'کار',
  priority: 2,
  status: TaskStatus.planned,
  positionInStatus: 0,
  createdAtUtc: createdAt,
  updatedAtUtc: updatedAt,
);
```

Required compatibility:

```dart
expect(task.isDone, isFalse);
expect(task.sortOrder, task.positionInStatus);
```

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test test/features/tasks/domain/task_item_test.dart" \
  /tmp/task2-1-2-red.log
```

Expected: constructor/field compile failures.

- [ ] **Step 3: Implement TaskItem v2**

Canonical fields:

```dart
final String id;
final int displayNumber;
final String title;
final int priority;
final TaskStatus status;
final int positionInStatus;
final DateTime createdAtUtc;
final DateTime updatedAtUtc;
final DateTime? completedAtUtc;
final DateTime? canceledAtUtc;

bool get isDone => status == TaskStatus.completed;
int get sortOrder => positionInStatus;
bool get isActive =>
    status == TaskStatus.planned || status == TaskStatus.inProgress;
```

Constructor validation must reject inconsistent terminal timestamps.

- [ ] **Step 4: Update direct fixtures**

All current TaskItem constructors receive deterministic temporary
`displayNumber` values and canonical status/position values. Repository mapping
may temporarily derive these from schema-v2 rows until Gate 2.1.3.

- [ ] **Step 5: Verify focused tests**

```bash
script -qefc \
  "flutter --color test \
  test/features/tasks/domain/task_item_test.dart \
  test/features/tasks/data/drift_task_repository_test.dart \
  test/features/dashboard/tasks_panel_test.dart \
  test/features/dashboard/tasks_panel_persistence_test.dart \
  test/core/database/database_restart_test.dart \
  test/core/providers/persistence_providers_test.dart" \
  /tmp/task2-1-2-focused.log
```

- [ ] **Step 6: Verify and commit**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task2-1-2-full.log
flutter build linux --debug
git diff --check

git add lib test tool/verify_phase2_task2_1_2_green.py
git commit -m "feat: add task status and ordering fields"
git push
```

---

### Gate 2.1.3: Schema version 3 and deterministic migration

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/core/database/app_database.g.dart`
- Create: `test/core/database/task_status_migration_test.dart`
- Modify: `test/core/database/app_database_test.dart`
- Modify: `test/core/database/database_restart_test.dart`
- Create: `tool/verify_phase2_task2_1_3_green.py`

**Interfaces:**
- Produces schema version 3 `TaskRows`
- Migrates schema version 2 rows without loss

- [ ] **Step 1: Create a real schema-v2 fixture test**

Create a file-backed SQLite database with the exact version-2 `tasks` table,
insert active/done rows with tied timestamps and different IDs, set
`PRAGMA user_version = 2`, then open it through `AppDatabase`.

Assert:

```text
schema version = 3
same IDs/titles/priorities/timestamps
active -> planned
done -> completed
display numbers rank by created_at_utc then id
positions contiguous inside planned/completed
canceled_at_utc null
restart returns identical rows
```

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test test/core/database/task_status_migration_test.dart" \
  /tmp/task2-1-3-red.log
```

Expected: schema remains version 2 and new columns are absent.

- [ ] **Step 3: Replace TaskRows definition**

```dart
IntColumn get displayNumber => integer().unique()();
TextColumn get status => text()();
IntColumn get positionInStatus => integer()();
DateTimeColumn get canceledAtUtc => dateTime().nullable()();
```

Remove `isDone` and `sortOrder` from the current table definition. Add checks for
display number, status, priority, and position.

- [ ] **Step 4: Implement `from < 3` migration**

Use one migration transaction:

```text
ALTER TABLE tasks RENAME TO tasks_v2_legacy
create current tasks table
copy deterministic mapped rows
drop tasks_v2_legacy
```

Display rank is based on `(created_at_utc, id)`. Per-status position rank is
based on `(sort_order, created_at_utc, id)`.

- [ ] **Step 5: Generate Drift code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Verify migration and restart tests**

```bash
script -qefc \
  "flutter --color test \
  test/core/database/task_status_migration_test.dart \
  test/core/database/app_database_test.dart \
  test/core/database/database_restart_test.dart" \
  /tmp/task2-1-3-focused.log
```

- [ ] **Step 7: Verify and commit**

```bash
flutter analyze
script -qefc "flutter --color test" /tmp/task2-1-3-full.log
flutter build linux --debug
git diff --check

git add lib/core/database test/core/database tool/verify_phase2_task2_1_3_green.py
git commit -m "feat: migrate tasks to status ordering schema"
git push
```

---

### Gate 2.1.4: Repository mapping and stable display numbers

**Files:**
- Modify: `lib/features/tasks/domain/task_repository.dart`
- Modify: `lib/features/tasks/data/drift_task_repository.dart`
- Modify: `test/features/tasks/data/drift_task_repository_test.dart`
- Create: `tool/verify_phase2_task2_1_4_green.py`

**Interfaces:**
- Produces `watchByStatus(TaskStatus)`
- Produces `getById(String)`
- Creates tasks with transactionally allocated display numbers
- Maps v3 rows to canonical TaskItem

- [ ] **Step 1: Add failing repository tests**

Tests must assert:

- `watchAll` orders by status workflow order, then status position;
- `watchByStatus` returns only one status and ordered positions;
- `getById` exact lookup and missing null;
- two sequential creates receive display numbers 1 and 2;
- delete then create receives 3, not reused 1;
- reorder does not change display number;
- file restart preserves display number.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test test/features/tasks/data/drift_task_repository_test.dart" \
  /tmp/task2-1-4-red.log
```

- [ ] **Step 3: Implement row mapping**

Use `TaskStatus.parseStorage(row.status)` and map all v3 columns.

- [ ] **Step 4: Implement create transaction**

Inside one transaction:

```text
nextDisplay = COALESCE(MAX(display_number), 0) + 1
nextPosition = count rows in requested status
insert canonical row
```

Task creation input must not be able to overwrite an existing display number.

- [ ] **Step 5: Add status-aware reads**

`watchByStatus` orders by `positionInStatus`, then `createdAtUtc`, then `id`.

- [ ] **Step 6: Verify, analyze, full test, build, commit**

Commit:

```bash
git commit -m "feat: persist stable task display numbers"
```

---

### Gate 2.1.5: Atomic transition and per-status reorder

**Files:**
- Modify: `lib/features/tasks/domain/task_repository.dart`
- Modify: `lib/features/tasks/data/drift_task_repository.dart`
- Create: `test/features/tasks/data/drift_task_repository_transition_test.dart`
- Create: `tool/verify_phase2_task2_1_5_green.py`

**Interfaces:**
- Produces `transition(...)`
- Produces `reorderWithinStatus(...)`

- [ ] **Step 1: Add failing transition tests**

Cover:

- planned -> inProgress at exact position;
- inProgress -> completed sets UTC completed timestamp;
- completed -> planned clears completed timestamp;
- any -> canceled sets canceled timestamp and clears completed timestamp;
- canceled -> inProgress clears canceled timestamp;
- source compaction and target slot insertion;
- target position clamping;
- missing ID failure without writes;
- restart preserves both statuses and positions.

- [ ] **Step 2: Add failing reorder tests**

Cover:

- exact full ID inventory required;
- duplicate ID rejected;
- missing ID rejected;
- ID from another status rejected;
- positions become contiguous;
- other statuses unchanged;
- transaction rollback on validation failure.

- [ ] **Step 3: Implement transition transaction**

Use temporary offset positions to avoid collisions, then compact source and
assign final target positions.

- [ ] **Step 4: Implement reorder transaction**

Validate first, write second. No row is updated until the full ID list is valid.

- [ ] **Step 5: Verify and commit**

```bash
git commit -m "feat: add atomic task status transitions"
```

---

### Gate 2.1.6: Existing Tasks panel compatibility

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/tasks_panel.dart`
- Modify: `test/features/dashboard/tasks_panel_test.dart`
- Modify: `test/features/dashboard/tasks_panel_persistence_test.dart`
- Modify provider/repository test doubles that implement TaskRepository
- Create: `tool/verify_phase2_task2_1_6_green.py`

**Interfaces:**
- Consumes status-aware TaskRepository
- Preserves current visible UI and Persian copy

- [ ] **Step 1: Add failing UI compatibility tests**

Assert:

- active count includes planned and inProgress;
- done count includes only completed;
- canceled tasks are excluded from the current active/done list;
- add creates planned at position zero;
- toggle planned/inProgress -> completed;
- toggle completed -> planned;
- delete-completed does not delete canceled;
- current filters, priority edits, title edits, animations, and copy remain.

- [ ] **Step 2: Run RED**

```bash
script -qefc \
  "flutter --color test \
  test/features/dashboard/tasks_panel_test.dart \
  test/features/dashboard/tasks_panel_persistence_test.dart" \
  /tmp/task2-1-6-red.log
```

- [ ] **Step 3: Replace compatibility operations**

Use `transition` and `reorderWithinStatus`. Remove UI dependence on global
ordering. Canceled tasks remain persisted but hidden until the status-aware
views arrive in Task 2.3.

- [ ] **Step 4: Update test doubles**

Every TaskRepository fake must implement status-aware reads, lookup,
transition, and reorder.

- [ ] **Step 5: Verify and commit**

```bash
git commit -m "feat: preserve task panel on status model"
```

---

### Gate 2.1.7: Migration, restart, and Task 2.1 checkpoint

**Files:**
- Create: `docs/superpowers/checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md`
- Create: `tool/prepare_phase2_task2_1_checkpoint.py`
- Create: `tool/verify_phase2_task2_1_complete.py`
- Modify: this plan and the Phase 2 design status sections

**Interfaces:**
- Consumes all Gate 2.1.1–2.1.6 commits and fresh verification logs
- Produces exact Task 2.1 completion evidence

- [ ] **Step 1: Run focused cross-gate suite**

Include status, TaskItem, migration, restart, repository, transition, provider,
and dashboard tests.

- [ ] **Step 2: Run fresh project verification**

```bash
flutter analyze 2>&1 | tee /tmp/task2-1-analyze.log
script -qefc "flutter --color test" /tmp/task2-1-full.log
flutter build linux --debug 2>&1 | tee /tmp/task2-1-build.log
git diff --check
```

- [ ] **Step 3: Generate checkpoint**

Checkpoint records:

- six exact Gate commit hashes;
- focused and full test counts;
- analyze/build/diff evidence;
- schema version 2 to 3 migration evidence;
- restart stability;
- status/timestamp invariants;
- stable display-number evidence;
- independent per-status ordering;
- unchanged current UI behavior;
- explicit non-completion of the remainder of Phase 2.

- [ ] **Step 4: Verify checkpoint**

```bash
python3 tool/verify_phase2_task2_1_complete.py
```

- [ ] **Step 5: Commit and push**

```bash
git commit -m "test: checkpoint task status ordering foundation"
git push
```

## Plan self-review

- Spec coverage: every Task 2.1 requirement maps to Gates 2.1.1–2.1.7.
- Placeholder scan: every implementation step contains concrete behavior.
- Type consistency: all later gates consume the `TaskStatus`, `TaskItem`, and
  `TaskRepository` signatures defined above.
- Scope check: reminders, recurrence, timers, Kanban, calendar, Trash, audit,
  and dashboard configuration remain outside Task 2.1.
