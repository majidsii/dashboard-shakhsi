#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

CHECKPOINT = Path("docs/superpowers/checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md")
PLAN = Path("docs/superpowers/plans/2026-08-02-task-2-1-status-ordering-foundation.md")
DESIGN = Path("docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md")
PREPARE = Path("tool/prepare_phase2_task2_1_checkpoint.py")

GATES = (
    ("2.1.1", "feat: add task status storage contract"),
    ("2.1.2", "feat: add task status and ordering fields"),
    ("2.1.3", "feat: migrate tasks to status ordering schema"),
    ("2.1.4", "feat: persist stable task display numbers"),
    ("2.1.5", "feat: add atomic task status transitions"),
    ("2.1.6", "feat: preserve task panel on status model"),
)

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

def fail(message: str) -> None:
    print(f"ERROR: {message}")
    sys.exit(1)

for label, path in (
    ("checkpoint", CHECKPOINT),
    ("plan", PLAN),
    ("design", DESIGN),
    ("preparer", PREPARE),
):
    if not path.is_file():
        fail(f"missing Task 2.1 {label}: {path}")

for path in TESTS:
    if not path.is_file():
        fail(f"missing focused test: {path}")

checkpoint = CHECKPOINT.read_text(encoding="utf-8")
plan = PLAN.read_text(encoding="utf-8")
design = DESIGN.read_text(encoding="utf-8")
prepare = PREPARE.read_text(encoding="utf-8")
tests = "\n".join(p.read_text(encoding="utf-8", errors="replace") for p in TESTS)

required_checkpoint = (
    "Status: **Implemented and freshly verified**",
    "Task 2.1 — Task Status, Display Number, and Per-Status Position: **Complete**",
    "Remaining Phase 2 tasks (2.2–2.11): **Not assessed and not marked complete**",
    "Phase 2 overall: **Not complete**",
    "Task 2.1 focused tests: **",
    "Full project tests: **",
    "`flutter analyze`: **No issues found**",
    "`flutter build linux --debug`: **Succeeded**",
    "`git diff --check`: **Clean**",
    "schema version 2 to schema version 3",
    "Restart from the migrated database file preserves",
    "Status/timestamp invariants",
    "Stable display-number evidence",
    "Independent per-status ordering",
    "Existing Tasks panel compatibility",
)
missing = [x for x in required_checkpoint if x not in checkpoint]
if missing:
    fail(f"incomplete checkpoint: {missing}")

rows = re.findall(
    r"\| (2\.1\.[1-6]) \| `([0-9a-f]{40})` \| `([^`]+)` \|",
    checkpoint,
)
if [(g, s) for g, _, s in rows] != list(GATES):
    fail(f"unexpected Gate table: {rows}")
hashes = [h for _, h, _ in rows]
if len(set(hashes)) != 6:
    fail("Gate hashes must be six distinct commits")
for commit_hash in hashes:
    result = subprocess.run(
        ("git", "merge-base", "--is-ancestor", commit_hash, "HEAD"),
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode:
        fail(f"Gate commit is not an ancestor of HEAD: {commit_hash}")

focused = re.search(r"Task 2\.1 focused tests: \*\*(\d+) passed\*\*", checkpoint)
full = re.search(r"Full project tests: \*\*(\d+) passed\*\*", checkpoint)
if focused is None or full is None:
    fail("test counts are not parseable")
focused_count, full_count = int(focused.group(1)), int(full.group(1))
if focused_count < 54 or full_count < 1029 or full_count < focused_count:
    fail(f"unexpected test counts: focused={focused_count}, full={full_count}")

relative = "../checkpoints/2026-08-02-task-2-1-status-ordering-checkpoint.md"
required_plan = (
    "Status: **Implemented and freshly verified**",
    f"Checkpoint: [Task 2.1 status and ordering evidence]({relative})",
    "- [x] **Step 1: Run focused cross-gate suite**",
    "- [x] **Step 2: Run fresh project verification**",
    "- [x] **Step 3: Generate checkpoint**",
    "- [x] **Step 4: Verify checkpoint**",
    "- [x] **Step 5: Commit and push**",
)
missing = [x for x in required_plan if x not in plan]
if missing:
    fail(f"incomplete plan status: {missing}")

required_design = (
    "Status: Approved for implementation; Tasks 2.1–2.4 implemented",
    "## Implementation status",
    f"Task 2.1 — Task Status, Display Number, and Per-Status Position: **Implemented** ([checkpoint]({relative}))",
    "Tasks 2.5–2.11: **Pending**",
    "Phase 2 overall: **In progress**",
    f"Task 2.1 status: **Implemented** — [checkpoint]({relative})",
)
missing = [x for x in required_design if x not in design]
if missing:
    fail(f"incomplete design status: {missing}")

combined_status_text = "\n".join((checkpoint, plan, design))

for forbidden_pattern in (
    r"(?m)^Phase 2 overall: \*\*Complete\*\*$",
    r"(?m)^All Phase 2 work: \*\*Complete\*\*$",
    r"(?m)^Phase 2: \*\*Complete\*\*$",
):
    if re.search(forbidden_pattern, combined_status_text):
        fail(
            "overbroad completion assertion matched: "
            f"{forbidden_pattern}"
        )

required_test_tokens = (
    "TaskStatus.planned",
    "TaskStatus.completed",
    "displayNumber",
    "positionInStatus",
    "reorderWithinStatus",
    "taskRepositoryProvider",
)
missing = [x for x in required_test_tokens if x not in tests]
if missing:
    fail(f"focused test evidence incomplete: {missing}")

required_prepare = (
    "_gate_hashes",
    "_update_plan",
    "_update_design",
    "No issues found!",
    "Built build/linux/x64/debug/bundle/dashboard_shakhsi",
    "focused_count < 54",
    "full_count < 1029",
)
missing = [x for x in required_prepare if x not in prepare]
if missing:
    fail(f"preparer is incomplete: {missing}")

result = subprocess.run(
    ("git", "diff", "--check"),
    check=False,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)
if result.returncode:
    fail(f"git diff --check failed:\n{result.stdout.rstrip()}")

print(
    "OK: Task 2.1 checkpoint contains six exact Gate hashes, "
    f"{focused_count} focused and {full_count} full passing tests, "
    "clean analyze/build/diff evidence, migration/restart proof, "
    "status/timestamp and display-number invariants, independent ordering, "
    "current Tasks panel compatibility, and an explicit incomplete boundary "
    "for the remainder of Phase 2."
)
