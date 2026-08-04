# Task 2.4 Task Reminder Rules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add independently persisted task reminder rules, deterministic notification projection, lifecycle-safe reprojection, and Liquid Glass reminder editing inside the shared task dialog.

**Architecture:** Reminder rules live in their own schema-version-5 table and are accessed through `TaskReminderRepository`. `TaskReminderProjector` converts an active task plus enabled rules into stable `NotificationRequest` values, while `NotificationCoordinator.replaceByOwner` updates only the affected task owner. `ReminderAwareTaskRepository` reprojects configured tasks after due/status changes and clears task-owned schedules after deletion.

**Tech Stack:** Flutter, Dart 3.12, Riverpod, Drift/SQLite, existing NotificationCoordinator and platform schedulers, Flutter widget tests.

## Global Constraints

- Keep `TaskItem` free of reminder fields.
- Keep `TaskRepository` signatures unchanged.
- Schedule identity is exactly `task-{taskId}-reminder-{ruleId}`.
- Notification owner is `NotificationOwnerType.task` with the task id.
- All persisted and projected times are UTC.
- Disabled, past, missing-due, completed, and canceled reminders do not schedule.
- Private rules use the existing `NotificationPrivacyMode.private` delivery policy.
- No recurrence, timer, calendar, trash, audit, or notification-platform rewrite.
- Preserve the existing Liquid Glass visual system and RTL behavior.

---

### Task 1: Reminder domain and persistence

**Files:**
- Create: `lib/features/tasks/domain/task_reminder_trigger.dart`
- Create: `lib/features/tasks/domain/task_reminder_rule.dart`
- Create: `lib/features/tasks/domain/task_reminder_repository.dart`
- Create: `lib/features/tasks/data/drift_task_reminder_repository.dart`
- Modify: `lib/core/database/app_database.dart`
- Regenerate: `lib/core/database/app_database.g.dart`
- Test: `test/features/tasks/domain/task_reminder_rule_test.dart`
- Test: `test/features/tasks/data/drift_task_reminder_repository_test.dart`
- Test: `test/core/database/task_reminder_schema_migration_test.dart`

**Interfaces:**
- Produces: `TaskReminderTrigger`, `TaskReminderRule`, `TaskReminderRepository`.
- Storage: one row per `(taskId, trigger)`, cascading on task deletion.

- [ ] Write domain and repository RED tests.
- [ ] Verify RED fails because reminder types and table are missing.
- [ ] Implement domain validation and schema version 5.
- [ ] Implement transactional `replaceForTask`.
- [ ] Run Drift generation.
- [ ] Verify domain, migration, restart, replacement, and cascade tests pass.

### Task 2: Owner-scoped notification projection

**Files:**
- Modify: `lib/core/notifications/notification_coordinator.dart`
- Create: `lib/features/tasks/application/task_reminder_projector.dart`
- Create: `lib/features/tasks/application/task_reminder_projection_service.dart`
- Test: `test/core/notifications/notification_coordinator_test.dart`
- Test: `test/features/tasks/application/task_reminder_projector_test.dart`

**Interfaces:**
- Produces: `NotificationCoordinator.replaceByOwner`.
- Produces: `TaskReminderProjector.project`.
- Projection payload contains `route`, `taskId`, `reminderRuleId`, and `trigger`.

- [ ] Write RED tests for owner isolation, stable IDs, UTC offsets, privacy, and past filtering.
- [ ] Add owner-scoped replacement without deleting unrelated owners.
- [ ] Add deterministic projector and projection service.
- [ ] Verify unrelated notification owners remain unchanged.

### Task 3: Task lifecycle integration

**Files:**
- Create: `lib/features/tasks/data/reminder_aware_task_repository.dart`
- Create: `lib/features/tasks/application/task_reminder_rules_service.dart`
- Modify: `lib/core/providers/persistence_providers.dart`
- Test: `test/features/tasks/application/task_reminder_projection_service_test.dart`

**Interfaces:**
- Keeps `TaskRepository` unchanged.
- Reprojects after create/update/transition only when rules exist.
- Clears owner schedules after delete and delete-completed.
- Rule replacement immediately reprojects the current task.

- [ ] Write RED tests for due edit, completion, cancel, restore, and deletion.
- [ ] Add lazy reminder-aware repository decoration.
- [ ] Wire repositories and services through Riverpod.
- [ ] Verify task mutations without rules do not initialize the scheduler.

### Task 4: Shared task-dialog reminder editing

**Files:**
- Create: `lib/features/tasks/presentation/task_details/task_reminder_draft.dart`
- Create: `lib/features/tasks/presentation/task_details/task_reminder_rules_field.dart`
- Modify: `lib/features/tasks/presentation/task_details/task_details_draft.dart`
- Modify: `lib/features/tasks/presentation/task_details/task_details_form.dart`
- Modify: `lib/features/tasks/presentation/task_details/task_details_dialog.dart`
- Modify: `lib/features/dashboard/presentation/widgets/tasks_panel.dart`
- Test: `test/features/tasks/presentation/task_details/task_reminder_draft_test.dart`
- Test: `test/features/tasks/presentation/task_details/task_reminder_rules_field_test.dart`
- Test: `test/features/tasks/presentation/task_details/task_reminder_dialog_test.dart`

**Interfaces:**
- Existing `showTaskDetailsDialog` remains backward compatible and returns `TaskItem?`.
- New `showTaskDetailsEditorDialog` returns `TaskDetailsDialogResult`.
- Each preset supports independent full/private delivery mode.

- [ ] Write RED tests for due requirement, ID preservation, preset selection, and privacy.
- [ ] Add four stable presets: at due, 15 minutes before, 1 hour before, 1 day before.
- [ ] Add inline reminder validation to `TaskDetailsDraft`.
- [ ] Add the Liquid Glass reminder field to the shared form.
- [ ] Persist desired rules after create/edit and immediately reproject.
- [ ] Verify existing Task 2.2 dialog tests remain green.

### Task 5: Verification and checkpoint

**Files:**
- Create: `tool/verify_phase2_task2_4_green.py`
- Modify: `tool/verify_phase2_task2_2_complete.py`
- Modify: `tool/verify_phase2_task2_3_complete.py`
- Create after verification: `docs/superpowers/checkpoints/2026-08-04-task-2-4-reminders-checkpoint.md`

- [ ] Run focused reminder tests with concurrency 1.
- [ ] Run all prior Task 2.2 and Task 2.3 complete verifiers.
- [ ] Run `flutter analyze`.
- [ ] Run the complete Flutter test suite.
- [ ] Build Linux debug.
- [ ] Run `git diff --check`.
- [ ] Commit implementation.
- [ ] Generate checkpoint from fresh log evidence and exact commit hash.
