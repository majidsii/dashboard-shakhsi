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
generated = read("lib/core/database/app_database.g.dart")
task_item = read("lib/features/tasks/domain/task_item.dart")
task_repository = read("lib/features/tasks/domain/task_repository.dart")
entry = read("lib/features/tasks/domain/task_time_entry.dart")
repository_contract = read(
    "lib/features/tasks/domain/task_time_repository.dart"
)
repository = read(
    "lib/features/tasks/data/drift_task_time_repository.dart"
)
service = read("lib/features/tasks/application/task_timer_service.dart")
providers = read("lib/core/providers/persistence_providers.dart")
panel = read(
    "lib/features/tasks/presentation/task_timer/task_timer_panel.dart"
)
manual_dialog = read(
    "lib/features/tasks/presentation/task_timer/"
    "task_manual_time_entry_dialog.dart"
)
details_form = read(
    "lib/features/tasks/presentation/task_details/task_details_form.dart"
)
details_dialog = read(
    "lib/features/tasks/presentation/task_details/task_details_dialog.dart"
)
tasks_panel = read(
    "lib/features/dashboard/presentation/widgets/tasks_panel.dart"
)

schema_match = re.search(
    r"int\s+get\s+schemaVersion\s*=>\s*(\d+)\s*;",
    database,
)
need(schema_match is not None, "schema version is missing")
need(int(schema_match.group(1)) >= 7, "Task 2.7 schema version must be at least 7")
for token in (
    "class TaskTimeEntryRows extends Table",
    "task_time_entries",
    "references(TaskRows, #id, onDelete: KeyAction.cascade)",
    "activeSlot => integer().nullable().unique()",
    "'running'",
    "'paused'",
    "'stopped'",
    "if (from < 7)",
    "createTable(taskTimeEntryRows)",
):
    need(token in database, f"schema-7 timer contract missing: {token}")
for token in (
    "class $TaskTimeEntryRowsTable",
    "TaskTimeEntryRow",
    "TaskTimeEntryRowsCompanion",
    "taskTimeEntryRows",
):
    need(token in generated, f"generated timer table missing: {token}")

need("timer" not in task_item.lower(), "TaskItem must remain timer-free")
need("timeentry" not in task_repository.lower(), "TaskRepository changed for timers")

for token in (
    "enum TaskTimeEntrySource",
    "enum TaskTimerState",
    "final class TaskTimeEntry",
    "elapsedSecondsAt",
    "TaskTimeEntry pause",
    "TaskTimeEntry resume",
    "TaskTimeEntry stop",
    "TaskTimeEntry updateManual",
    "activeSlot",
):
    need(token in entry, f"time-entry domain missing: {token}")

for token in (
    "watchAll",
    "watchByTask",
    "watchActive",
    "getActive",
    "insert",
    "update",
    "delete",
):
    need(token in repository_contract, f"time repository contract missing: {token}")
    need(token in repository, f"Drift time repository missing: {token}")
for token in (
    "TaskTimeEntryRowsCompanion",
    "activeSlot.equals(1)",
    "PersistenceFailure",
    "watchSingleOrNull",
):
    need(token in repository, f"repository persistence behavior missing: {token}")

for token in (
    "final class TaskTimerService",
    "Future<TaskTimeEntry> start",
    "Future<TaskTimeEntry> pause",
    "Future<TaskTimeEntry> resume",
    "Future<TaskTimeEntry> stop",
    "addManualDuration",
    "updateManualDuration",
    "_ensureNoOverlap",
    "_clock.nowUtc()",
):
    need(token in service, f"timer service behavior missing: {token}")

for token in (
    "taskTimeRepositoryProvider",
    "taskTimerServiceProvider",
    "taskTimeEntriesProvider",
    "taskTimeEntriesByTaskProvider",
    "activeTaskTimerProvider",
    "DriftTaskTimeRepository",
):
    need(token in providers, f"timer provider wiring missing: {token}")

for token in (
    "TaskTimerPanel",
    "task-timer-start",
    "task-timer-pause",
    "task-timer-resume",
    "task-timer-stop",
    "task-time-manual-add",
    "TaskTimeTotalBadge",
    "TaskActiveTimerStrip",
):
    need(token in panel, f"timer UI missing: {token}")
for token in (
    "TaskManualTimeEntryDraft",
    "manual-time-duration",
    "manual-time-save",
):
    need(token in manual_dialog, f"manual time dialog missing: {token}")
need("final String? taskId" in details_form, "details form lacks task id")
need("TaskTimerPanel" in details_form, "details form lacks timer panel")
need("taskId: widget.initialTask?.id" in details_dialog, "edit dialog lacks timer id")
need("TaskActiveTimerStrip" in tasks_panel, "Tasks panel lacks active timer")
need("TaskTimeTotalBadge" in tasks_panel, "Tasks panel lacks time totals")

focused_files = (
    "test/features/tasks/domain/task_time_entry_test.dart",
    "test/features/tasks/data/drift_task_time_repository_test.dart",
    "test/features/tasks/application/task_timer_service_test.dart",
    "test/core/database/task_time_schema_migration_test.dart",
    "test/core/database/task_time_restart_test.dart",
    "test/features/tasks/presentation/task_timer/task_timer_panel_test.dart",
    "test/features/tasks/presentation/task_details/task_details_timer_test.dart",
    "test/features/dashboard/tasks_panel_timer_test.dart",
    "test/core/providers/persistence_providers_test.dart",
)
tests = "\n".join(read(relative) for relative in focused_files)
for token in (
    "database rejects a second globally active timer",
    "pause resume and stop accumulate only running intervals",
    "new service instance recovers running timer from persistence",
    ("schema version six upgrades append-only to timer schema seven"
     if "schema version six upgrades append-only to timer schema seven" in tests
     else "schema version six upgrades append-only to timer schema eight"),
    "running timer survives restart and derives elapsed from UTC",
    "manual entry rejects overlap with an existing entry",
    "starts pauses resumes and stops the persisted timer",
    "edit mode exposes persisted timer controls",
    "panel shows global active timer with task title",
    "timer providers emit persisted active and task-scoped entries",
):
    need(token in tests, f"focused timer coverage missing: {token}")

run_verifier("tool/verify_phase2_task2_6_complete.py")
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
    "OK: Task 2.7 adds schema-7 task time entries, database-enforced "
    "single active timer, UTC-derived recoverable elapsed time, persisted "
    "pause/resume/stop lifecycle, manual non-overlapping entries, Riverpod "
    "wiring, Task Details controls, Tasks-panel visibility, migration and "
    "restart coverage, and stable Task 2.6 verification."
)
