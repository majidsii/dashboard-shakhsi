#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = ROOT / "lib/features/tasks/data/drift_task_repository.dart"
INTERFACE = ROOT / "lib/features/tasks/domain/task_repository.dart"
TEST = ROOT / "test/features/tasks/data/drift_task_repository_planning_test.dart"


def need(value: bool, message: str) -> None:
    if not value:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


for path in (REPOSITORY, INTERFACE, TEST):
    need(path.exists(), f"missing {path}")

source = REPOSITORY.read_text(encoding="utf-8")
interface = INTERFACE.read_text(encoding="utf-8")
test = TEST.read_text(encoding="utf-8")

read_patterns = {
    "description": r"description\s*:\s*row\.description",
    "startAtUtc": (
        r"startAtUtc\s*:\s*row\.startAtUtc\?\s*\.\s*toUtc\s*\(\s*\)"
    ),
    "dueAtUtc": (
        r"dueAtUtc\s*:\s*row\.dueAtUtc\?\s*\.\s*toUtc\s*\(\s*\)"
    ),
    "estimatedDurationMinutes": (
        r"estimatedDurationMinutes\s*:\s*row\.estimatedDurationMinutes"
    ),
}
for name, pattern in read_patterns.items():
    need(
        re.search(pattern, source, re.DOTALL) is not None,
        f"row mapping missing: {name}",
    )

write_patterns = {
    "description": (
        r"description\s*:\s*Value<String\?>\s*\(\s*"
        r"task\.description\s*,?\s*\)"
    ),
    "startAtUtc": (
        r"startAtUtc\s*:\s*Value<DateTime\?>\s*\(\s*"
        r"task\.startAtUtc\s*,?\s*\)"
    ),
    "dueAtUtc": (
        r"dueAtUtc\s*:\s*Value<DateTime\?>\s*\(\s*"
        r"task\.dueAtUtc\s*,?\s*\)"
    ),
    "estimatedDurationMinutes": (
        r"estimatedDurationMinutes\s*:\s*Value<int\?>\s*\(\s*"
        r"task\.estimatedDurationMinutes\s*,?\s*\)"
    ),
}
for name, pattern in write_patterns.items():
    need(
        re.search(pattern, source, re.DOTALL) is not None,
        f"companion mapping missing: {name}",
    )

update_match = re.search(
    r"Future<void>\s+update\s*\(\s*TaskItem\s+task\s*\)"
    r"(?P<body>.*?)"
    r"Future<void>\s+transition\s*\(",
    source,
    re.DOTALL,
)
need(update_match is not None, "update body missing")
update_body = update_match.group("body")

for field in (
    "description",
    "startAtUtc",
    "dueAtUtc",
    "estimatedDurationMinutes",
):
    need(field in update_body, f"update does not persist {field}")

for forbidden in (
    "setDescription",
    "setStartAt",
    "setDueAt",
    "setEstimatedDuration",
    "updatePlanning",
):
    need(
        forbidden not in interface,
        f"TaskRepository gained forbidden method {forbidden}",
    )

for required_method in (
    "watchAll",
    "watchByStatus",
    "getById",
    "create",
    "update",
    "transition",
    "reorderWithinStatus",
    "delete",
    "deleteCompleted",
):
    need(required_method in interface, f"TaskRepository lost {required_method}")

coverage_tokens = (
    "create update and clear round-trip every task planning field",
    "transition and reorder preserve every task planning field",
    "task planning fields survive closing and reopening the database",
    "clearDescription: true",
    "clearStartAt: true",
    "clearDueAt: true",
    "clearEstimatedDuration: true",
    "repository.transition(",
    "repository.reorderWithinStatus(",
    "final reopenedDatabase = AppDatabase",
    "reopened.startAtUtc!.isUtc",
    "reopened.dueAtUtc!.isUtc",
)
for token in coverage_tokens:
    need(token in test, f"focused test coverage missing: {token}")

need(
    re.search(
        r"expect\s*\(\s*created\s*!?\s*\.\s*displayNumber\s*,\s*1\s*\)",
        test,
        re.DOTALL,
    )
    is not None,
    "create test does not preserve repository-owned display number allocation",
)
need(
    re.search(
        r"expect\s*\(\s*created\s*!?\s*\.\s*positionInStatus\s*,\s*0\s*\)",
        test,
        re.DOTALL,
    )
    is not None,
    "create test does not preserve repository-owned position allocation",
)

clear_assertions = {
    "description": (
        r"expect\s*\(\s*cleared\s*!?\s*\.\s*description\s*,\s*isNull\s*\)"
    ),
    "startAtUtc": (
        r"expect\s*\(\s*cleared\s*!?\s*\.\s*startAtUtc\s*,\s*isNull\s*\)"
    ),
    "dueAtUtc": (
        r"expect\s*\(\s*cleared\s*!?\s*\.\s*dueAtUtc\s*,\s*isNull\s*\)"
    ),
    "estimatedDurationMinutes": (
        r"expect\s*\(\s*cleared\s*!?\s*\.\s*"
        r"estimatedDurationMinutes\s*,\s*isNull\s*\)"
    ),
}
for name, pattern in clear_assertions.items():
    need(
        re.search(pattern, test, re.DOTALL) is not None,
        f"clear persistence assertion missing: {name}",
    )

need(
    re.search(
        r"startAtUtc\s*:\s*row\.startAtUtc\?\s*\.\s*toUtc\s*\(\s*\)",
        source,
        re.DOTALL,
    )
    is not None
    and re.search(
        r"dueAtUtc\s*:\s*row\.dueAtUtc\?\s*\.\s*toUtc\s*\(\s*\)",
        source,
        re.DOTALL,
    )
    is not None,
    "repository read mapping does not normalize planning timestamps to UTC",
)

need(
    re.search(
        r"expect\s*\(\s*reopened\s*!?\s*\.\s*startAtUtc\s*!\s*"
        r"\.\s*isUtc\s*,\s*isTrue\s*\)",
        test,
        re.DOTALL,
    )
    is not None,
    "restart test does not prove UTC start timestamp",
)
need(
    re.search(
        r"expect\s*\(\s*reopened\s*!?\s*\.\s*dueAtUtc\s*!\s*"
        r"\.\s*isUtc\s*,\s*isTrue\s*\)",
        test,
        re.DOTALL,
    )
    is not None,
    "restart test does not prove UTC due timestamp",
)

print(
    "OK: Gate 2.2.3 maps all planning fields through create/get/update, "
    "supports persisted clearing, preserves them across transition/reorder, "
    "normalizes timestamps to UTC on read, proves restart persistence, and "
    "keeps the TaskRepository interface unchanged."
)
