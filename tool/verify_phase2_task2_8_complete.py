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
ROADMAP = ROOT / "PROJECT_ROADMAP.md"

EXPECTED_COMMIT = "0972d8feba1566c0a876d8d5e3969f95281e2e6e"
EXPECTED_CHECKPOINT_COMMIT = "458499dfdb3504034d1d7115bd1515fe20ffc876"
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


def require_ancestor(commit: str, label: str) -> None:
    result = subprocess.run(
        ("git", "merge-base", "--is-ancestor", commit, "HEAD"),
        cwd=ROOT,
        check=False,
    )
    need(result.returncode == 0, f"{label} is not an ancestor of HEAD: {commit}")


need(CHECKPOINT.is_file(), f"missing checkpoint: {CHECKPOINT}")
need(SPEC.is_file(), f"missing Phase 2 design: {SPEC}")
need(ROADMAP.is_file(), f"missing Roadmap: {ROADMAP}")

checkpoint = CHECKPOINT.read_text(encoding="utf-8")
spec = SPEC.read_text(encoding="utf-8")
roadmap = ROADMAP.read_text(encoding="utf-8")

need(EXPECTED_COMMIT in checkpoint, "checkpoint implementation commit evidence changed")
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

require_ancestor(EXPECTED_COMMIT, "Task 2.8 implementation commit")
require_ancestor(EXPECTED_CHECKPOINT_COMMIT, "Task 2.8 checkpoint commit")

implementation_subject = subprocess.run(
    ("git", "show", "-s", "--format=%s", EXPECTED_COMMIT),
    cwd=ROOT,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
need(
    implementation_subject.returncode == 0,
    f"cannot read implementation commit:\n{implementation_subject.stdout}",
)
need(
    implementation_subject.stdout.strip() == "feat: add quick-entry task templates",
    "implementation commit subject changed",
)

checkpoint_subject = subprocess.run(
    ("git", "show", "-s", "--format=%s", EXPECTED_CHECKPOINT_COMMIT),
    cwd=ROOT,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
need(
    checkpoint_subject.returncode == 0,
    f"cannot read checkpoint commit:\n{checkpoint_subject.stdout}",
)
need(
    checkpoint_subject.stdout.strip() == "docs: checkpoint quick-entry task templates",
    "checkpoint commit subject changed",
)

roadmap_tokens = (
    "Current database schema: **8**",
    "Latest fully verified checkpoint commit: "
    f"`{EXPECTED_CHECKPOINT_COMMIT}`",
    "## Task 2.8 — Quick-Entry Templates",
    "**Status: IMPLEMENTED AND FRESHLY VERIFIED**",
    f"`{EXPECTED_COMMIT}`",
    f"`{EXPECTED_CHECKPOINT_COMMIT}`",
    "focused tests: **57 passed**",
    "full suite: **1245 passed**",
    "# 7. CURRENT TASK — Task 2.9 — Undo, 30-Day Trash, and Audit History",
    "**Status: PENDING — DESIGN NOT STARTED**",
    "Latest fully recorded checkpoint baseline after Task 2.8:",
    "Repository schema is **8**.",
    "`docs/superpowers/checkpoints/"
    "2026-08-07-task-2-8-quick-entry-templates-checkpoint.md`",
    "`tool/verify_phase2_task2_8_complete.py`",
    "Latest checkpoint:\n\n`docs/superpowers/checkpoints/"
    "2026-08-07-task-2-8-quick-entry-templates-checkpoint.md`",
    "Latest semantic verifier:\n\n`tool/verify_phase2_task2_8_complete.py`",
)
for token in roadmap_tokens:
    need(token in roadmap, f"Roadmap Task 2.8/2.9 marker missing: {token}")

need(
    "# 7. CURRENT TASK — Task 2.8" not in roadmap,
    "Roadmap still identifies Task 2.8 as CURRENT TASK",
)
need(
    "Task 2.8 implementation has **not started**" not in roadmap,
    "Roadmap still contains stale Task 2.8 not-started marker",
)
need(
    "Current schema version is **7**" not in roadmap,
    "Roadmap still contains stale schema-7 current marker",
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
    "OK: Task 2.8 is checkpointed against exact implementation commit "
    f"{EXPECTED_COMMIT} and checkpoint commit {EXPECTED_CHECKPOINT_COMMIT}, "
    f"with {EXPECTED_FOCUSED} focused and {EXPECTED_FULL} full passing tests, "
    "clean analyze/build/diff evidence, schema-8 migration/restart proof, "
    "seven stable built-ins, template lifecycle/mapping/UI coverage, stable "
    "Task 2.7 verification, and PROJECT_ROADMAP.md advanced to Task 2.9."
)
