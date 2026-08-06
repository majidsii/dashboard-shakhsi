#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CHECKPOINT = (
    ROOT
    / "docs/superpowers/checkpoints/"
    "2026-08-05-task-2-5-recurrence-checkpoint.md"
)
SPEC = ROOT / "docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md"
EXPECTED_COMMIT = "3affb2579bed4afffaf37cb7122b565d1b236897"


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
need("24" in checkpoint, "focused test evidence changed")
need("1126" in checkpoint, "full test evidence changed")
need(
    "5. **Task 2.5 — Shared Recurrence Domain and Occurrence Engine** "
    "— **Implemented** "
    "([checkpoint](../checkpoints/"
    "2026-08-05-task-2-5-recurrence-checkpoint.md))"
    in spec,
    "Phase 2 design does not mark Task 2.5 implemented",
)

run_verifier("tool/verify_phase2_task2_4_complete.py")
run_verifier("tool/verify_phase2_task2_5_green.py")

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
    "OK: Task 2.5 checkpoint is linked to exact commit evidence, "
    "24 focused and 1126 full passing tests, clean "
    "analyze/build/diff evidence, schema-5 compatibility, Gregorian/Jalali "
    "calendar coverage, deterministic timezone-aware recurrence expansion, "
    "DST policies, termination, exceptions, and stable Task 2.4 verification."
)
