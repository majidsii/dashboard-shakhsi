#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PRODUCTION = (
    ROOT
    / "lib/features/tasks/presentation/task_details/task_details_draft.dart"
)
TEST = (
    ROOT
    / "test/features/tasks/presentation/task_details/"
    "task_details_draft_test.dart"
)


def need(condition: bool, message: str) -> None:
    if not condition:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


for path in (PRODUCTION, TEST):
    need(path.exists(), f"missing required file: {path}")

source = PRODUCTION.read_text(encoding="utf-8")
tests = TEST.read_text(encoding="utf-8")

for forbidden in (
    "package:flutter/",
    "material.dart",
    "widgets.dart",
    "cupertino.dart",
    "Widget",
    "BuildContext",
    "TaskRepository",
    "DateTime.now",
):
    need(forbidden not in source, f"pure draft contains forbidden dependency: {forbidden}")

need(
    re.search(
        r"enum\s+TaskDetailsField\s*\{"
        r"(?=[^}]*\btitle\b)"
        r"(?=[^}]*\bstartAt\b)"
        r"(?=[^}]*\bdueAt\b)"
        r"(?=[^}]*\bestimatedDuration\b)"
        r"[^}]*\}",
        source,
        re.DOTALL,
    )
    is not None,
    "TaskDetailsField enum contract is incomplete",
)

need(
    re.search(r"final\s+class\s+TaskDetailsDraft\b", source) is not None,
    "TaskDetailsDraft final class is missing",
)

required_api_patterns = {
    "create factory": (
        r"factory\s+TaskDetailsDraft\.create\s*\(\s*\{"
        r"(?=[^}]*required\s+DateTime\s+nowLocal)"
        r"(?=[^}]*int\s+priority\s*=\s*0)"
    ),
    "fromTask factory": (
        r"factory\s+TaskDetailsDraft\.fromTask\s*\(\s*TaskItem\s+task\s*\)"
    ),
    "validate": (
        r"Map<TaskDetailsField\s*,\s*String>\s+validate\s*\(\s*\)"
    ),
    "buildNewTask": (
        r"TaskItem\s+buildNewTask\s*\(\s*\{"
        r"(?=[^}]*required\s+String\s+id)"
        r"(?=[^}]*required\s+DateTime\s+savedAtUtc)"
    ),
    "applyTo": (
        r"TaskItem\s+applyTo\s*\(\s*\{"
        r"(?=[^}]*required\s+TaskItem\s+task)"
        r"(?=[^}]*required\s+DateTime\s+savedAtUtc)"
    ),
}
for label, pattern in required_api_patterns.items():
    need(
        re.search(pattern, source, re.DOTALL) is not None,
        f"required API missing: {label}",
    )

for field in (
    "String title;",
    "String description;",
    "int priority;",
    "DateTime? startLocal;",
    "DateTime? dueLocal;",
    "int estimatedHours;",
    "int estimatedMinutes;",
):
    need(field in source, f"mutable draft field missing: {field}")

need(
    "task.startAtUtc?.toLocal()" in source
    and "task.dueAtUtc?.toLocal()" in source,
    "edit initialization does not convert UTC values to local",
)
need(
    "startLocal?.toUtc()" in source and "dueLocal?.toUtc()" in source,
    "projection does not convert local values to UTC",
)

need(
    re.search(
        r"estimatedMinutes\s*<\s*0\s*\|\|\s*estimatedMinutes\s*>\s*59",
        source,
    )
    is not None,
    "minute range 0..59 is not enforced",
)
need(
    re.search(r"estimatedHours\s*<\s*0", source) is not None,
    "non-negative hours are not enforced",
)
need(
    re.search(
        r"estimatedHours\s*==\s*0\s*&&\s*estimatedMinutes\s*==\s*0",
        source,
    )
    is not None,
    "zero hours and minutes are not normalized to null",
)
need(
    re.search(r"estimatedHours\s*\*\s*60\s*\+\s*estimatedMinutes", source)
    is not None,
    "duration is not normalized to total minutes",
)
need(
    re.search(r"due\.isBefore\s*\(\s*start\s*\)", source) is not None,
    "due-before-start validation is missing",
)

for placeholder in (
    "displayNumber: 1",
    "status: TaskStatus.planned",
    "positionInStatus: 0",
    "createdAtUtc: savedAtUtc",
    "updatedAtUtc: savedAtUtc",
):
    need(placeholder in source, f"new-task projection missing: {placeholder}")

for clear_flag in (
    "clearDescription: normalizedDescription == null",
    "clearStartAt: startAtUtc == null",
    "clearDueAt: dueAtUtc == null",
    "clearEstimatedDuration: durationMinutes == null",
):
    need(clear_flag in source, f"explicit update clear behavior missing: {clear_flag}")

for immutable_field in (
    "expect(updated.id, existing.id)",
    "expect(updated.displayNumber, existing.displayNumber)",
    "expect(updated.createdAtUtc, existing.createdAtUtc)",
    "expect(updated.status, existing.status)",
    "expect(updated.positionInStatus, existing.positionInStatus)",
    "expect(updated.completedAtUtc, existing.completedAtUtc)",
    "expect(updated.canceledAtUtc, existing.canceledAtUtc)",
):
    need(immutable_field in tests, f"update preservation test missing: {immutable_field}")

coverage_tokens = (
    "create mode starts with empty optional fields and supplied priority",
    "edit mode converts UTC fields to local and splits duration",
    "new projection normalizes text local time and duration",
    "due before start maps only to the due field",
    "duration uses explicit non-negative hours and minute range 0 to 59",
    "blank title is a field error and blocks projection",
    "update projection preserves identity workflow order and terminals",
    "update projection explicitly clears every optional planning field",
    "(0, -1)",
    "(0, 60)",
    "(1, 75)",
    "estimatedDurationMinutes, 90",
    "estimatedDurationMinutes, isNull",
)
for token in coverage_tokens:
    need(token in tests, f"focused coverage missing: {token}")

print(
    "OK: Gate 2.2.4 provides a Flutter-independent mutable task-details "
    "draft with field validation, text and duration normalization, local/UTC "
    "conversion, deterministic create projection, immutable-safe update "
    "projection, and explicit optional-field clearing."
)
