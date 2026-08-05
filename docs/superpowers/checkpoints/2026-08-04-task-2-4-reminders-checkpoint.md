# Task 2.4 — Task Reminder Rules and Notification Projection Checkpoint

Date: 2026-08-04
Implementation commit: `916f6e46a6ec52ee107125a4f11c2778bf669561`

## Delivered

- Separate persisted `TaskReminderRule` entities; no reminder fields on `TaskItem`.
- Schema version 5 with cascading task reminder rows and unique task/trigger rules.
- Deterministic schema version 4 to 5 migration and restart coverage.
- Stable schedule identity `task-{taskId}-reminder-{ruleId}`.
- Task-owned `NotificationOwner` values and owner-scoped coordinator replacement.
- Full/private delivery mode per reminder rule.
- UTC projection for due time, 15 minutes, 1 hour, and 1 day before due.
- Filtering for disabled, past, missing-due, completed, and canceled reminders.
- Automatic reprojection after due edits and task status transitions.
- Automatic schedule cleanup after task deletion and delete-completed.
- Liquid Glass reminder controls in the shared create/edit task form.
- Backward-compatible `showTaskDetailsDialog` API and structured reminder editor result.
- Historical Task 2.2 and Task 2.3 checkpoint verifiers remain valid after schema 5.

## Verification evidence

- Focused Task 2.4 tests: **64 passed**.
- Full project tests: **1102 passed**.
- Flutter analyze: **No issues found**.
- Linux debug build: **passed**.
- `git diff --check`: **clean**.
- Semantic verifier: `tool/verify_phase2_task2_4_green.py`.

## Explicit boundary

Task 2.4 does not add recurrence, calendar occurrences, timers, templates,
Undo/Trash, audit history, or dashboard layout settings. Those remain in
Tasks 2.5–2.11.
