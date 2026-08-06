# Task 2.6 Recurring Tasks and Calendar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development or superpowers:executing-plans.
> Steps use checkbox syntax for tracking.

**Goal:** Persist task recurrence state, project deterministic task
occurrences, reproject reminders, and add a third Calendar task view.

**Architecture:** Keep `TaskItem` and `TaskRepository` recurrence-free. Add a
task recurrence repository backed by three append-only Drift tables. Build
Calendar and reminder output by projecting persisted state through the shared
Task 2.5 engine.

**Tech Stack:** Flutter, Riverpod, Drift, timezone, shamsi_date, flutter_test.

## Global constraints

- Baseline commit: `2761407d4d8d300975297954b4dd3242daf9c9ac`.
- Schema upgrade is append-only from 5 to 6.
- `TaskItem` and `TaskRepository` signatures remain unchanged.
- List remains the default task view.
- All UTC persistence values must be UTC `DateTime`.
- Occurrence identity uses original local civil time.

---

### Task 1: Persist task recurrence state

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Create: task recurrence domain, codec, repository, and Drift implementation
- Test: domain, codec, repository, migration, and restart tests

- [ ] Install RED tests and verify missing APIs fail.
- [ ] Add schema-6 recurrence tables.
- [ ] Generate Drift code.
- [ ] Implement deterministic JSON codec and repository mappings.
- [ ] Run focused persistence tests.

### Task 2: Project task occurrences

**Files:**
- Create: `task_calendar_occurrence.dart`
- Create: `task_occurrence_projector.dart`
- Create: `task_recurrence_service.dart`
- Test: projection, completion, exception, and range behavior

- [ ] Project one-off and recurring tasks.
- [ ] Overlay completion by original local key.
- [ ] Preserve identity across move.
- [ ] Exclude terminal task series from future active projection.
- [ ] Run focused application tests.

### Task 3: Reproject recurring reminders

**Files:**
- Modify: `task_reminder_projector.dart`
- Modify: `task_reminder_projection_service.dart`
- Modify: provider wiring
- Test: stable occurrence schedule ids and skipped/canceled suppression

- [ ] Add occurrence-scoped notification projection.
- [ ] Expand a bounded future horizon.
- [ ] Reconcile the complete task owner set.
- [ ] Reproject after recurrence and exception changes.
- [ ] Run reminder regression tests.

### Task 4: Recurrence editor and Calendar view

**Files:**
- Modify: shared task details draft, form, and dialog
- Create: recurrence draft and field
- Create: monthly task Calendar
- Modify: `TaskViewMode` and TasksPanel integration
- Test: draft, dialog, Calendar, and List/Kanban compatibility

- [ ] Add recurrence form state and validation.
- [ ] Save recurrence after task create/edit.
- [ ] Add Calendar as view index 2.
- [ ] Add occurrence actions.
- [ ] Run focused widget tests.

### Task 5: Full verification and checkpoint

- [ ] Run `flutter analyze`.
- [ ] Run all Flutter tests.
- [ ] Build Linux debug bundle.
- [ ] Run stable Task 2.4 and 2.5 verifiers.
- [ ] Commit code and push.
- [ ] Generate and commit Task 2.6 checkpoint.

## Commit boundary

```bash
git commit -m "feat: add recurring tasks and calendar"
```
