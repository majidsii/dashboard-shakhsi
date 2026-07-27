#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
panel = root / "lib/features/dashboard/presentation/widgets/tasks_panel.dart"
legacy_test = root / "test/features/dashboard/tasks_panel_test.dart"
persistence_test = root / "test/features/dashboard/tasks_panel_persistence_test.dart"

for path in (panel, legacy_test, persistence_test):
    if not path.is_file():
        raise SystemExit(f"Missing Task 7 GREEN file: {path}")

panel_source = panel.read_text(encoding="utf-8")
required_panel_markers = [
    "final class TasksPanel extends ConsumerStatefulWidget",
    "final tasksAsync = ref.watch(taskItemsProvider);",
    "await repository.create(",
    "ref.read(taskRepositoryProvider).setDone",
    "ref.read(taskRepositoryProvider).update",
    "ref.read(taskRepositoryProvider).delete(task.id)",
    ".deleteCompleted()",
    "UuidV7IdGenerator",
    "List<TaskItem> _filteredTasks",
    "final TaskItem task;",
]
missing = [m for m in required_panel_markers if m not in panel_source]
if missing:
    raise SystemExit("Missing Task 7 GREEN panel markers: " + ", ".join(missing))

for forbidden in (
    "final List<_TaskPreview>",
    "final class _TaskPreview",
    "_nextTaskId",
    "_tasks.insert",
    "_tasks.removeWhere",
):
    if forbidden in panel_source:
        raise SystemExit(f"In-memory task state remains: {forbidden}")

legacy_source = legacy_test.read_text(encoding="utf-8")
for marker in (
    "UncontrolledProviderScope",
    "appDatabaseProvider.overrideWithValue(database)",
    "openTestDatabase()",
):
    if marker not in legacy_source:
        raise SystemExit(f"Legacy task widget test is not persistent: {marker}")

persistence_source = persistence_test.read_text(encoding="utf-8")
for marker in (
    "renders tasks streamed from the repository",
    "adding a task through the UI persists it",
    "edit completion and delete actions update the repository",
    "a UI-created task survives reopening the database",
    "driftRuntimeOptions.dontWarnAboutMultipleDatabases",
):
    if marker not in persistence_source:
        raise SystemExit(f"Persistence test marker missing: {marker}")

print("Persistence Task 7 GREEN source contract verified.")
