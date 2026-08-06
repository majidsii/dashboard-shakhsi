# Phase 2 Tasks v2, Reminder, and Recurrence — Design

Date: 2026-08-02
Status: Approved for implementation; Tasks 2.1–2.5 implemented
Phase: 2 — Planning and Execution
Baseline: Phase 1 complete; 1005 project tests passing

## Implementation status

- Task 2.1 — Task Status, Display Number, and Per-Status Position: **Implemented** ([checkpoint](../checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md))
- Task 2.2 — Description, Start/Due Time, and Estimated Duration: **Implemented** ([checkpoint](../checkpoints/2026-08-04-task-2-2-planning-fields-checkpoint.md))
- Task 2.3 — Atomic Board Operations, List, and Kanban Views: **Implemented** ([checkpoint](../checkpoints/2026-08-04-task-2-3-board-list-kanban-checkpoint.md))
- Task 2.4 — Task Reminder Rules and Notification Projection: **Implemented** ([checkpoint](../checkpoints/2026-08-04-task-2-4-reminders-checkpoint.md))
- Tasks 2.6–2.11: **Pending**
- Phase 2 overall: **In progress**

## Objective

Evolve the current persisted task list into a durable planning system with four
statuses, stable display numbering, independent per-status ordering, List,
Kanban, and Calendar views, task reminders, shared recurrence, recoverable
timers, templates, reversible destructive operations, and configurable
dashboard cards.

Phase 2 must extend the existing Drift and notification foundations rather than
replace them. Every migration is append-only after distribution to testers,
every task begins with a failing test, and each gate ends with focused tests,
`flutter analyze`, the full test suite, a Linux debug build, and a focused
commit.

## Existing baseline

The current repository contains:

- Drift schema version 2;
- `tasks` rows with `id`, `title`, `priority`, `is_done`, `sort_order`,
  `created_at_utc`, `updated_at_utc`, and `completed_at_utc`;
- `TaskItem` with boolean completion and one global sort position;
- `TaskRepository` with CRUD, completion, delete-completed, and global reorder;
- a persisted task panel with local search, filter, and sort state;
- a complete notification pipeline with `NotificationOwnerType.task`;
- hidden Linux delivery, platform scheduler selection, and startup
  reconciliation;
- no shared recurrence engine and no task-specific reminder projection.

## Architectural choice

Phase 2 evolves the existing `tasks` table in deterministic, tested migrations.
It does not introduce a parallel `tasks_v2` table for normal operation and does
not perform one large all-features migration.

Reasons:

1. Existing user data remains in place.
2. Repository and provider boundaries stay stable during incremental work.
3. Each migration has an independent rollback and restart test.
4. Reminder and recurrence can attach after task identity and ordering are
   stable.
5. The implementation avoids temporary dual writes and cutover complexity.

## Core task model

### Task status

The canonical statuses are:

```dart
enum TaskStatus {
  planned,
  inProgress,
  completed,
  canceled,
}
```

Their persisted representations are explicit and stable:

```text
planned
inProgress
completed
canceled
```

Parsing is exact, case-sensitive, and whitespace-sensitive. Unknown persisted
values are rejected instead of silently defaulting.

### Task identity and display number

A task has two different identifiers:

- `id`: immutable internal UUID used for joins, routes, notifications, and
  repository operations;
- `displayNumber`: immutable positive integer shown to the user.

`displayNumber` is allocated transactionally as `MAX(display_number) + 1`.
Deleted numbers are not reused. Reordering or moving a task never changes its
display number.

### Status-local position

`positionInStatus` is a zero-based integer scoped to one `TaskStatus`.

Invariant for every status:

```text
positions = [0, 1, 2, ..., itemCount - 1]
```

Moving a task between statuses compacts the source status and inserts into the
target status at a clamped target position. Reordering one status never changes
the position of tasks in another status.

### Task timestamps

The foundation model includes:

- `createdAtUtc`;
- `updatedAtUtc`;
- `completedAtUtc`;
- `canceledAtUtc`.

All persisted timestamps are UTC.

Status/timestamp invariants:

- `completed` requires `completedAtUtc` and clears `canceledAtUtc`;
- `canceled` requires `canceledAtUtc` and clears `completedAtUtc`;
- `planned` and `inProgress` require both terminal timestamps to be null.

## Schema version 3

The `tasks` table evolves to:

| Column | Type | Rule |
|---|---|---|
| `id` | TEXT PK | immutable |
| `display_number` | INTEGER | positive, unique |
| `title` | TEXT | trimmed, non-empty in domain |
| `priority` | INTEGER | 0 through 3 |
| `status` | TEXT | canonical TaskStatus storage value |
| `position_in_status` | INTEGER | non-negative |
| `created_at_utc` | DATETIME | UTC |
| `updated_at_utc` | DATETIME | UTC |
| `completed_at_utc` | DATETIME NULL | status-consistent |
| `canceled_at_utc` | DATETIME NULL | status-consistent |

Migration from schema version 2 is deterministic:

```text
is_done = true  -> status = completed
is_done = false -> status = planned
sort_order      -> initial position within the mapped status
completed_at_utc is retained only for completed tasks
canceled_at_utc = null
display_number  = rank by created_at_utc, then id
```

After copying, positions are normalized independently for `planned` and
`completed`. No version 2 row is dropped.

## Repository boundary

The Task 2.1 repository contract becomes:

```dart
abstract interface class TaskRepository {
  Stream<List<TaskItem>> watchAll();

  Stream<List<TaskItem>> watchByStatus(TaskStatus status);

  Future<TaskItem?> getById(String id);

  Future<void> create(TaskItem task);

  Future<void> update(TaskItem task);

  Future<void> transition({
    required String id,
    required TaskStatus status,
    required int targetPosition,
    required DateTime changedAtUtc,
  });

  Future<void> reorderWithinStatus({
    required TaskStatus status,
    required List<String> orderedIds,
  });

  Future<void> delete(String id);

  Future<void> deleteCompleted();
}
```

`create`, `transition`, `reorderWithinStatus`, and `delete` maintain contiguous
positions inside Drift transactions.

The existing `setDone` and global `reorder` operations remain only as temporary
compatibility adapters while the current Tasks panel is migrated. They are
removed after the UI consumes status-aware operations.

## Atomic ordering algorithm

To avoid unique-position collisions during reorder:

1. validate that the supplied IDs are exactly the current IDs for the status;
2. move current positions to a temporary high range;
3. write final positions `0..n-1`;
4. commit once.

Transition uses one transaction:

1. read the task;
2. normalize `changedAt` to UTC;
3. compact the source status;
4. open one slot in the target status;
5. update status, target position, timestamps, and `updatedAtUtc`;
6. verify final contiguous positions before commit.

A missing task, duplicate ID, foreign-status ID, or incomplete reorder list
fails without partial writes.

## UI compatibility and later views

Task 2.1 preserves the current visible Tasks panel.

Compatibility mapping:

- existing “active” means `planned` or `inProgress`;
- existing “done” means `completed`;
- “delete completed” deletes only `completed`;
- current add flow creates `planned` at position zero;
- current completion toggle transitions between `planned` and `completed`.

Task 2.3 introduces List and Kanban views after the storage and transition
contracts are stable. Calendar is introduced after start/due fields in Task 2.2.

## Reminder architecture

Reminder rules are separate persisted entities, not scattered nullable fields
on `TaskItem`.

Proposed domain:

```dart
final class TaskReminderRule {
  final String id;
  final String taskId;
  final TaskReminderTrigger trigger;
  final bool enabled;
  final NotificationPrivacyMode privacyMode;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
}
```

A projector converts a task and its enabled reminder rules into
`NotificationRequest` values.

Schedule identity:

```text
task-{taskId}-reminder-{ruleId}
```

Notification owner:

```dart
NotificationOwner(
  type: NotificationOwnerType.task,
  id: taskId,
)
```

Editing due time, completing, canceling, trashing, or restoring a task
reprojects the complete expected notification set through
`NotificationCoordinator`. The hidden delivery pipeline remains unchanged.

## Shared recurrence architecture

Recurrence is core infrastructure because finance, tasks, habits, challenges,
and installments need the same date rules.

Target location:

```text
lib/core/recurrence/
  recurrence_frequency.dart
  recurrence_rule.dart
  recurrence_end.dart
  recurrence_exception.dart
  recurrence_occurrence.dart
  recurrence_engine.dart
```

The core engine consumes timezone-aware local scheduling inputs and produces
deterministic occurrences. Task-specific completion, skip, reschedule, and
exception behavior lives in the tasks feature and does not leak into the core
engine.

The recurrence test matrix must include:

