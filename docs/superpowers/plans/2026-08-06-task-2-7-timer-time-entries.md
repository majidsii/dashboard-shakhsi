# Task 2.7 Timer Lifecycle and Recoverable Time Entries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist one globally active task timer, recover it after restart, and manage tracked/manual time entries from Task Details and the Tasks panel.

**Architecture:** Add an independent schema-7 time-entry subsystem. Domain objects derive elapsed duration from UTC persistence; Drift enforces the single active slot; `TaskTimerService` coordinates commands; Riverpod exposes streams; Liquid Glass widgets consume those providers.

**Tech Stack:** Flutter, Dart, Riverpod, Drift/SQLite, flutter_test.

## Global Constraints

- Preserve `TaskItem` and `TaskRepository` public contracts.
- Preserve List/Kanban/Calendar defaults and recurrence/reminder behavior.
- Store all persistence timestamps in UTC.
- Never use an in-memory Stopwatch as the source of truth.
- Only one running or paused timer may exist globally.
- Keep schema migration append-only from version 6 to version 7.

---

### Task 1: Time-entry domain

**Files:**
- Create: `lib/features/tasks/domain/task_time_entry.dart`
- Test: `test/features/tasks/domain/task_time_entry_test.dart`

**Interfaces:**
- Produces: `TaskTimeEntry`, `TaskTimeEntrySource`, `TaskTimerState`, `elapsedSecondsAt`, lifecycle copy helpers.

- [ ] Write failing tests for UTC validation, running/paused/stopped invariants, elapsed arithmetic, and manual entry construction.
- [ ] Run the domain test and verify missing production types cause RED.
- [ ] Implement the minimal immutable domain model.
- [ ] Run the domain test and verify GREEN.

### Task 2: Schema 7 and Drift repository

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Create: `lib/features/tasks/domain/task_time_repository.dart`
- Create: `lib/features/tasks/data/drift_task_time_repository.dart`
- Test: `test/features/tasks/data/drift_task_time_repository_test.dart`
- Test: `test/core/database/task_time_schema_migration_test.dart`
- Test: `test/core/database/task_time_restart_test.dart`

**Interfaces:**
- Consumes: `TaskTimeEntry`.
- Produces: live streams, active lookup, CRUD, and database single-active enforcement.

- [ ] Write failing repository, migration, and restart tests.
- [ ] Verify RED before adding schema and repository production code.
- [ ] Add `TaskTimeEntryRows`, schema 7 migration, mapping, and queries.
- [ ] Run build_runner and focused persistence tests.

### Task 3: Timer application service

**Files:**
- Create: `lib/features/tasks/application/task_timer_service.dart`
- Test: `test/features/tasks/application/task_timer_service_test.dart`

**Interfaces:**
- Consumes: `TaskTimeRepository`, `AppClock`, and id generator callback.
- Produces: `start`, `pause`, `resume`, `stop`, `addManual`, `updateManual`, and `delete`.

- [ ] Write failing command and overlap tests.
- [ ] Verify RED.
- [ ] Implement lifecycle arithmetic from persisted UTC timestamps.
- [ ] Verify service tests GREEN.

### Task 4: Riverpod wiring

**Files:**
- Modify: `lib/core/providers/persistence_providers.dart`
- Modify: `test/core/providers/persistence_providers_test.dart`

**Interfaces:**
- Produces: repository/service providers, all-entry stream, task-family stream, and global active stream.

- [ ] Add failing provider tests.
- [ ] Wire Drift repository and service using existing AppClock and UUID generator.
- [ ] Verify provider streams emit persisted timer state.

### Task 5: Task Details timer panel

**Files:**
- Create: `lib/features/tasks/presentation/task_timer/task_timer_panel.dart`
- Create: `lib/features/tasks/presentation/task_timer/task_manual_time_entry_dialog.dart`
- Modify: `lib/features/tasks/presentation/task_details/task_details_form.dart`
- Modify: `lib/features/tasks/presentation/task_details/task_details_dialog.dart`
- Test: `test/features/tasks/presentation/task_timer/task_timer_panel_test.dart`
- Test: `test/features/tasks/presentation/task_details/task_details_timer_test.dart`

**Interfaces:**
- Consumes: task id and timer providers.
- Produces: live elapsed display, lifecycle actions, manual add/edit, total, and history.

- [ ] Write failing widget tests for create/edit visibility and lifecycle callbacks.
- [ ] Add edit-only timer panel and manual-duration dialog.
- [ ] Verify widget tests GREEN without off-screen tap warnings.

### Task 6: Tasks-panel visibility and compatibility

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/tasks_panel.dart`
- Test: `test/features/dashboard/tasks_panel_timer_test.dart`

**Interfaces:**
- Consumes: active timer and task time streams.
- Produces: global active timer strip and per-task total badge.

- [ ] Write failing panel tests.
- [ ] Add timer strip and row badge without altering board operations.
- [ ] Run existing List/Kanban/Calendar panel tests.

### Task 7: Compatibility and checkpoint

**Files:**
- Modify: schema-version migration/restart tests that legitimately track latest schema.
- Create: `tool/verify_phase2_task2_7_green.py`
- Create during finalization: Task 2.7 checkpoint and complete verifier.

- [ ] Run focused Task 2.7 plus prior Task 2.6 regressions.
- [ ] Run `flutter analyze`.
- [ ] Run the full Flutter test suite.
- [ ] Run `flutter build linux --debug`.
- [ ] Run `git diff --check`, commit, push, finalize, and checkpoint.
