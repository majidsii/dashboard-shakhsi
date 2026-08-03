# Task Status and Ordering Foundation — Task 2.1 Checkpoint

Date finalized: 2026-08-03  
Phase: 2  
Task: 2.1  
Status: **Implemented and freshly verified**

## Completion boundary

- Task 2.1 — Task Status, Display Number, and Per-Status Position: **Complete**
- Remaining Phase 2 tasks (2.2–2.11): **Not assessed and not marked complete**
- Phase 2 overall: **Not complete**

This checkpoint proves only Task 2.1. It does **not** mark the remainder of
Phase 2 complete.

## Scope completed

Task 2.1 replaces boolean completion and global ordering with four canonical
statuses, immutable display numbers, status-local positions, deterministic
schema version 2 to schema version 3 migration, atomic transitions, independent
reorder behavior, and compatibility behavior for the existing Tasks panel.

## Gate commit evidence

| Gate | Commit | Subject |
|---|---|---|
| 2.1.1 | `af6cf278135dcfb572e7eb49bbd8d571d2d547e0` | `feat: add task status storage contract` |
| 2.1.2 | `359322a173a5c4cbef35a9bec4671eb805db9394` | `feat: add task status and ordering fields` |
| 2.1.3 | `b716296ad5d0a2153a0d54fe07262e924d9ec606` | `feat: migrate tasks to status ordering schema` |
| 2.1.4 | `557542567ed07b8dc7936619cf36f27f9e8a5344` | `feat: persist stable task display numbers` |
| 2.1.5 | `b463c25393bd8d3e21d94a85410a02a213e73851` | `feat: add atomic task status transitions` |
| 2.1.6 | `7433e205f3eb3edbb8605caf658157431ee6d55b` | `feat: preserve task panel on status model` |

## Fresh verification evidence

- Task 2.1 focused tests: **54 passed**
- Full project tests: **1029 passed**
- `flutter analyze`: **No issues found**
- `flutter build linux --debug`: **Succeeded**
- `git diff --check`: **Clean**

## Schema migration evidence

- A real schema version 2 fixture upgrades to schema version 3.
- Every schema version 2 task row is preserved.
- Active rows migrate to `planned`.
- Done rows migrate to `completed`.
- Initial display numbers are positive, unique, and deterministic.
- Initial positions are contiguous inside each mapped status.
- The migration does not use a destructive fallback.

## Restart stability

Restart from the migrated database file preserves row identity, canonical
status, terminal timestamps, immutable display numbers, and contiguous
status-local positions.

## Status/timestamp invariants

- `planned` and `inProgress` clear terminal timestamps.
- `completed` requires `completedAtUtc` and clears `canceledAtUtc`.
- `canceled` requires `canceledAtUtc` and clears `completedAtUtc`.
- Transitions update status, timestamps, ordering, and `updatedAtUtc` atomically.

## Stable display-number evidence

Display numbers remain positive, unique, deterministic, immutable across
transition/reorder/restart, and are not reused after deletion.

## Independent per-status ordering

Every status has its own contiguous zero-based positions. Reordering one status
does not mutate another. Transitions compact the source and insert at the
clamped target position transactionally.

## Existing Tasks panel compatibility

The existing Persian Tasks panel keeps its Liquid Glass structure and copy.
Planned/in-progress remain active, completed remains done, canceled stays
hidden, add creates planned at position zero, completion toggles use atomic
transitions, and delete-completed removes completed rows only.

## Explicit remaining Phase 2 scope

Descriptions, time fields, Kanban/List/Calendar v2 views, reminders,
recurrence, timers, templates, Undo, Trash, audit history, and dashboard layout
configuration remain outside this checkpoint.
