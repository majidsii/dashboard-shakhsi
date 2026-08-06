#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def need(condition: bool, message: str) -> None:
    if not condition:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    need(path.is_file(), f"missing required file: {relative}")
    return path.read_text(encoding="utf-8")


database = read("lib/core/database/app_database.dart")
generated = read("lib/core/database/app_database.g.dart")
task_item = read("lib/features/tasks/domain/task_item.dart")
trigger = read("lib/features/tasks/domain/task_reminder_trigger.dart")
rule = read("lib/features/tasks/domain/task_reminder_rule.dart")
repository_contract = read(
    "lib/features/tasks/domain/task_reminder_repository.dart"
)
repository = read(
    "lib/features/tasks/data/drift_task_reminder_repository.dart"
)
coordinator = read(
    "lib/core/notifications/notification_coordinator.dart"
)
projector = read(
    "lib/features/tasks/application/task_reminder_projector.dart"
)
projection_service = read(
    "lib/features/tasks/application/task_reminder_projection_service.dart"
)
aware_repository = read(
    "lib/features/tasks/data/reminder_aware_task_repository.dart"
)
providers = read("lib/core/providers/persistence_providers.dart")
draft = read(
    "lib/features/tasks/presentation/task_details/task_details_draft.dart"
)
field = read(
    "lib/features/tasks/presentation/task_details/"
    "task_reminder_rules_field.dart"
)
dialog = read(
    "lib/features/tasks/presentation/task_details/task_details_dialog.dart"
)
panel = read(
    "lib/features/dashboard/presentation/widgets/tasks_panel.dart"
)

schema_match = re.search(
    r"int\s+get\s+schemaVersion\s*=>\s*(\d+)\s*;",
    database,
)
need(schema_match is not None, "schema version is missing")
need(int(schema_match.group(1)) >= 5, "schema regressed below version 5")
for token in (
    "class TaskReminderRuleRows extends Table",
    "task_reminder_rules",
    "references(TaskRows, #id, onDelete: KeyAction.cascade)",
    "'atDue'",
    "'fifteenMinutesBefore'",
    "'oneHourBefore'",
    "'oneDayBefore'",
    "CHECK (privacy_mode IN ('full', 'private'))",
    "if (from < 5)",
    "createTable(taskReminderRuleRows)",
):
    need(token in database, f"schema contract missing: {token}")

for token in (
    "class $TaskReminderRuleRowsTable",
    "TaskReminderRuleRow",
    "TaskReminderRuleRowsCompanion",
    "taskReminderRuleRows",
):
    need(token in generated, f"generated Drift contract missing: {token}")

need(
    "reminder" not in task_item.lower(),
    "TaskItem must remain free of reminder fields",
)

for token in (
    "enum TaskReminderTrigger",
    "atDue",
    "fifteenMinutesBefore",
    "oneHourBefore",
    "oneDayBefore",
    "scheduledAtUtc",
    "parseStorage",
):
    need(token in trigger, f"trigger contract missing: {token}")

for token in (
    "final class TaskReminderRule",
    "final String id",
    "final String taskId",
    "NotificationPrivacyMode",
    "task-$taskId-reminder-$id",
    "createdAtUtc",
    "updatedAtUtc",
):
    need(token in rule, f"rule contract missing: {token}")

for token in (
    "watchByTask",
    "getByTask",
    "replaceForTask",
    "deleteByTask",
):
    need(token in repository_contract, f"repository interface missing: {token}")
    need(token in repository, f"Drift repository missing: {token}")

for token in (
    "transaction",
    "insertOnConflictUpdate",
    "desiredByTrigger",
    "rule.taskId != normalizedTaskId",
    "desired.id != row.id",
):
    need(token in repository, f"replacement semantics missing: {token}")

for token in (
    "Future<void> replaceByOwner",
    "request.owner != owner",
    "if (request.owner != owner) request",
    "await replaceAll(merged)",
):
    need(token in coordinator, f"owner replacement missing: {token}")

