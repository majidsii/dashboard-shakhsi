#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
repository = (
    root
    / "lib/features/tasks/data/drift_task_repository.dart"
)

if not repository.is_file():
    raise SystemExit(f"Missing repository: {repository}")

source = repository.read_text(encoding="utf-8")
required_markers = [
    "final class DriftTaskRepository implements TaskRepository",
    "Stream<List<TaskItem>> watchAll()",
    "OrderingTerm.asc(row.sortOrder)",
    "Future<void> create(TaskItem task)",
    "Future<void> update(TaskItem task)",
    "Future<void> setDone(",
    "changedAt.toUtc()",
    "Future<void> deleteCompleted()",
    "Future<void> reorder(List<String> orderedIds)",
    "_database.transaction(() async",
    "TaskRowsCompanion _companionFromTask",
    "completedAtUtc: Value<DateTime?>",
]

missing = [marker for marker in required_markers if marker not in source]
if missing:
    raise SystemExit(
        "Missing GREEN markers: " + ", ".join(missing)
    )

print("Persistence Task 3 GREEN source contract verified.")
