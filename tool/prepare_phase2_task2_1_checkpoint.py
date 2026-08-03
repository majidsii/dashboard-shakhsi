#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
from datetime import date
from pathlib import Path

GATES = (
    ("2.1.1", "feat: add task status storage contract"),
    ("2.1.2", "feat: add task status and ordering fields"),
    ("2.1.3", "feat: migrate tasks to status ordering schema"),
    ("2.1.4", "feat: persist stable task display numbers"),
    ("2.1.5", "feat: add atomic task status transitions"),
    ("2.1.6", "feat: preserve task panel on status model"),
)

CHECKPOINT = Path("docs/superpowers/checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md")
PLAN = Path("docs/superpowers/plans/2026-08-02-task-2-1-status-ordering-foundation.md")
DESIGN = Path("docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md")

TESTS = (
    Path("test/features/tasks/domain/task_status_test.dart"),
    Path("test/features/tasks/domain/task_item_test.dart"),
    Path("test/core/database/task_status_migration_test.dart"),
    Path("test/core/database/app_database_test.dart"),
    Path("test/core/database/database_restart_test.dart"),
    Path("test/features/tasks/data/drift_task_repository_test.dart"),
    Path("test/features/tasks/data/drift_task_repository_transition_test.dart"),
    Path("test/core/providers/persistence_providers_test.dart"),
    Path("test/features/dashboard/tasks_panel_test.dart"),
    Path("test/features/dashboard/tasks_panel_persistence_test.dart"),
)

ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
COUNT = re.compile(r"\+(\d+): All tests passed!")

def read_success(path: Path, marker: str, label: str) -> str:
    if not path.is_file():
        raise SystemExit(f"ERROR: missing {label} log: {path}")
    text = ANSI.sub("", path.read_text(encoding="utf-8", errors="replace"))
    if marker not in text:
        raise SystemExit(f"ERROR: {label} log lacks marker: {marker}")
    return text

def test_count(path: Path, label: str) -> int:
    text = read_success(path, "All tests passed!", label)
    matches = COUNT.findall(text)
    if not matches:
        raise SystemExit(f"ERROR: cannot parse test count from {path}")
    return int(matches[-1])

