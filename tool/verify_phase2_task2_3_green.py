#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

FILES = {
    "view_mode": ROOT / (
        "lib/features/tasks/presentation/task_board/task_view_mode.dart"
    ),
    "operations": ROOT / (
        "lib/features/tasks/presentation/task_board/task_board_operations.dart"
    ),
    "kanban": ROOT / (
        "lib/features/tasks/presentation/task_board/task_kanban_board.dart"
    ),
    "panel": ROOT / (
        "lib/features/dashboard/presentation/widgets/tasks_panel.dart"
    ),
    "repository": ROOT / (
        "lib/features/tasks/domain/task_repository.dart"
    ),
    "database": ROOT / "lib/core/database/app_database.dart",
    "operations_test": ROOT / (
        "test/features/tasks/presentation/task_board/"
        "task_board_operations_test.dart"
    ),
    "kanban_test": ROOT / (
        "test/features/tasks/presentation/task_board/"
        "task_kanban_board_test.dart"
    ),
    "panel_test": ROOT / (
        "test/features/dashboard/tasks_panel_views_test.dart"
    ),
    "plan": ROOT / (
        "docs/superpowers/plans/"
        "2026-08-04-task-2-3-board-list-kanban.md"
    ),
}


def need(condition: bool, message: str) -> None:
    if not condition:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


for label, path in FILES.items():
    need(path.is_file(), f"missing {label}: {path}")

source = {
    label: path.read_text(encoding="utf-8")
    for label, path in FILES.items()
}

need(
    re.search(
        r"enum\s+TaskViewMode\s*\{"
        r"(?=[^}]*\blist\b)"
        r"(?=[^}]*\bkanban\b)"
        r"[^}]*\}",
        source["view_mode"],
        re.DOTALL,
    )
    is not None,
    "TaskViewMode does not define list and kanban",
)

operations = source["operations"]
for token in (
    "final class TaskBoardMoveRequest",
    "final class TaskBoardOperations",
    "targetPosition",
    "_repository.reorderWithinStatus",
    "_repository.transition",
    "_nowUtc().toUtc()",
    "_sameOrder",
):
    need(token in operations, f"board operations missing: {token}")

need(
    re.search(
        r"if\s*\(\s*task\.status\s*!=\s*request\.targetStatus\s*\)"
        r".*?_repository\.transition",
        operations,
        re.DOTALL,
    )
    is not None,
    "cross-status moves are not delegated to atomic transition",
)
need(
    re.search(
        r"orderedIds\.removeAt\s*\(\s*sourceIndex\s*\)"
        r".*?orderedIds\.insert"
        r".*?_repository\.reorderWithinStatus",
        operations,
        re.DOTALL,
    )
    is not None,
    "same-status moves do not submit one complete reordered inventory",
)
need(
    "شناسه کار در برد تکراری است." in operations
    and "کار موردنظر در برد پیدا نشد." in operations,
    "board identity validation is incomplete",
)

kanban = source["kanban"]
for token in (
    "final class TaskKanbanBoard",
    "for (final status in TaskStatus.values)",
    "OriginalGlass(",
    "OriginalFieldSurface(",
    "LongPressDraggable<_TaskDragPayload>",
    "DragTarget<_TaskDragPayload>",
    "onWillAcceptWithDetails",
    "onAcceptWithDetails",
    "Axis.horizontal",
    "task-kanban-horizontal-scroll",
    "task-kanban-column-${status.storageValue}",
    "TaskBoardMoveRequest(",
    "allTasks",
    "_canonicalDropPosition",
):
    need(token in kanban, f"Kanban implementation missing: {token}")

for label in (
    "برنامه‌ریزی‌شده",
    "در حال انجام",
    "انجام‌شده",
    "لغوشده",
    "گرفتن و جابه‌جایی",
    "به وضعیت قبلی",
    "به وضعیت بعدی",
    "بالا بردن",
    "پایین بردن",
):
    need(label in kanban, f"Kanban Persian/accessibility copy missing: {label}")

