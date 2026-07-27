#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
test_file = (
    root
    / "test/features/dashboard/tasks_panel_persistence_test.dart"
)

if not test_file.is_file():
    raise SystemExit(f"Missing Task 7 RED test: {test_file}")

source = test_file.read_text(encoding="utf-8")
markers = [
    "renders tasks streamed from the repository",
    "adding a task through the UI persists it",
    "edit completion and delete actions update the repository",
    "a UI-created task survives reopening the database",
    "appDatabaseProvider.overrideWithValue(database)",
    "taskRepositoryProvider",
    "UncontrolledProviderScope",
    "NativeDatabase(file)",
    "پس از اجرای دوباره",
]

missing = [marker for marker in markers if marker not in source]
if missing:
    raise SystemExit(
        "Missing Task 7 RED markers: " + ", ".join(missing)
    )

print("Persistence Task 7 RED tests contract verified.")
