#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PRODUCTION = ROOT / "lib/features/tasks/domain/task_item.dart"
TESTS = ROOT / "test/features/tasks/domain/task_item_test.dart"


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


def normalized(value: str) -> str:
    return re.sub(r"\s+", " ", value)


def main() -> int:
    require(PRODUCTION.exists(), f"missing production file: {PRODUCTION}")
    require(TESTS.exists(), f"missing test file: {TESTS}")

    source = PRODUCTION.read_text(encoding="utf-8")
    tests = TESTS.read_text(encoding="utf-8")
    compact_source = normalized(source)
    compact_tests = normalized(tests)

    declarations = {
        "description": r"final\s+String\?\s+description\s*;",
        "startAtUtc": r"final\s+DateTime\?\s+startAtUtc\s*;",
        "dueAtUtc": r"final\s+DateTime\?\s+dueAtUtc\s*;",
        "estimatedDurationMinutes": r"final\s+int\?\s+estimatedDurationMinutes\s*;",
    }
    for name, pattern in declarations.items():
        require(
            re.search(pattern, source, re.DOTALL) is not None,
            f"missing canonical field declaration: {name}",
        )

    constructor_checks = (
        r"String\?\s+description",
        r"this\.startAtUtc",
        r"this\.dueAtUtc",
        r"this\.estimatedDurationMinutes",
    )
    for pattern in constructor_checks:
        require(
            re.search(pattern, source, re.DOTALL) is not None,
            f"constructor contract missing: {pattern}",
        )

    require(
        re.search(
            r"description\s*=\s*_normalizeOptionalText\s*\(\s*description\s*\)",
            source,
            re.DOTALL,
        ) is not None,
        "description is not normalized canonically",
    )
    require(
        re.search(
            r"String\?\s+_normalizeOptionalText\s*\(\s*String\?\s+value\s*\)",
            source,
            re.DOTALL,
        ) is not None,
        "optional-text normalizer is missing",
    )
    require(
        re.search(r"_validateUtc\s*\(\s*startAt\s*\)", source) is not None,
        "start timestamp is not UTC validated",
    )
    require(
        re.search(r"_validateUtc\s*\(\s*dueAt\s*\)", source) is not None,
        "due timestamp is not UTC validated",
    )
    require(
        re.search(
            r"dueAt\s*\.\s*isBefore\s*\(\s*startAt\s*\)",
            source,
            re.DOTALL,
        ) is not None,
        "due-before-start validation is missing",
    )
    require(
        re.search(
            r"estimatedDuration\s*!=\s*null\s*&&\s*estimatedDuration\s*<=\s*0",
            source,
            re.DOTALL,
        ) is not None,
        "positive estimated-duration validation is missing",
    )

    clear_flags = (
        "clearDescription",
        "clearStartAt",
        "clearDueAt",
        "clearEstimatedDuration",
    )
    for clear_flag in clear_flags:
        require(
            re.search(
                rf"bool\s+{re.escape(clear_flag)}\s*=\s*false",
                source,
                re.DOTALL,
            ) is not None,
            f"missing copyWith clear flag: {clear_flag}",
        )

    equality_start = source.find("bool operator ==")
    hash_start = source.find("int get hashCode")
    string_start = source.find("String toString")
    require(
        equality_start >= 0 and hash_start > equality_start,
        "equality region missing",
    )
    require(string_start > hash_start, "hashCode region missing")

    equality_region = source[equality_start:hash_start]
    hash_region = source[hash_start:string_start]
    fields = (
        "description",
        "startAtUtc",
        "dueAtUtc",
        "estimatedDurationMinutes",
    )
    for field in fields:
        require(field in equality_region, f"{field} missing from equality")
        require(field in hash_region, f"{field} missing from hashCode")

    for field in fields:
        require(
            re.search(
                rf"copyWith\s*\([^)]*{re.escape(field)}\s*:",
                tests,
                re.DOTALL,
            ) is not None
            or re.search(
                rf"{re.escape(field)}\s*:",
                tests,
                re.DOTALL,
            ) is not None,
            f"focused tests do not exercise {field}",
        )

    require(
        "throwsA(isA<ValidationFailure>())" in compact_tests,
        "focused tests do not assert validation failures",
    )
    require(
        "DateTime(" in tests and "DateTime.utc(" in tests,
        "focused tests do not distinguish local and UTC timestamps",
    )
    require(
        all(flag in tests for flag in clear_flags),
        "focused tests do not exercise all explicit clear flags",
    )

    equality_coverage = (
        "equality includes planning fields" in tests
        or "equality and hash include planning fields" in tests
        or (
            "isNot(base.copyWith(description:" in compact_tests
            and "isNot(base.copyWith(estimatedDurationMinutes:" in compact_tests
        )
    )
    require(
        equality_coverage,
        "focused tests do not semantically cover planning-field equality",
    )

    require(
        "blank description" in compact_tests
        or "description: '   '" in tests,
        "focused tests do not cover blank-description normalization",
    )
    require(
        "estimatedDurationMinutes: 0" in compact_tests
        or "<int>[0, -1]" in compact_tests,
        "focused tests do not cover non-positive estimated duration",
    )

    print(
        "OK: Gate 2.2.1 has canonical normalized planning fields, UTC and "
        "ordering validation, positive duration, explicit clearing, and "
        "semantic focused domain coverage."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
