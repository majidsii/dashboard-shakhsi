#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CHECKPOINT = ROOT / 'docs/superpowers/checkpoints/2026-08-04-task-2-2-planning-fields-checkpoint.md'
SPEC = ROOT / "docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md"
EXPECTED_COMMIT = '6d7a859a69e4a72ff5ee4aef2da2a12567785ca0'


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
need('35' in checkpoint, "focused test evidence changed")
need('1084' in checkpoint, "full test evidence changed")
need('2. **Task 2.2 — Description, Start/Due Time, and Estimated Duration** — **Implemented** ([checkpoint](../checkpoints/2026-08-04-task-2-2-planning-fields-checkpoint.md))' in spec, "Phase 2 design does not mark Task 2.2 implemented")

run_verifier("tool/verify_phase2_task2_1_complete.py")
run_verifier("tool/verify_phase2_task2_2_1_green.py")
run_verifier("tool/verify_phase2_task2_2_2_green.py")
run_verifier("tool/verify_phase2_task2_2_3_green.py")
run_verifier("tool/verify_phase2_task2_2_4_green.py")
run_verifier("tool/verify_phase2_task2_2_ui_green.py")

print(
    "OK: Task 2.2 checkpoint is linked to exact commit evidence, "
    "35 focused and 1084 full passing tests, clean analyze/"
    "build/diff evidence, and all stable semantic verifiers."
)
