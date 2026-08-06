#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import subprocess
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


def run_verifier(relative: str) -> None:
    result = subprocess.run(
        [sys.executable, str(ROOT / relative)],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    need(result.returncode == 0, f"{relative} failed:\n{result.stdout}")


database = read("lib/core/database/app_database.dart")
task_item = read("lib/features/tasks/domain/task_item.dart")
task_repository = read("lib/features/tasks/domain/task_repository.dart")
rule = read("lib/features/tasks/domain/task_recurrence_rule.dart")
exception = read("lib/features/tasks/domain/task_recurrence_exception.dart")
completion = read("lib/features/tasks/domain/task_occurrence_completion.dart")
bundle = read("lib/features/tasks/domain/task_recurrence_bundle.dart")
repository_contract = read(
    "lib/features/tasks/domain/task_recurrence_repository.dart"
)
calendar_occurrence = read(
    "lib/features/tasks/domain/task_calendar_occurrence.dart"
)
codec = read("lib/features/tasks/data/task_recurrence_codec.dart")
repository = read(
    "lib/features/tasks/data/drift_task_recurrence_repository.dart"
)
projector = read(
    "lib/features/tasks/application/task_occurrence_projector.dart"
)
service = read(
    "lib/features/tasks/application/task_recurrence_service.dart"
)
reminder_projector = read(
    "lib/features/tasks/application/task_reminder_projector.dart"
)
reminder_service = read(
    "lib/features/tasks/application/task_reminder_projection_service.dart"
)
providers = read("lib/core/providers/persistence_providers.dart")
view_mode = read(
    "lib/features/tasks/presentation/task_board/task_view_mode.dart"
)
calendar_board = read(
    "lib/features/tasks/presentation/task_calendar/task_calendar_board.dart"
)
draft = read(
    "lib/features/tasks/presentation/task_details/task_details_draft.dart"
)
recurrence_draft = read(
    "lib/features/tasks/presentation/task_details/task_recurrence_draft.dart"
)
recurrence_field = read(
    "lib/features/tasks/presentation/task_details/task_recurrence_field.dart"
)
dialog = read(
    "lib/features/tasks/presentation/task_details/task_details_dialog.dart"
)
panel = read(
    "lib/features/dashboard/presentation/widgets/tasks_panel.dart"
)
design = read(
    "docs/superpowers/specs/2026-08-06-recurring-tasks-calendar-design.md"
)
plan = read(
    "docs/superpowers/plans/2026-08-06-task-2-6-recurring-calendar.md"
)

schema_match = re.search(
    r"int\s+get\s+schemaVersion\s*=>\s*(\d+)\s*;",
    database,
)
need(schema_match is not None, "schema version is missing")
need(int(schema_match.group(1)) >= 6, "schema regressed below Task 2.6 version 6")
for token in (
    "class TaskRecurrenceRuleRows extends Table",
    "class TaskRecurrenceExceptionRows extends Table",
    "class TaskOccurrenceCompletionRows extends Table",
    "task_recurrence_rules",
    "task_recurrence_exceptions",
    "task_occurrence_completions",
    "references(TaskRows, #id, onDelete: KeyAction.cascade)",
    "if (from < 6)",
    "createTable(taskRecurrenceRuleRows)",
    "createTable(taskRecurrenceExceptionRows)",
    "createTable(taskOccurrenceCompletionRows)",
):
    need(token in database, f"schema-6 recurrence contract missing: {token}")

need(
    "RecurrenceRule" not in task_item,
    "TaskItem must remain recurrence-free",
)
need(
    "recurrence" not in task_repository.lower(),
    "TaskRepository must remain recurrence-free",
)

for source, tokens, label in (
    (
        rule,
        (
            "final class TaskRecurrenceRule",
            "final RecurrenceRule rule",
            "createdAtUtc",
            "updatedAtUtc",
        ),
        "task recurrence rule",
    ),
    (
        exception,
        (
            "final class TaskRecurrenceException",
            "final RecurrenceException exception",
            "createdAtUtc",
            "updatedAtUtc",
        ),
        "task recurrence exception",
    ),
    (
        completion,
        (
            "final class TaskOccurrenceCompletion",
            "originalLocalDateTime",
            "completedAtUtc",
            "occurrenceKey",
        ),
        "occurrence completion",
    ),
    (
        bundle,
        (
            "final class TaskRecurrenceBundle",
            "TaskRecurrenceRule? rule",
            "exceptions",
            "completions",
        ),
        "recurrence bundle",
    ),
):
    for token in tokens:
        need(token in source, f"{label} contract missing: {token}")

for token in (
    "watchRules",
    "watchExceptions",
    "watchCompletions",
    "getByTask",
    "replaceRule",
    "upsertException",
    "deleteException",
    "setCompletion",
    "clearCompletion",
    "clearTask",
):
    need(token in repository_contract, f"repository API missing: {token}")
    need(token in repository, f"Drift repository missing: {token}")

for token in (
    "'version': 1",
    "encodeRule",
    "decodeRule",
    "encodeException",
    "decodeException",
    "decodeLocalDateTime",
    "fixedTimeZoneId",
    "monthlySelectors",
    "annualDates",
    "invalidDatePolicy",
):
    need(token in codec, f"versioned recurrence codec missing: {token}")

for token in (
    "transaction",
    "TaskRecurrenceRuleRowsCompanion.insert",
    "TaskRecurrenceExceptionRowsCompanion.insert",
    "TaskOccurrenceCompletionRowsCompanion.insert",
    "originalLocalKey",
    "onDelete: KeyAction.cascade",
):
    need(
        token in repository or token in database,
        f"recurrence persistence invariant missing: {token}",
    )

for token in (
    "final class TaskCalendarOccurrence",
    "originalLocalDateTime",
    "effectiveLocalDateTime",
    "instantUtc",
    "occurrenceKey",
    "scheduled",
    "moved",
    "completed",
    "skipped",
    "canceled",
):
    need(token in calendar_occurrence, f"calendar occurrence missing: {token}")

for token in (
    "final class TaskOccurrenceProjector",
    "engine.expand",
    "rangeStartUtc",
    "rangeEndUtc",
    "floatingTimeZoneId",
    "completionKeys",
    "_projectOneOff",
    "TaskStatus.completed",
    "TaskStatus.canceled",
    "List<TaskCalendarOccurrence>.unmodifiable",
):
    need(token in projector, f"task occurrence projection missing: {token}")

for token in (
    "final class TaskRecurrenceService",
    "replaceRule",
    "setCompleted",
    "skip",
    "cancel",
    "move",
    "restore",
    "moveToDeviceLocal",
    "_notifyChanged",
):
    need(token in service, f"recurrence lifecycle service missing: {token}")

for token in (
    "projectForOccurrences",
    "occurrence.recurring",
    "TaskCalendarOccurrenceStatus.scheduled",
    "TaskCalendarOccurrenceStatus.moved",
    "occurrenceKey",
    "originalLocalDateTime",
    "task-${task.id}-occurrence-",
):
    need(token in reminder_projector, f"recurring reminder projection missing: {token}")
for token in (
    "recurrenceHorizon",
    "_recurrenceRepository",
    "_occurrenceProjector.project",
    "projectForOccurrences",
    "replaceByOwner",
):
    need(token in reminder_service, f"recurring reminder service missing: {token}")

for token in (
    "taskRecurrenceRepositoryProvider",
    "taskOccurrenceProjectorProvider",
    "taskRecurrenceServiceProvider",
    "taskRecurrenceRulesProvider",
    "taskRecurrenceExceptionsProvider",
    "taskOccurrenceCompletionsProvider",
    "taskCalendarTimeZoneProvider",
):
    need(token in providers, f"provider wiring missing: {token}")

need(
    re.search(
        r"enum\s+TaskViewMode\s*\{"
        r"(?=[^}]*\blist\b)"
        r"(?=[^}]*\bkanban\b)"
        r"(?=[^}]*\bcalendar\b)",
        view_mode,
        re.DOTALL,
    )
    is not None,
    "TaskViewMode must define list, kanban, and calendar",
)
for token in (
    "final class TaskCalendarBoard",
    "task-calendar-board",
    "GridView.builder",
    "جلالی",
    "میلادی",
    "ماه قبل",
    "ماه بعد",
    "امروز",
    "انجام شد",
    "ردکردن",
    "لغو",
    "بازگردانی",
    "انتقال",
):
    need(token in calendar_board, f"Calendar UI missing: {token}")

for token in (
    "TaskDetailsField.recurrence",
    "TaskRecurrenceDraft",
    "buildRecurrenceRule",
):
    need(token in draft, f"task draft recurrence integration missing: {token}")
for token in (
    "TaskRecurrenceDraft.disabled",
    "RecurrenceFrequency.daily",
    "RecurrenceFrequency.weekly",
    "RecurrenceFrequency.monthly",
    "RecurrenceFrequency.yearly",
    "RecurrenceCalendar.jalali",
    "RecurrenceCalendar.gregorian",
    "RecurrenceTimeZoneMode.fixed",
    "RecurrenceTimeZoneMode.floating",
    "RecurrenceEndKind.never",
    "RecurrenceEndKind.until",
    "RecurrenceEndKind.afterCount",
):
    need(token in recurrence_draft, f"recurrence draft missing: {token}")
for token in (
    "final class TaskRecurrenceField",
    "روزهای هفته",
    "روزهای ماه",
    "تاریخ‌های سالانه",
    "آخرین روز ماه",
    "منطقه زمانی ثابت",
    "پایان تکرار",
):
    need(token in recurrence_field, f"recurrence editor missing: {token}")
for token in (
    "initialRecurrenceRule",
    "recurrenceRule",
    "buildRecurrenceRule",
):
    need(token in dialog, f"dialog recurrence result missing: {token}")
for token in (
    "items: const <String>['فهرست', 'کانبان', 'تقویم']",
    "TaskViewMode.calendar",
    "TaskCalendarBoard(",
    "taskRecurrenceRepositoryProvider",
    "taskRecurrenceServiceProvider",
    "_toggleOccurrenceCompleted",
    "_skipOccurrence",
    "_cancelOccurrence",
    "_restoreOccurrence",
    "_moveOccurrence",
):
    need(token in panel, f"TasksPanel Calendar integration missing: {token}")
need(
    "TaskViewMode _viewMode = TaskViewMode.list" in panel,
    "List must remain the default task view",
)
need("TaskKanbanBoard(" in panel, "Kanban integration was removed")

focused_files = (
    "test/features/tasks/domain/task_recurrence_domain_test.dart",
    "test/features/tasks/data/task_recurrence_codec_test.dart",
    "test/features/tasks/data/drift_task_recurrence_repository_test.dart",
    "test/core/database/task_recurrence_schema_migration_test.dart",
    "test/core/database/task_recurrence_restart_test.dart",
    "test/features/tasks/application/task_occurrence_projector_test.dart",
    "test/features/tasks/application/task_recurrence_service_test.dart",
    "test/features/tasks/application/task_recurring_reminder_projection_test.dart",
    "test/features/tasks/presentation/task_details/task_recurrence_draft_test.dart",
    "test/features/tasks/presentation/task_calendar/task_calendar_board_test.dart",
)
tests = "\n".join(read(relative) for relative in focused_files)
for token in (
    "schema version five upgrades to recurring task schema seven",
    "recurrence state survives restart with stable occurrence identity",
    "persists rule, exception, and independent completion",
    "projects recurring move and completion by original identity",
    "completion and exception are independent",
    "recurring reminders use stable occurrence-scoped schedule ids",
    "skipped, canceled, and completed occurrences do not notify",
    "builds a Jalali weekly rule with floating timezone",
    "renders Calendar as a monthly grid with selected-day tasks",
    "completion action returns the stable occurrence identity",
):
    need(token in tests, f"focused Task 2.6 coverage missing: {token}")

for token in (
    "three task-owned tables",
    "{taskId}@{originalLocalDateTime.storageKey}",
    "bounded 90-day",
    "List as the default view",
):
    need(token in design, f"approved Task 2.6 design missing: {token}")
for token in (
    "Task 2.6 Recurring Tasks and Calendar Implementation Plan",
    "Schema upgrade is append-only from 5 to 6.",
    'git commit -m "feat: add recurring tasks and calendar"',
):
    need(token in plan, f"Task 2.6 plan missing: {token}")

run_verifier("tool/verify_phase2_task2_4_complete.py")
run_verifier("tool/verify_phase2_task2_5_complete.py")

result = subprocess.run(
    ("git", "diff", "--check"),
    cwd=ROOT,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
need(result.returncode == 0, f"git diff --check failed:\n{result.stdout}")

print(
    "OK: Task 2.6 persists task-owned recurrence rules, occurrence "
    "exceptions, and completion state on schema 6; projects one-off and "
    "recurring Calendar occurrences with stable original-local identity; "
    "reconciles occurrence-scoped reminders; adds a Jalali/Gregorian "
    "Calendar as the third task view; preserves List/Kanban defaults and "
    "TaskItem/TaskRepository contracts; and keeps Task 2.4/2.5 verification "
    "stable."
)
