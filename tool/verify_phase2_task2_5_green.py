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
task_item = read("lib/features/tasks/domain/task_item.dart")
task_repository = read("lib/features/tasks/domain/task_repository.dart")
design = read(
    "docs/superpowers/specs/2026-08-05-shared-recurrence-engine-design.md"
)
plan = read(
    "docs/superpowers/plans/2026-08-05-task-2-5-shared-recurrence-engine.md"
)
frequency = read("lib/core/recurrence/recurrence_frequency.dart")
calendar = read("lib/core/recurrence/recurrence_calendar.dart")
local = read("lib/core/recurrence/recurrence_local_date_time.dart")
timezone_model = read("lib/core/recurrence/recurrence_time_zone.dart")
end = read("lib/core/recurrence/recurrence_end.dart")
rule = read("lib/core/recurrence/recurrence_rule.dart")
exception = read("lib/core/recurrence/recurrence_exception.dart")
occurrence = read("lib/core/recurrence/recurrence_occurrence.dart")
adapter = read("lib/core/recurrence/recurrence_calendar_adapter.dart")
gregorian = read(
    "lib/core/recurrence/gregorian_recurrence_calendar.dart"
)
jalali = read("lib/core/recurrence/jalali_recurrence_calendar.dart")
resolver = read(
    "lib/core/recurrence/recurrence_time_zone_resolver.dart"
)
engine = read("lib/core/recurrence/recurrence_engine.dart")

schema_match = re.search(
    r"int\s+get\s+schemaVersion\s*=>\s*(\d+)\s*;",
    database,
)
need(schema_match is not None, "schema version is missing")
need(int(schema_match.group(1)) >= 5, "schema regressed below version 5")
need(
    "class RecurrenceRuleRows" not in database,
    "shared recurrence must not own a generic persistence table",
)
need(
    "RecurrenceRule" not in task_item,
    "TaskItem must remain free of recurrence state",
)
need(
    "recurrence" not in task_repository.lower(),
    "TaskRepository contract must remain recurrence-free",
)

for token in ("daily", "weekly", "monthly", "yearly"):
    need(token in frequency, f"frequency missing: {token}")
for token in ("gregorian", "jalali"):
    need(token in calendar, f"calendar missing: {token}")
for token in (
    "storageKey",
    "compareTo",
    "year",
    "month",
    "day",
    "hour",
    "minute",
):
    need(token in local, f"local civil contract missing: {token}")
for token in (
    "RecurrenceTimeZoneMode",
    "fixed",
    "floating",
    "resolveTimeZoneId",
):
    need(token in timezone_model, f"timezone model missing: {token}")
for token in ("never", "until", "afterCount"):
    need(token in end, f"termination mode missing: {token}")
for token in (
    "RecurrenceRule.daily",
    "RecurrenceRule.weekly",
    "RecurrenceRule.monthly",
    "RecurrenceRule.yearly",
    "weeklyDays",
    "monthlySelectors",
    "annualDates",
    "invalidDatePolicy",
):
    need(token in rule, f"rule contract missing: {token}")
for token in ("skip", "cancel", "move", "originalLocalDateTime"):
    need(token in exception, f"exception contract missing: {token}")
for token in (
    "originalLocalDateTime",
    "effectiveLocalDateTime",
    "instantUtc",
    "timeZoneId",
    "sequence",
    "scheduled",
    "moved",
    "skipped",
    "canceled",
):
    need(token in occurrence, f"occurrence contract missing: {token}")

for token in (
    "isValidDate",
    "daysInMonth",
    "weekday",
    "addDays",
    "shiftMonth",
    "toGregorianCivil",
    "fromGregorianCivil",
):
    need(token in adapter, f"calendar adapter API missing: {token}")
need(
    "RecurrenceCalendar.gregorian" in gregorian,
    "Gregorian adapter identity missing",
)
for token in (
    "Jalali(",
    ".toGregorian()",
    "Gregorian(",
    ".toJalali()",
    "RecurrenceCalendar.jalali",
):
    need(token in jalali, f"Jalali adapter missing: {token}")

for token in (
    "TimezoneRecurrenceResolver",
    "timezone.getLocation",
    "maximumGapSearchMinutes",
    "_exactMatches",
    "matches.sort",
    "matches.first",
    "_addCivilMinute",
):
    need(token in resolver, f"timezone/DST contract missing: {token}")

for token in (
    "List<RecurrenceOccurrence> expand",
    "rangeStartUtc",
    "rangeEndUtc",
    "floatingTimeZoneId",
    "maximumOccurrences",
    "RecurrenceEndKind.until",
    "RecurrenceEndKind.afterCount",
    "RecurrenceExceptionAction.skip",
    "RecurrenceExceptionAction.cancel",
    "RecurrenceExceptionAction.move",
    "RecurrenceInvalidDatePolicy.skipPeriod",
    "RecurrenceInvalidDatePolicy.clampToLastDay",
    "_candidatePeriods",
    "_CandidatePeriod",
    "_dailyCandidates",
    "_weeklyCandidates",
    "_monthlyCandidates",
    "_yearlyCandidates",
    "List<RecurrenceOccurrence>.unmodifiable",
):
    need(token in engine, f"engine contract missing: {token}")

tests = "\n".join(
    read(relative)
    for relative in (
        "test/core/recurrence/recurrence_domain_test.dart",
        "test/core/recurrence/recurrence_calendar_adapter_test.dart",
        "test/core/recurrence/recurrence_time_zone_resolver_test.dart",
        "test/core/recurrence/recurrence_engine_test.dart",
    )
)
for token in (
    "DST gap advances to the first valid local minute",
    "DST overlap chooses the first matching instant",
    "Jalali adapter crosses month and year boundaries deterministically",
    "Jalali leap year crosses Esfand into Farvardin",
    "weekly rules support multiple weekdays and week intervals",
    "monthly invalid dates can skip periods",
    "monthly invalid dates can clamp and duplicate selectors collapse",
    "monthly and yearly intervals skip inactive periods",
    "yearly leap dates skip invalid years",
    "impossible active periods terminate at the requested range",
    "fixed and floating timezone modes resolve independently",
    "until is inclusive and expansion ranges are half-open",
    "skip cancel and move exceptions preserve original sequence",
    "same inputs produce equal restart-safe output",
):
    need(token in tests, f"focused recurrence coverage missing: {token}")

for token in (
    "Task 2.5 creates only `lib/core/recurrence/`",
    "first valid civil minute",
    "does not change Drift schema version 5",
):
    need(token in design, f"approved design missing: {token}")
for token in (
    "Shared Recurrence Engine Implementation Plan",
    "flutter test test/core/recurrence",
    'git commit -m "feat: add shared recurrence engine"',
):
    need(token in plan, f"implementation plan missing: {token}")

run_verifier("tool/verify_phase2_task2_4_complete.py")

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
    "OK: Task 2.5 preserves a schema-neutral shared recurrence domain, "
    "Gregorian/Jalali adapters, fixed/floating IANA timezone resolution, "
    "first-valid DST-gap and first-instant overlap policy, deterministic "
    "daily/weekly/monthly/yearly expansion, inclusive termination, "
    "skip/cancel/move exceptions, half-open range filtering, safety bounds, "
    "and stable Task 2.4 compatibility."
)
