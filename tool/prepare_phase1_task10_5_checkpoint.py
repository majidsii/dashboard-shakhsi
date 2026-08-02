#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
from datetime import date
from pathlib import Path


GATES: tuple[tuple[str, tuple[str, ...]], ...] = (
    (
        "10.5.1",
        ("feat: define retained systemd unit transactions",),
    ),
    (
        "10.5.2",
        ("feat: retain Linux unit install rollback state",),
    ),
    (
        "10.5.3",
        ("feat: retain Linux unit removal snapshots",),
    ),
    (
        "10.5.4",
        ("feat: define Linux scheduler contracts",),
    ),
    (
        "10.5.5",
        ("feat: schedule Linux systemd notifications",),
    ),
    (
        "10.5.6",
        ("feat: rollback failed Linux schedules",),
    ),
    (
        "10.5.7",
        ("feat: cancel Linux systemd notifications",),
    ),
    (
        "10.5.8",
        (
            "feat: serialize Linux scheduler owner operations",
            "feat: serialize Linux scheduler mutations",
        ),
    ),
    (
        "10.5.9",
        ("feat: recover Linux notification inventory",),
    ),
    (
        "10.5.10",
        ("feat: reconcile Linux notification schedules",),
    ),
)

ANSI_PATTERN = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
TEST_COUNT_PATTERN = re.compile(r"\+(\d+): All tests passed!")


def _read_success_log(path: Path, marker: str, label: str) -> str:
    if not path.is_file():
        raise SystemExit(f"ERROR: missing {label} log: {path}")

    text = ANSI_PATTERN.sub("", path.read_text(encoding="utf-8", errors="replace"))
    if marker not in text:
        raise SystemExit(
            f"ERROR: {label} log does not contain success marker: {marker}"
        )
    return text


def _test_count(path: Path, label: str) -> int:
    text = _read_success_log(path, "All tests passed!", label)
    matches = TEST_COUNT_PATTERN.findall(text)
    if not matches:
        raise SystemExit(f"ERROR: could not parse test count from {path}")
    return int(matches[-1])


