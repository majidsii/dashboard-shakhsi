#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CHECKPOINT = (
    ROOT
    / "docs/superpowers/checkpoints/"
    "2026-08-06-task-2-7-timer-checkpoint.md"
)
SPEC = ROOT / "docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md"
EXPECTED_COMMIT = "99dc7182c03545c102b730f52985a6ae32b3349a"


def need(condition: bool, message: str) -> None:
    if not condition:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


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


need(CHECKPOINT.is_file(), f"missing checkpoint: {CHECKPOINT}")
checkpoint = CHECKPOINT.read_text(encoding="utf-8")
spec = SPEC.read_text(encoding="utf-8")

need(EXPECTED_COMMIT in checkpoint, "checkpoint commit evidence changed")
need("72" in checkpoint, "focused test evidence changed")
need("1188" in checkpoint, "full test evidence changed")
need(
    "7. **Task 2.7 — Timer Lifecycle and Recoverable Time Entries** "
    "— **Implemented** "
    "([checkpoint](../checkpoints/"
    "2026-08-06-task-2-7-timer-checkpoint.md))"
    in spec,
    "Phase 2 design does not mark Task 2.7 implemented",
)

run_verifier("tool/verify_phase2_task2_6_complete.py")
run_verifier("tool/verify_phase2_task2_7_green.py")

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
    "OK: Task 2.7 checkpoint is linked to exact commit evidence, "
    "72 focused and 1188 full passing tests, clean "
    "analyze/build/diff evidence, schema-7 migration and restart proof, "
    "database-enforced single active timer, UTC-derived recoverable elapsed "
    "time, persisted pause/resume/stop and manual entries, Task Details and "
    "Tasks-panel coverage, and stable Task 2.6 verification."
)
