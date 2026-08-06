# Recurring Tasks, Occurrence Exceptions, and Calendar Design

Date: 2026-08-06
Status: Approved for implementation
Parent phase: Phase 2 — Tasks v2
Task: 2.6

## Goal

Attach the shared recurrence engine to persisted tasks without adding
recurrence fields to `TaskItem` or recurrence methods to `TaskRepository`.
Persist task-owned recurrence rules, per-occurrence exceptions, and
per-occurrence completion. Add Calendar as the third Tasks view while keeping
List and Kanban behavior stable.

## Architecture

A task remains the durable series parent. Recurrence metadata is stored in
three task-owned tables:

- `task_recurrence_rules`: one serialized shared `RecurrenceRule` per task;
- `task_recurrence_exceptions`: zero or one skip/cancel/move exception per
  original local occurrence key;
- `task_occurrence_completions`: independent completion timestamps per original
  local occurrence key.

`TaskOccurrenceProjector` combines persisted task data with the shared
`RecurrenceEngine`. It expands only a requested UTC range, applies exceptions,
then overlays completion state. One-off tasks are projected from `dueAtUtc` or
`startAtUtc`, so Calendar works for recurring and non-recurring tasks.

## Identity and invariants

- The task id identifies the series parent.
- The occurrence identity is `{taskId}@{originalLocalDateTime.storageKey}`.
- Move changes effective time but never occurrence identity.
- Completion is keyed by original local time and survives move.
- A task can own at most one recurrence rule.
- A task can own at most one exception and one completion per occurrence key.
- Deleting a task cascades all recurrence state.
- Schema migration is append-only from version 5 to version 6.

## Reminder projection

Existing reminder rules remain task-owned. For a recurring task, reminder
projection expands scheduled and moved occurrences over a bounded 90-day
horizon and creates deterministic schedule ids containing the original local
occurrence key. Skipped and canceled occurrences never create notifications.
A recurrence edit reprojects the complete owner-scoped expected set through
`NotificationCoordinator`.

## Calendar UI

`TaskViewMode` gains `calendar`. The monthly Calendar:

- supports previous month, today, and next month;
- shows Persian date headings while using Gregorian range boundaries;
- includes one-off and recurring active tasks;
- displays completed, moved, skipped, and canceled occurrence states;
- supports complete/uncomplete, skip, cancel, restore, and move actions;
- keeps List as the default view and Kanban unchanged.

## Recurrence editor

The shared create/edit dialog gains a recurrence section. It supports:

- enabled/disabled;
- daily, weekly, monthly, yearly;
- positive interval;
- Gregorian or Jalali calendar;
- fixed or floating timezone;
- weekly weekday selection;
- comma-separated monthly day selectors plus last-day;
- comma-separated annual month/day selectors;
- never, inclusive until, and after-count termination;
- skip-period or clamp-to-last-day invalid-date policy.

Recurrence requires a start or due time. Due time is preferred as the anchor.

## Non-goals

Task 2.6 does not add:

- timer sessions;
- quick-entry templates;
- trash or undo;
- audit history;
- dashboard card ordering;
- quota recurrence such as “three times per week”.