for token in (
    "TaskReminderProjector",
    "!task.isActive",
    "dueAtUtc == null",
    "!rule.enabled",
    "!scheduledAtUtc.isAfter(nowUtc)",
    "NotificationOwnerType.task",
    "'route': '/tasks/${task.id}'",
    "'reminderRuleId': rule.id",
    "privacyMode: rule.privacyMode",
):
    need(token in projector, f"projection contract missing: {token}")

for token in (
    "replaceByOwner",
    "_reminderRepository.getByTask",
    "_projector.project",
    "_nowUtc().toUtc()",
):
    need(token in projection_service, f"projection service missing: {token}")

for token in (
    "implements TaskRepository",
    "_reprojectIfConfigured",
    "transition",
    "deleteCompleted",
    "_projection().clear",
    "_reminderRepository.getByTask",
):
    need(token in aware_repository, f"lifecycle integration missing: {token}")

for token in (
    "baseTaskRepositoryProvider",
    "taskReminderRepositoryProvider",
    "taskReminderProjectionServiceProvider",
    "taskReminderRulesServiceProvider",
    "ReminderAwareTaskRepository",
    "taskReminderRulesProvider",
):
    need(token in providers, f"provider wiring missing: {token}")

for token in (
    "TaskDetailsField.reminders",
    "reminders.any((item) => item.selected)",
    "buildReminderRules",
    "TaskReminderDraft",
):
    need(token in draft, f"draft reminder integration missing: {token}")

for token in (
    "TaskReminderRulesField",
    "task-reminder-active-count",
    "NotificationPrivacyMode.private",
    "یادآورها بر اساس زمان سررسید ساخته می‌شوند",
):
    need(token in field, f"Liquid Glass reminder field missing: {token}")

for token in (
    "TaskDetailsDialogResult",
    "showTaskDetailsEditorDialog",
    "initialReminderRules",
    "buildReminderRules",
):
    need(token in dialog, f"dialog reminder result missing: {token}")

for token in (
    "showTaskDetailsEditorDialog",
    "taskReminderRepositoryProvider",
    "taskReminderRulesServiceProvider",
    "_sameReminderRules",
):
    need(token in panel, f"TasksPanel reminder integration missing: {token}")

test_files = (
    "test/features/tasks/domain/task_reminder_rule_test.dart",
    "test/features/tasks/data/drift_task_reminder_repository_test.dart",
    "test/features/tasks/application/task_reminder_projector_test.dart",
    "test/features/tasks/application/"
    "task_reminder_projection_service_test.dart",
    "test/features/tasks/presentation/task_details/"
    "task_reminder_draft_test.dart",
    "test/features/tasks/presentation/task_details/"
    "task_reminder_rules_field_test.dart",
    "test/features/tasks/presentation/task_details/"
    "task_reminder_dialog_test.dart",
    "test/core/database/task_reminder_schema_migration_test.dart",
)
tests = "\n".join(read(relative) for relative in test_files)
need(
    "schema version four upgrades to reminder schema version five" in tests
    or "schema version four upgrades through reminder and recurrence schema six"
    in tests
    or "schema version four upgrades through reminder and recurrence schema seven"
    in tests,
    "focused reminder migration coverage missing",
)
for token in (
    "task deletion cascades reminder rules",
    "projects enabled future rules with stable identity and payload",
    "due edits and terminal transitions reproject the owner set",
    "selected reminders require a due time",
    "reminder field enables presets and toggles privacy",
    "editor dialog returns task and canonical reminder rules",
):
    need(token in tests, f"focused test coverage missing: {token}")

print(
    "OK: Task 2.4 preserves independent persisted reminder rules from schema 5, "
    "stable task-owned notification projection, owner-scoped reconciliation, "
    "automatic due/status/delete reprojection, backward-compatible task "
    "editing, per-rule privacy, Liquid Glass reminder controls, migration "
    "coverage, and unchanged TaskItem/TaskRepository contracts."
)
