#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CHECKPOINT = (
    ROOT
    / "docs/superpowers/checkpoints/"
    "2026-08-07-task-2-8-quick-entry-templates-checkpoint.md"
)
SPEC = ROOT / "docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md"
EXPECTED_COMMIT = "0972d8feba1566c0a876d8d5e3969f95281e2e6e"
EXPECTED_FOCUSED = "57"
EXPECTED_FULL = "1245"


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
need(
    f"Task 2.8 focused tests: **{EXPECTED_FOCUSED} passed**" in checkpoint,
    "focused test evidence changed",
)
need(
    f"Full project tests: **{EXPECTED_FULL} passed**" in checkpoint,
    "full test evidence changed",
)
need("schema version 8" in checkpoint.lower(), "schema-8 checkpoint evidence missing")
need(
    "seven app-owned system templates" in checkpoint.lower(),
    "seven system-template checkpoint evidence missing",
)
need(
    "8. **Task 2.8 — Quick-Entry Templates** — **Implemented** "
    "([checkpoint](../checkpoints/"
    "2026-08-07-task-2-8-quick-entry-templates-checkpoint.md))"
    in spec,
    "Phase 2 design does not mark Task 2.8 implemented",
)

ancestor = subprocess.run(
    ("git", "merge-base", "--is-ancestor", EXPECTED_COMMIT, "HEAD"),
    cwd=ROOT,
    check=False,
)
need(
    ancestor.returncode == 0,
    "recorded Task 2.8 implementation commit is not an ancestor of HEAD",
)

subject = subprocess.run(
    ("git", "show", "-s", "--format=%s", EXPECTED_COMMIT),
    cwd=ROOT,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
need(subject.returncode == 0, f"cannot read implementation commit:\n{subject.stdout}")
need(
    subject.stdout.strip() == "feat: add quick-entry task templates",
    "implementation commit subject changed",
)

run_verifier("tool/verify_phase2_task2_7_complete.py")
run_verifier("tool/verify_phase2_task2_8_green.py")

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
    "OK: Task 2.8 checkpoint is linked to exact implementation commit "
    f"{EXPECTED_COMMIT}, {EXPECTED_FOCUSED} focused and {EXPECTED_FULL} full "
    "passing tests, clean analyze/build/diff evidence, schema-8 migration and "
    "restart proof, seven stable app-owned built-ins, system/custom lifecycle "
    "rules, idempotent catalog sync, fresh Task Details draft mapping, "
    "relative recurrence-end defaults, template picker/manager/editor and "
    "save-as-template integration, and stable Task 2.7 verification."
)
