#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
DATABASE = ROOT / "lib/core/database/app_database.dart"
GENERATED = ROOT / "lib/core/database/app_database.g.dart"
TEST = ROOT / "test/core/database/task_planning_migration_test.dart"
RESTART = ROOT / "test/core/database/database_restart_test.dart"


def need(value: bool, message: str) -> None:
    if not value:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


def compact(value: str) -> str:
    return re.sub(r"\s+", " ", value)


def dart_sql(value: str) -> str:
    # Dart commonly splits one SQL CHECK across adjacent string literals:
    # 'CHECK (...) ' 'OR ...'
    # Remove literal boundaries before semantic matching.
    value = re.sub(r"(['\"])\s*(['\"])", "", value)
    return compact(value)


for path in (DATABASE, GENERATED, TEST, RESTART):
    need(path.exists(), f"missing {path}")

source = DATABASE.read_text(encoding="utf-8")
generated = GENERATED.read_text(encoding="utf-8")
test = TEST.read_text(encoding="utf-8")
restart = RESTART.read_text(encoding="utf-8")

flat_source = compact(source)
sql_source = dart_sql(source)
flat_test = compact(test)
flat_restart = compact(restart)

need(
    re.search(r"schemaVersion\s*=>\s*4\s*;", source) is not None,
    "schemaVersion != 4",
)

patterns = {
    "description": (
        r"TextColumn\s+get\s+description\s*=>\s*"
        r"text\(\)\.nullable\(\)\(\)"
    ),
    "startAtUtc": (
        r"DateTimeColumn\s+get\s+startAtUtc\s*=>\s*"
        r"dateTime\(\)\.nullable\(\)\(\)"
    ),
    "dueAtUtc": (
        r"DateTimeColumn\s+get\s+dueAtUtc\s*=>\s*"
        r"dateTime\(\)\.nullable\(\)\(\)"
    ),
    "estimatedDurationMinutes": (
        r"IntColumn\s+get\s+estimatedDurationMinutes\s*=>\s*"
        r"integer\(\)\.nullable\(\)\(\)"
    ),
}
for name, pattern in patterns.items():
    need(
        re.search(pattern, source, re.DOTALL) is not None,
        f"missing nullable {name}",
    )

need(
    re.search(
        r"estimated_duration_minutes\s+IS\s+NULL\s+OR\s+"
        r"estimated_duration_minutes\s*>\s*0",
        sql_source,
        re.IGNORECASE,
    ) is not None,
    "duration CHECK missing",
)

need(
    re.search(
        r"start_at_utc\s+IS\s+NULL\s+OR\s+"
        r"due_at_utc\s+IS\s+NULL\s+OR\s+"
        r"due_at_utc\s*>=\s*start_at_utc",
        sql_source,
        re.IGNORECASE,
    ) is not None,
    "start/due CHECK missing",
)

need(
    re.search(
        r"if\s*\(\s*from\s*>=\s*3\s*&&\s*from\s*<\s*4\s*\)",
        source,
    ) is not None,
    "3->4 branch missing",
)

start = source.find("ALTER TABLE tasks RENAME TO tasks_v3_legacy")
end = source.find("DROP TABLE tasks_v3_legacy", start)
need(start >= 0 and end > start, "migration region missing")

region = dart_sql(source[start:end])

for token in (
    "migrator.createTable(taskRows)",
    "FROM tasks_v3_legacy",
    "NULL AS description",
    "NULL AS start_at_utc",
    "NULL AS due_at_utc",
    "NULL AS estimated_duration_minutes",
):
    need(token in region, f"migration token missing: {token}")

for column in (
    "id",
    "display_number",
    "title",
    "priority",
    "status",
    "position_in_status",
    "created_at_utc",
    "updated_at_utc",
    "completed_at_utc",
    "canceled_at_utc",
):
    need(column in region, f"legacy column not preserved: {column}")

for name in (
    "description",
    "startAtUtc",
    "dueAtUtc",
    "estimatedDurationMinutes",
):
    need(name in generated, f"generated Drift output missing: {name}")

need("PRAGMA user_version = 3" in test, "schema-3 fixture missing")
need("PRAGMA table_info(tasks)" in test, "table shape assertion missing")
need("final reopened = AppDatabase" in test, "reopen proof missing")
need("throwsA(anything)" in flat_test, "constraint proof missing")
need(
    "expect(migrated.schemaVersion, 4)" in flat_test,
    "migrated schema assertion missing",
)
need(
    "expect(reopened.schemaVersion, 4)" in flat_test,
    "reopened schema assertion missing",
)

for column in (
    "description",
    "start_at_utc",
    "due_at_utc",
    "estimated_duration_minutes",
):
    need(column in test, f"test coverage missing column {column}")

need("schema version four" in restart, "restart test title not updated")
need(
    "expect(first.schemaVersion, 4)" in flat_restart,
    "first-open schema assertion missing",
)
need(
    "expect(reopened.schemaVersion, 4)" in flat_restart,
    "reopen schema assertion missing",
)
need(
    "read<int>('user_version'), 4" in flat_restart,
    "PRAGMA v4 assertion missing",
)

print(
    "OK: Gate 2.2.2 defines schema 4 planning columns and constraints, "
    "preserves schema-3 rows with null planning fields, regenerates Drift, "
    "and proves deterministic reopen behavior."
)
