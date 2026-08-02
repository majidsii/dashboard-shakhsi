#!/usr/bin/env python3
from pathlib import Path
import sys

design = Path(
    "docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md"
)
plan = Path(
    "docs/superpowers/plans/"
    "2026-08-02-task-2-1-status-ordering-foundation.md"
)

for label, path in (("design", design), ("plan", plan)):
    if not path.is_file():
        print(f"ERROR: missing Phase 2 {label}: {path}")
        sys.exit(1)

design_text = design.read_text(encoding="utf-8")
plan_text = plan.read_text(encoding="utf-8")

required_design = (
    "Status: Approved for implementation",
    "## Schema version 3",
    "planned",
    "inProgress",
    "completed",
    "canceled",
    "displayNumber",
    "positionInStatus",
    "Task 2.1 — Task Status, Display Number, and Per-Status Position",
    "Task 2.11 — Phase 2 Integrated Checkpoint",
    "Reminder architecture",
    "Shared recurrence architecture",
    "durable planning system",
    "Explicit non-goals for Task 2.1",
)
missing = [token for token in required_design if token not in design_text]
if missing:
    print(f"ERROR: Phase 2 design is incomplete: {missing}")
    sys.exit(1)

required_plan = (
    "# Task 2.1 Status and Ordering Foundation Implementation Plan",
    "Gate 2.1.1: TaskStatus domain and storage serialization",
    "Gate 2.1.2: TaskItem v2 invariants and compatibility",
    "Gate 2.1.3: Schema version 3 and deterministic migration",
    "Gate 2.1.4: Repository mapping and stable display numbers",
    "Gate 2.1.5: Atomic transition and per-status reorder",
    "Gate 2.1.6: Existing Tasks panel compatibility",
    "Gate 2.1.7: Migration, restart, and Task 2.1 checkpoint",
    "feat: add task status storage contract",
    "feat: add atomic task status transitions",
    "test: checkpoint task status ordering foundation",
)
missing = [token for token in required_plan if token not in plan_text]
if missing:
    print(f"ERROR: Task 2.1 plan is incomplete: {missing}")
    sys.exit(1)

for forbidden in ("TBD", "TODO", "implement later", "Phase 2: **Complete**"):
    if forbidden in design_text or forbidden in plan_text:
        print(f"ERROR: design/plan contains forbidden placeholder: {forbidden}")
        sys.exit(1)

print(
    "OK: Phase 2 design and the seven-Gate Task 2.1 implementation plan "
    "define status storage, v2 domain invariants, deterministic schema-3 "
    "migration, stable numbering, independent ordering, atomic transitions, "
    "current UI compatibility, reminder/recurrence boundaries, and a final "
    "checkpoint without marking the rest of Phase 2 complete."
)
