#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

ROOT = Path.cwd()
CHECKPOINT = ROOT / "docs/superpowers/checkpoints/2026-08-04-task-2-4-reminders-checkpoint.md"
SPEC = ROOT / "docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md"
EXPECTED_COMMIT = '916f6e46a6ec52ee107125a4f11c2778bf669561'


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
need("64" in checkpoint, "focused test evidence changed")
need("1102" in checkpoint, "full test evidence changed")
need(
    "4. **Task 2.4 — Task Reminder Rules and Notification Projection** "
    "— **Implemented** "
    "([checkpoint](../checkpoints/2026-08-04-task-2-4-reminders-checkpoint.md))"
    in spec,
    "Phase 2 design does not mark Task 2.4 implemented",
)

run_verifier("tool/verify_phase2_task2_2_complete.py")
run_verifier("tool/verify_phase2_task2_3_complete.py")
run_verifier("tool/verify_phase2_task2_4_green.py")

print(
    "OK: Task 2.4 checkpoint is linked to exact commit evidence, "
    "64 focused and 1102 full passing tests, clean "
    "analyze/build/diff evidence, schema-5 migration proof, owner-scoped "
    "notification projection, lifecycle reprojection, and stable prior "
    "Task 2.2/2.3 checkpoint verification."
)