def git_output(*args: str) -> str:
    result = subprocess.run(
        ("git", *args),
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode:
        raise SystemExit(
            f"ERROR: git {' '.join(args)} failed:\n{result.stderr.strip()}"
        )
    return result.stdout

def _gate_hashes() -> list[tuple[str, str, str]]:
    history = []
    for line in git_output("log", "--all", "--format=%H%x09%s").splitlines():
        commit_hash, sep, subject = line.partition("\t")
        if sep and re.fullmatch(r"[0-9a-f]{40}", commit_hash):
            history.append((commit_hash, subject))

    rows = []
    for gate, subject in GATES:
        matches = [(h, s) for h, s in history if s == subject]
        if not matches:
            raise SystemExit(f"ERROR: exact Gate {gate} commit not found: {subject}")
        commit_hash, found_subject = matches[0]
        ancestor = subprocess.run(
            ("git", "merge-base", "--is-ancestor", commit_hash, "HEAD"),
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if ancestor.returncode:
            raise SystemExit(f"ERROR: Gate {gate} is not an ancestor of HEAD")
        rows.append((gate, commit_hash, found_subject))

    if len({h for _, h, _ in rows}) != 6:
        raise SystemExit("ERROR: Gate evidence reused a commit hash")
    return rows

def verify_inventory(focused_log: str) -> None:
    missing_files = [str(path) for path in TESTS if not path.is_file()]
    if missing_files:
        raise SystemExit(f"ERROR: focused test files missing: {missing_files}")

    missing_log = [str(path) for path in TESTS if str(path) not in focused_log]
    if missing_log:
        raise SystemExit(f"ERROR: focused log omitted tests: {missing_log}")

    combined = "\n".join(
        path.read_text(encoding="utf-8", errors="replace") for path in TESTS
    )
    required = (
        "TaskStatus.planned",
        "TaskStatus.completed",
        "displayNumber",
        "positionInStatus",
        "reorderWithinStatus",
        "taskRepositoryProvider",
    )
    missing = [token for token in required if token not in combined]
    if missing:
        raise SystemExit(f"ERROR: focused evidence missing: {missing}")

def _update_plan(relative: str) -> None:
    text = PLAN.read_text(encoding="utf-8")
    block = (
        "Status: **Implemented and freshly verified**  \n"
        f"Checkpoint: [Task 2.1 status and ordering evidence]({relative})\n\n"
    )
    if block not in text:
        index = text.find("**Goal:**")
        if index < 0:
            raise SystemExit("ERROR: plan Goal marker missing")
        text = text[:index] + block + text[index:]

    heading = "### Gate 2.1.7: Migration, restart, and Task 2.1 checkpoint"
    start = text.find(heading)
    end = text.find("\n## Plan self-review", start)
    if start < 0 or end < 0:
        raise SystemExit("ERROR: Gate 2.1.7 plan section missing")
    section = text[start:end]
    section = re.sub(
        r"- \[ \] \*\*Step ([1-5]):",
        r"- [x] **Step \1:",
        section,
    )
    if len(re.findall(r"- \[x\] \*\*Step [1-5]:", section)) != 5:
        raise SystemExit("ERROR: could not mark all Gate 2.1.7 steps complete")
    PLAN.write_text(text[:start] + section + text[end:], encoding="utf-8")

def _update_design(relative: str) -> None:
    text = DESIGN.read_text(encoding="utf-8")
    old = "Status: Approved for implementation"
    new = "Status: Approved for implementation; Task 2.1 implemented"
    if new not in text:
        if old not in text:
            raise SystemExit("ERROR: design top status unexpected")
        text = text.replace(old, new, 1)

    block = (
        "\n## Implementation status\n\n"
        "- Task 2.1 — Task Status, Display Number, and Per-Status Position: "
        f"**Implemented** ([checkpoint]({relative}))\n"
        "- Tasks 2.2–2.11: **Pending**\n"
        "- Phase 2 overall: **In progress**\n"
    )
    if "## Implementation status" not in text:
        index = text.find("\n## Objective")
        if index < 0:
            raise SystemExit("ERROR: design Objective marker missing")
        text = text[:index] + block + text[index:]

    old_item = "1. **Task 2.1 — Task Status, Display Number, and Per-Status Position**"
    new_item = old_item + f" — **Implemented** ([checkpoint]({relative}))"
    if new_item not in text:
        if old_item not in text:
            raise SystemExit("ERROR: Task 2.1 map item missing")
        text = text.replace(old_item, new_item, 1)

    status = f"Task 2.1 status: **Implemented** — [checkpoint]({relative})"
    if status not in text:
        heading = "## Task 2.1 gate map"
        index = text.find(heading)
        if index < 0:
            raise SystemExit("ERROR: Task 2.1 gate map missing")
        insert = index + len(heading)
        text = text[:insert] + "\n\n" + status + text[insert:]

    DESIGN.write_text(text, encoding="utf-8")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--focused-log", type=Path, default=Path("/tmp/task2-1-focused.log"))
    parser.add_argument("--full-log", type=Path, default=Path("/tmp/task2-1-full.log"))
    parser.add_argument("--analyze-log", type=Path, default=Path("/tmp/task2-1-analyze.log"))
    parser.add_argument("--build-log", type=Path, default=Path("/tmp/task2-1-build.log"))
    args = parser.parse_args()

    focused_text = read_success(args.focused_log, "All tests passed!", "focused")
    focused_count = test_count(args.focused_log, "focused")
    full_count = test_count(args.full_log, "full")
    read_success(args.analyze_log, "No issues found!", "analyze")
    read_success(
        args.build_log,
        "Built build/linux/x64/debug/bundle/dashboard_shakhsi",
        "build",
    )

    if focused_count < 54:
        raise SystemExit(f"ERROR: focused_count < 54: {focused_count}")
    if full_count < 1029:
        raise SystemExit(f"ERROR: full_count < 1029: {full_count}")
    if full_count < focused_count:
        raise SystemExit("ERROR: full count is smaller than focused count")

    diff = subprocess.run(
        ("git", "diff", "--check"),
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if diff.returncode:
        raise SystemExit(f"ERROR: git diff --check failed:\n{diff.stdout.rstrip()}")

    verify_inventory(focused_text)
    gates = _gate_hashes()
    table = "\n".join(
        f"| {gate} | `{commit_hash}` | `{subject}` |"
        for gate, commit_hash, subject in gates
    )

    checkpoint = f"""# Task Status and Ordering Foundation — Task 2.1 Checkpoint

Date finalized: {date.today().isoformat()}  
Phase: 2  
Task: 2.1  
Status: **Implemented and freshly verified**

## Completion boundary

- Task 2.1 — Task Status, Display Number, and Per-Status Position: **Complete**
- Remaining Phase 2 tasks (2.2–2.11): **Not assessed and not marked complete**
- Phase 2 overall: **Not complete**

This checkpoint proves only Task 2.1. It does **not** mark the remainder of
Phase 2 complete.

## Scope completed

Task 2.1 replaces boolean completion and global ordering with four canonical
statuses, immutable display numbers, status-local positions, deterministic
schema version 2 to schema version 3 migration, atomic transitions, independent
reorder behavior, and compatibility behavior for the existing Tasks panel.

## Gate commit evidence

| Gate | Commit | Subject |
|---|---|---|
{table}

## Fresh verification evidence

- Task 2.1 focused tests: **{focused_count} passed**
- Full project tests: **{full_count} passed**
- `flutter analyze`: **No issues found**
- `flutter build linux --debug`: **Succeeded**
- `git diff --check`: **Clean**

## Schema migration evidence

- A real schema version 2 fixture upgrades to schema version 3.
- Every schema version 2 task row is preserved.
- Active rows migrate to `planned`.
- Done rows migrate to `completed`.
- Initial display numbers are positive, unique, and deterministic.
- Initial positions are contiguous inside each mapped status.
- The migration does not use a destructive fallback.

## Restart stability

Restart from the migrated database file preserves row identity, canonical
status, terminal timestamps, immutable display numbers, and contiguous
status-local positions.

## Status/timestamp invariants

- `planned` and `inProgress` clear terminal timestamps.
- `completed` requires `completedAtUtc` and clears `canceledAtUtc`.
- `canceled` requires `canceledAtUtc` and clears `completedAtUtc`.
- Transitions update status, timestamps, ordering, and `updatedAtUtc` atomically.

## Stable display-number evidence

Display numbers remain positive, unique, deterministic, immutable across
transition/reorder/restart, and are not reused after deletion.

## Independent per-status ordering

Every status has its own contiguous zero-based positions. Reordering one status
does not mutate another. Transitions compact the source and insert at the
clamped target position transactionally.

## Existing Tasks panel compatibility

The existing Persian Tasks panel keeps its Liquid Glass structure and copy.
Planned/in-progress remain active, completed remains done, canceled stays
hidden, add creates planned at position zero, completion toggles use atomic
transitions, and delete-completed removes completed rows only.

## Explicit remaining Phase 2 scope

Descriptions, time fields, Kanban/List/Calendar v2 views, reminders,
recurrence, timers, templates, Undo, Trash, audit history, and dashboard layout
configuration remain outside this checkpoint.
"""
    CHECKPOINT.parent.mkdir(parents=True, exist_ok=True)
    CHECKPOINT.write_text(checkpoint, encoding="utf-8")

    relative = "../checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md"
    _update_plan(relative)
    _update_design(relative)

    print(
        "OK: Task 2.1 checkpoint prepared with "
        f"{focused_count} focused tests, {full_count} full tests, six exact "
        "Gate hashes, clean analyze/build/diff evidence, migration/restart "
        "proof, invariant evidence, UI compatibility, and an explicit "
        "incomplete boundary for the rest of Phase 2."
    )

if __name__ == "__main__":
    main()
