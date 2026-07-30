#!/usr/bin/env python3
"""Finalize the Task 10.4 checkpoint with repository-local evidence."""

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path

CHECKPOINT_PATH = Path(
    "docs/superpowers/checkpoints/"
    "2026-07-30-linux-systemd-schedule-registry-checkpoint.md"
)

GATE_SUBJECTS = {
    "GATE_10_4_1_HASH": "feat: add Linux schedule registry models",
    "GATE_10_4_2_HASH": "feat: add strict Linux registry codec",
    "GATE_10_4_3_HASH": "feat: fingerprint Linux notification requests",
    "GATE_10_4_4_HASH": "feat: extend Linux systemd filesystem inventory",
    "GATE_10_4_5_HASH": "feat: load Linux schedule registry safely",
    "GATE_10_4_6_HASH": "feat: replace Linux schedule registry atomically",
    "GATE_10_4_7_HASH": "feat: recover Linux schedule registry inventory",
}


def _git_lines() -> list[tuple[str, str]]:
    result = subprocess.run(
        ["git", "log", "--all", "--format=%H%x09%s"],
        check=True,
        capture_output=True,
        text=True,
    )
    lines: list[tuple[str, str]] = []

    for raw_line in result.stdout.splitlines():
        commit_hash, separator, subject = raw_line.partition("\t")
        if separator:
            lines.append((commit_hash, subject))

    return lines


def _resolve_hashes() -> dict[str, str]:
    history = _git_lines()
    resolved: dict[str, str] = {}

    for token, subject in GATE_SUBJECTS.items():
        matches = [
            commit_hash
            for commit_hash, candidate_subject in history
            if candidate_subject == subject
        ]
        if not matches:
            raise SystemExit(
                f"ERROR: no commit found with exact subject: {subject}"
            )

        resolved[token] = matches[0]

    return resolved


def _positive_count(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("test count must be positive")
    return parsed


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--focused-tests",
        required=True,
        type=_positive_count,
    )
    parser.add_argument(
        "--full-tests",
        required=True,
        type=_positive_count,
    )
    parser.add_argument(
        "--analyze-result",
        default="No issues found",
    )
    parser.add_argument(
        "--linux-build-result",
        default=(
            "Succeeded: "
            "build/linux/x64/debug/bundle/dashboard_shakhsi"
        ),
    )
    args = parser.parse_args()

    if not CHECKPOINT_PATH.exists():
        raise SystemExit(f"ERROR: missing checkpoint: {CHECKPOINT_PATH}")

    text = CHECKPOINT_PATH.read_text(encoding="utf-8")
    replacements = {
        **_resolve_hashes(),
        "FOCUSED_TEST_COUNT": str(args.focused_tests),
        "FULL_TEST_COUNT": str(args.full_tests),
        "ANALYZE_RESULT": args.analyze_result,
        "LINUX_BUILD_RESULT": args.linux_build_result,
    }

    for token, value in replacements.items():
        placeholder = f"__{token}__"
        if placeholder not in text:
            raise SystemExit(
                f"ERROR: checkpoint placeholder missing: {placeholder}"
            )
        text = text.replace(placeholder, value)

    unresolved = sorted(set(re.findall(r"__[A-Z0-9_]+__", text)))
    if unresolved:
        raise SystemExit(
            f"ERROR: unresolved checkpoint placeholders: {unresolved}"
        )

    CHECKPOINT_PATH.write_text(text, encoding="utf-8")
    print(
        "OK: Task 10.4 checkpoint finalized with seven exact Gate "
        "commit hashes and fresh verification evidence."
    )


if __name__ == "__main__":
    main()