def _git_output(*args: str) -> str:
    result = subprocess.run(
        ("git", *args),
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise SystemExit(
            f"ERROR: git {' '.join(args)} failed:\n{result.stderr.strip()}"
        )
    return result.stdout


def _gate_hashes() -> list[tuple[str, str, str]]:
    history = _git_output(
        "log",
        "--all",
        "--format=%H%x09%s",
    ).splitlines()
    parsed: list[tuple[str, str]] = []

    for line in history:
        commit_hash, separator, subject = line.partition("\t")
        if separator and re.fullmatch(r"[0-9a-f]{40}", commit_hash):
            parsed.append((commit_hash, subject))

    evidence: list[tuple[str, str, str]] = []
    for gate, accepted_subjects in GATES:
        match = next(
            (
                (commit_hash, subject)
                for commit_hash, subject in parsed
                if subject in accepted_subjects
            ),
            None,
        )
        if match is None:
            raise SystemExit(
                f"ERROR: no exact commit found for Gate {gate}; "
                f"accepted subjects: {accepted_subjects}"
            )
        evidence.append((gate, match[0], match[1]))

    hashes = [commit_hash for _, commit_hash, _ in evidence]
    if len(set(hashes)) != len(hashes):
        raise SystemExit("ERROR: Gate evidence reused the same commit hash.")

    return evidence


def _update_design(path: Path, checkpoint_relative: str) -> None:
    if not path.is_file():
        raise SystemExit(f"ERROR: shared design is missing: {path}")

    text = path.read_text(encoding="utf-8")

    status_old = (
        "Status: Approved architecture; Task 10.4 implemented; "
        "Tasks 10.5 and 10.6 pending"
    )
    status_new = (
        "Status: Approved architecture; Tasks 10.4 and 10.5 implemented; "
        "Task 10.6 pending"
    )
    if status_old in text:
        text = text.replace(status_old, status_new, 1)
    elif status_new not in text:
        raise SystemExit("ERROR: shared design top-level status is unexpected.")

    list_old = (
        "- Task 10.5 — Linux systemd Notification Scheduler: **Pending**"
    )
    list_new = (
        "- Task 10.5 — Linux systemd Notification Scheduler: "
        f"**Implemented** ([checkpoint]({checkpoint_relative}))"
    )
    if list_old in text:
        text = text.replace(list_old, list_new, 1)
    elif list_new not in text:
        raise SystemExit("ERROR: Task 10.5 implementation-list status is unexpected.")

    task_heading = "# Task 10.5 — Linux systemd Notification Scheduler"
    heading_index = text.find(task_heading)
    if heading_index < 0:
        raise SystemExit("ERROR: Task 10.5 design section is missing.")

    section_tail = text[heading_index:]
    section_old = "Status: **Pending**"
    section_new = f"Status: **Implemented** — [checkpoint]({checkpoint_relative})"
    if section_old in section_tail:
        section_tail = section_tail.replace(section_old, section_new, 1)
        text = text[:heading_index] + section_tail
    elif section_new not in section_tail:
        raise SystemExit("ERROR: Task 10.5 section status is unexpected.")

    path.write_text(text, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Finalize Task 10.5 checkpoint evidence after fresh verification."
    )
    parser.add_argument(
        "--focused-log",
        type=Path,
        default=Path("/tmp/task10-5-focused.log"),
    )
    parser.add_argument(
        "--full-log",
        type=Path,
        default=Path("/tmp/task10-5-full.log"),
    )
    parser.add_argument(
        "--analyze-log",
        type=Path,
        default=Path("/tmp/task10-5-analyze.log"),
    )
    parser.add_argument(
        "--build-log",
        type=Path,
        default=Path("/tmp/task10-5-build.log"),
    )
    args = parser.parse_args()

    focused_count = _test_count(args.focused_log, "focused test")
    full_count = _test_count(args.full_log, "full test")
    _read_success_log(
        args.analyze_log,
        "No issues found!",
        "flutter analyze",
    )
    _read_success_log(
        args.build_log,
        "Built build/linux/x64/debug/bundle/dashboard_shakhsi",
        "Linux debug build",
    )

    if full_count < focused_count:
        raise SystemExit(
            "ERROR: full test count is smaller than focused test count."
        )

    diff_check = subprocess.run(
        ("git", "diff", "--check"),
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if diff_check.returncode != 0:
        raise SystemExit(
            "ERROR: git diff --check failed:\n"
            f"{diff_check.stdout.rstrip()}"
        )

    evidence = _gate_hashes()
    checkpoint_path = Path(
        "docs/superpowers/checkpoints/"
        "2026-07-30-linux-systemd-notification-scheduler-checkpoint.md"
    )
    design_path = Path(
        "docs/superpowers/specs/"
        "2026-07-29-linux-systemd-notification-pipeline-design.md"
    )
    checkpoint_path.parent.mkdir(parents=True, exist_ok=True)

    table_rows = "\n".join(
        f"| {gate} | `{commit_hash}` | `{subject}` |"
        for gate, commit_hash, subject in evidence
    )

    checkpoint = f"""# Linux systemd Notification Scheduler — Task 10.5 Checkpoint

Date finalized: {date.today().isoformat()}  
Phase: 1  
Task: 10.5  
Status: **Implemented and freshly verified**

## Scope

Task 10.5 implements `LinuxSystemdNotificationScheduler` and retained
systemd unit transactions. It composes the fixed clock, immediate notification
gateway, delivery-command factory, deterministic renderer, transactional unit
store, hardened user-systemd driver, persistent registry, request fingerprint,
writer-preferring global lock, and per-schedule FIFO mutex.

Task 10.6 remains pending. This checkpoint does not add the hidden delivery
entrypoint or application provider wiring.

## Gate commit evidence

| Gate | Commit | Subject |
|---|---|---|
{table_rows}

## Fresh verification evidence

- Task 10.5 focused tests: **{focused_count} passed**
- Full project tests: **{full_count} passed**
- `flutter analyze`: **No issues found**
- `flutter build linux --debug`: **Succeeded**
- `git diff --check`: **Clean**
- Real user systemd access: **Not used by checkpoint tests**

## Retained transaction guarantees

- Install and remove operations retain exact previous unit-pair state.
- Applied but unfinalized transactions can roll back.
- Finalized transactions cannot be silently rolled back.
- Primary failures remain primary when rollback also fails.
- Wrapper methods preserve the same retained transaction semantics.

## Scheduling and locking guarantees

- Due requests clean stale platform state before immediate delivery.
- Future requests render, install, reload, enable, verify, register, and finalize.
- Healthy matching requests are idempotent.
- Changed or unhealthy requests are replaced or repaired.
- Same-schedule operations are FIFO serialized.
- Different schedule IDs can overlap under the global read lock.
- Writer-preferring owner cancellation and reconciliation exclude new readers.

## Cancellation and rollback guarantees

- Cancellation handles missing, registry-only, unit-only, and complete state.
- Owner cancellation uses exact owner matching and deterministic schedule order.
- Batch failure stops at the first failed schedule and reports immutable
  completed schedule IDs.
- Failed schedule and cancel operations restore retained files, registry
  evidence, daemon visibility, and previous enabled state when possible.

## Reconciliation guarantees

- Desired requests use last-value-wins normalization and deterministic sorting.
- Due desired items are cleaned without startup immediate delivery.
- Stale registry entries, orphan complete pairs, and partial pairs are removed.
- Corrupt registry state is quarantined and rebuilt from desired state.
- Healthy matching schedules are preserved.
- Missing, changed, and unhealthy schedules are repaired.
- Successful repairs are preserved across later batch failure.
- Partial reconciliation reports the failing schedule, immutable completed IDs,
  confirmed status when available, original cause, and rollback failures.

## Remaining work

Task 10.6 — Delivery Entrypoint and Platform Wiring — is still **pending**.
"""

    checkpoint_path.write_text(checkpoint, encoding="utf-8")

    checkpoint_relative = (
        "../checkpoints/"
        "2026-07-30-linux-systemd-notification-scheduler-checkpoint.md"
    )
    _update_design(design_path, checkpoint_relative)

    print(
        "OK: Task 10.5 checkpoint prepared with "
        f"{focused_count} focused tests, {full_count} full tests, "
        "10 exact Gate commit hashes, clean analyze/build evidence, "
        "and Task 10.6 explicitly pending."
    )


if __name__ == "__main__":
    main()