- daylight-saving transitions;
- device timezone changes;
- Jalali month/year boundaries;
- monthly dates that do not exist;
- leap years;
- explicit skipped, moved, and canceled occurrences;
- deterministic restart behavior.

## Timer architecture

Task timers use persisted sessions rather than an in-memory stopwatch.

A timer session records:

```text
id
task_id
started_at_utc
stopped_at_utc
created_at_utc
updated_at_utc
```

At most one running timer is allowed. Startup recovery determines elapsed time
from persisted UTC timestamps. Manual entries use the same session aggregate
boundary and are distinguishable for audit.

## Reversible operations

Task 2.9 introduces generic infrastructure:

- operation command;
- inverse/undo payload;
- soft-delete timestamp;
- purge-after timestamp;
- audit event.

Trash retention is 30 days. Purge is deterministic and restart-safe. A task in
Trash does not produce reminders, active recurrence occurrences, or dashboard
counts.

## Dashboard configuration

Task 2.10 stores:

- module visibility;
- card visibility;
- card order;
- per-device layout preferences where required.

Task domain data remains independent of dashboard layout state.

## Phase 2 task map

1. **Task 2.1 — Task Status, Display Number, and Per-Status Position** — **Implemented** ([checkpoint](../checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md))
2. **Task 2.2 — Description, Start/Due Time, and Estimated Duration** — **Implemented** ([checkpoint](../checkpoints/2026-08-04-task-2-2-planning-fields-checkpoint.md))
3. **Task 2.3 — Atomic Board Operations, List, and Kanban Views** — **Implemented** ([checkpoint](../checkpoints/2026-08-04-task-2-3-board-list-kanban-checkpoint.md))
4. **Task 2.4 — Task Reminder Rules and Notification Projection** — **Implemented** ([checkpoint](../checkpoints/2026-08-04-task-2-4-reminders-checkpoint.md))
5. **Task 2.5 — Shared Recurrence Domain and Occurrence Engine** — **Implemented** ([checkpoint](../checkpoints/2026-08-05-task-2-5-recurrence-checkpoint.md))
6. **Task 2.6 — Recurring Tasks, Exceptions, and Calendar View**
7. **Task 2.7 — Timer Lifecycle and Recoverable Time Entries**
8. **Task 2.8 — Quick-Entry Templates**
9. **Task 2.9 — Undo, 30-Day Trash, and Audit History**
10. **Task 2.10 — Dashboard Card Visibility and Ordering**
11. **Task 2.11 — Phase 2 Integrated Checkpoint**

Each task receives its own detailed implementation plan immediately before
execution.

## Task 2.1 gate map

Task 2.1 status: **Implemented** — [checkpoint](../checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md)

1. **2.1.1 — TaskStatus domain and storage serialization**
2. **2.1.2 — TaskItem v2 invariants and compatibility**
3. **2.1.3 — Schema version 3 and deterministic migration**
4. **2.1.4 — Repository mapping and stable display numbers**
5. **2.1.5 — Atomic transition and per-status reorder**
6. **2.1.6 — Existing Tasks panel compatibility**
7. **2.1.7 — Migration, restart, and Task 2.1 checkpoint**

## Test and verification policy

Every Gate follows:

```text
RED test
-> verify expected failure
-> minimal GREEN implementation
-> focused regression tests
-> flutter analyze
-> full flutter test
-> flutter build linux --debug
-> git diff --check
-> focused commit and push
```

Database migration gates additionally require:

- opening a real schema version 2 fixture;
- upgrading to version 3;
- row-for-row data checks;
- restart from the same file;
- no destructive fallback;
- generated Drift code committed when changed.

## Task 2.1 exit criteria

Task 2.1 is complete only when:

- every version 2 task migrates without loss;
- active rows become `planned`;
- done rows become `completed`;
- display numbers are positive, unique, deterministic, and stable after
  reorder/restart;
- each status keeps contiguous independent positions after restart;
- status transitions are atomic;
- terminal timestamps match status;
- the existing Tasks panel remains visually and behaviorally compatible;
- all previous tests and all new tests pass;
- the Linux debug build succeeds;
- a checkpoint records exact Gate commits and fresh verification evidence.

## Explicit non-goals for Task 2.1

Task 2.1 does not add:

- descriptions;
- due dates;
- reminders;
- recurrence;
- timers;
- Kanban UI;
- calendar UI;
- trash;
- audit history;
- dashboard layout settings.

Those features depend on the Task 2.1 identity, status, and ordering foundation.
