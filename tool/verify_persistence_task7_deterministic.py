#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = (
    root
    / "test/features/dashboard/"
    "tasks_panel_persistence_test.dart"
)
if not path.is_file():
    raise SystemExit(f"Missing deterministic Task 7 test: {path}")

source = path.read_text(encoding="utf-8")
required = [
    "final class _MemoryTaskRepository implements TaskRepository",
    "taskRepositoryProvider.overrideWithValue(repository)",
    "adding a task calls the repository",
    "edit completion and delete actions call the repository",
    "remount reads the current repository state",
    "await tester.pump(const Duration(milliseconds: 300))",
]
forbidden = [
    "AppDatabase",
    "NativeDatabase",
    "pumpAndSettle",
    "waitForTasks",
    "tester.runAsync",
]

missing = [item for item in required if item not in source]
present = [item for item in forbidden if item in source]

if missing:
    raise SystemExit(
        "Missing deterministic markers: " + ", ".join(missing)
    )
if present:
    raise SystemExit(
        "Forbidden flaky markers remain: " + ", ".join(present)
    )

print("Task 7 deterministic widget tests verified.")