panel = source["panel"]
for token in (
    "TaskViewMode _viewMode = TaskViewMode.list",
    "final Set<String> _movingTaskIds",
    "_TaskViewModeToggle(",
    "items: const <String>['فهرست', 'کانبان']",
    "if (_viewMode == TaskViewMode.list)",
    "TaskKanbanBoard(",
    "tasks: visibleBoardTasks",
    "allTasks: tasks",
    "TaskBoardOperations(",
    "_searchedBoardTasks",
    "_moveBoardTask",
):
    need(token in panel, f"TasksPanel integration missing: {token}")

need(
    re.search(
        r"panelTasks\s*=\s*tasks\s*"
        r"\.where\s*\(\s*\(task\)\s*=>\s*"
        r"task\.status\s*!=\s*TaskStatus\.canceled",
        panel,
        re.DOTALL,
    )
    is not None,
    "default list no longer preserves canceled-task hiding",
)
need(
    "OriginalTextField(" in panel
    and "افزودن با جزئیات" in panel
    and "_addTaskWithDetails" in panel,
    "existing quick/detailed add flows were not preserved",
)

repository = source["repository"]
required_repository_methods = (
    "watchAll",
    "watchByStatus",
    "getById",
    "create",
    "update",
    "transition",
    "reorderWithinStatus",
    "delete",
    "deleteCompleted",
)
for method in required_repository_methods:
    need(method in repository, f"TaskRepository lost method: {method}")
for forbidden in (
    "moveBoardTask",
    "moveBetweenStatuses",
    "watchBoard",
    "saveBoard",
):
    need(
        forbidden not in repository,
        f"TaskRepository was widened unnecessarily: {forbidden}",
    )

database = source["database"]
need(
    re.search(r"int\s+get\s+schemaVersion\s*=>\s*4\s*;", database)
    is not None,
    "Task 2.3 must keep schema version 4",
)

coverage = {
    "operations_test": (
        "same-status move writes one complete canonical order",
        "same-status no-op does not write to repository",
        "cross-status move delegates one atomic transition",
        "negative positions clamp to the beginning",
        "missing and duplicate board identities fail without writes",
    ),
    "kanban_test": (
        "renders four canonical columns including canceled tasks",
        "accessible next-status action emits a board move request",
        "reorder actions emit final same-column positions",
        "filtered reorder maps to complete canonical positions",
        "narrow board remains horizontally scrollable without overflow",
    ),
    "panel_test": (
        "list stays default and kanban reveals all four statuses",
        "kanban move action uses repository atomic transition",
        "switching back keeps quick add and detailed create available",
        "_BoardMemoryTaskRepository",
    ),
}
for file_label, tokens in coverage.items():
    for token in tokens:
        need(
            token in source[file_label],
            f"focused coverage missing in {file_label}: {token}",
        )

for forbidden in (
    "AppDatabase",
    "openTestDatabase",
    "DriftTaskRepository",
):
    need(
        forbidden not in source["panel_test"],
        f"TasksPanel view test must stay fast and in-memory: {forbidden}",
    )

plan = source["plan"]
for requirement in (
    "Same-status order changes use `reorderWithinStatus`.",
    "Cross-status moves use the existing atomic `transition`.",
    "Kanban shows all four canonical statuses, including canceled.",
    "Narrow layouts use horizontal Kanban scrolling without overflow.",
):
    need(requirement in plan, f"implementation plan missing: {requirement}")

print(
    "OK: Task 2.3 adds Flutter-independent atomic board orchestration, "
    "a four-column Liquid Glass Kanban with drag/drop and accessible move "
    "controls, default-compatible List/Kanban switching, complete canceled "
    "visibility in Kanban, search-safe canonical drop mapping, fast focused "
    "tests, unchanged repository signatures, and schema version 4."
)
