#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
test_file = root / "test/features/tasks/data/drift_task_repository_test.dart"

if not test_file.is_file():
    raise SystemExit(f"Missing RED test file: {test_file}")

source = test_file.read_text(encoding="utf-8")
required_markers = [
    "DriftTaskRepository",
    "watchAll emits inserted tasks in stable sort order",
    "update persists all editable task fields",
    "setDone stores UTC completion and clears it when reopened",
    "deleteCompleted keeps only active tasks",
    "delete removes only the requested task",
    "reorder writes contiguous sort order atomically",
    "task survives reopening the same file database",
    "NativeDatabase(file)",
]

missing = [marker for marker in required_markers if marker not in source]
if missing:
    raise SystemExit("Missing RED markers: " + ", ".join(missing))

print("Persistence Task 3 RED tests contract verified.")
