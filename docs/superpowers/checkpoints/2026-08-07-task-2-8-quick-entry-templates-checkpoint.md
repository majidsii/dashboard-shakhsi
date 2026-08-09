# Task 2.8 — Quick-Entry Templates Checkpoint

Date: 2026-08-09
Status: **Implemented and freshly verified**
Code commit: `0972d8feba1566c0a876d8d5e3969f95281e2e6e`

## Delivered boundary

Task 2.8 adds persistent reusable Task templates as a separate bounded context
without storing template state on `TaskItem` or changing `TaskRepository`.

Implemented capabilities:

- Drift schema version 8 with one unified `task_templates` table;
- append-only schema-7 to schema-8 migration preserving existing task,
  reminder, recurrence, occurrence, notification, and timer/time-entry data;
- seven app-owned system templates with stable `systemKey` identities and
  frozen defaults;
- unlimited custom templates with create/edit/delete/hide/show/duplicate/reorder;
- system hide/show/reorder/duplicate plus restore-defaults, with no in-place
  system edit or permanent delete;
- idempotent system-catalog synchronization that preserves user visibility and
  ordering while appending newly introduced built-ins deterministically;
- dedicated `TaskTemplate`, `TaskTemplateDraft`, recurrence-default,
  repository, Drift repository, codec, catalog, synchronizer, and mapper
  boundaries;
- template-to-Task mapping through a fresh `TaskDetailsDraft` with null
  Start/Due values and fresh reminder/recurrence identities;
- Task-to-custom-template mapping that stores reusable intent only and converts
  fixed recurrence-until dates to relative days-after-anchor representation;
- template picker, manager, and editor UI;
- split New Task entry with template selection;
- edit-mode **ذخیره به‌عنوان قالب** flow;
- Riverpod repository/catalog/synchronizer/mapper/startup wiring and
  application-bootstrap system catalog synchronization;
- migration, restart, mapping, provider, picker/manager/editor, Task Details,
  and Tasks-panel integration coverage.

Trash/audit history, dashboard card ordering, billing, Pomodoro, idle detection,
and occurrence-specific template state remain outside Task 2.8.

## Fresh verification evidence

- Task 2.8 focused tests: **57 passed**
- Full project tests: **1245 passed**
- `flutter analyze`: **No issues found**
- `flutter build linux --debug`: **Succeeded**
- `git diff --check`: **Clean**
- Task 2.5 semantic verifier: **Passed**
- Task 2.6 semantic verifier: **Passed**
- Task 2.7 semantic verifier: **Passed**
- Task 2.8 green semantic verifier: **Passed**

## Compatibility evidence

- `TaskItem` remains free of template persistence fields.
- `TaskRepository` remains responsible only for Task persistence.
- Selecting a template does not create a Task or reminder/recurrence rows.
- Template application leaves fixed Start/Due values empty.
- Reminder and recurrence identities are fresh when the reviewed Task is saved.
- Templates do not persist Task IDs, display numbers, status/order, lifecycle
  timestamps, fixed scheduling dates, timer data, occurrence completion, or
  recurrence exception history.
- Existing reminder, recurrence, timer, List, Kanban, Calendar, and Task Details
  behavior remains covered by the full suite and prior semantic verifiers.
- Custom templates and user system visibility/order survive restart.
