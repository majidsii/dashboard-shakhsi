# Task Timer and Recoverable Time Entries Design

Date: 2026-08-06
Status: Approved for implementation
Scope: Phase 2 Task 2.7

## Goal

Add persistent task time tracking that survives process restart, guarantees at
most one active timer across the application, supports pause/resume/stop, and
stores editable manual time entries without changing `TaskItem` or
`TaskRepository`.

## Architecture

Time tracking is a task-owned subsystem with its own domain model, repository,
application service, Drift table, providers, and UI. A timer is never computed
from an in-memory `Stopwatch`; the current elapsed duration is derived from the
persisted UTC timestamps plus accumulated completed intervals.

`TaskTimeEntry` represents both tracked and manual records. Tracked records move
through `running`, `paused`, and `stopped`. Manual records are created directly
in `stopped`. The nullable unique `activeSlot` column is `1` for a running or
paused timer and `NULL` for stopped entries, so SQLite enforces one active timer
globally even when concurrent commands race.

## Domain invariants

- every timestamp is stored in UTC;
- a running timer has `lastResumedAtUtc`, no end timestamp, and active slot 1;
- a paused timer has no `lastResumedAtUtc`, no end timestamp, and active slot 1;
- a stopped entry has an end timestamp, no active slot, and no resume timestamp;
- manual entries are always stopped and their accumulated duration equals the
  half-open interval `[startedAtUtc, endedAtUtc)`;
- accumulated seconds never decrease;
- active duration is `accumulatedSeconds + nowUtc - lastResumedAtUtc`;
- manual entries for the same task may not overlap another persisted interval;
- an active entry cannot be edited or deleted before it is stopped.

## Persistence

Schema 7 adds `task_time_entries` with a cascading task foreign key. The table
stores source, lifecycle state, UTC boundaries, accumulated seconds, optional
note, audit timestamps, and the nullable unique active slot. Migration from
schema 6 is append-only and creates the new table without rewriting tasks,
recurrence, reminders, or notification schedules.

## Application lifecycle

`TaskTimerService` owns all commands:

- `start(taskId)` fails while any running or paused timer exists;
- `pause()` freezes elapsed time into `accumulatedSeconds`;
- `resume()` resumes the single paused timer;
- `stop()` closes the active entry and releases the global slot;
- `addManual()` and `updateManual()` validate duration and overlap;
- `delete()` rejects active entries and removes stopped entries.

The service receives `AppClock` and `IdGenerator` dependencies so tests are
fully deterministic.

## UI

Edit-mode task details show a Liquid Glass timer panel with:

- live elapsed duration;
- start, pause, resume, and stop actions;
- a manual-duration dialog;
- total recorded duration;
- persisted entry history with manual edit and stopped-entry deletion.

Create mode does not show timer controls because no task id exists yet. The
Tasks panel shows the current global timer and per-task accumulated time without
changing List, Kanban, or Calendar semantics.

## Explicit non-goals

Task 2.7 does not add billing rates, Pomodoro cycles, idle detection, automatic
status transitions, occurrence-specific timers, cross-device sync, export,
templates, trash, audit history, or dashboard card ordering.

## Verification

Required coverage includes domain invariants, one-active database enforcement,
pause/resume arithmetic, restart recovery, schema-6 migration, manual overlap
rejection, provider wiring, task-detail controls, Tasks-panel summary, analyzer,
full test suite, Linux debug build, and stable Task 2.6 verification.
