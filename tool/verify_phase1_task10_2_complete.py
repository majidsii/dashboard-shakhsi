#!/usr/bin/env python3
from pathlib import Path
import re
import sys

design_path = Path(
    "docs/superpowers/specs/"
    "2026-07-29-linux-systemd-user-unit-store-design.md"
)
checkpoint_path = Path(
    "docs/superpowers/checkpoints/"
    "2026-07-29-linux-systemd-user-unit-store-checkpoint.md"
)

for path in (design_path, checkpoint_path):
    if not path.exists():
        print(f"ERROR: missing finalized Task 10.2 document: {path}")
        sys.exit(1)

design = design_path.read_text(encoding="utf-8")
checkpoint = checkpoint_path.read_text(encoding="utf-8")

if "Status: Implemented and verified" not in design:
    print("ERROR: Task 10.2 design status is not finalized.")
    sys.exit(1)

required_checkpoint = [
    "# Linux systemd User Unit Store — Verification Checkpoint",
    "## Fresh verification evidence",
    "Focused Task 10.2 tests",
    "Flutter analyze",
    "Full Flutter suite",
    "Linux debug build",
    "## Permission implementation",
    "chmodWithMode(path, mode)",
    "## Transaction guarantees",
    "## Known crash boundary",
    "## Cross-platform boundary",
    "Task 10.3",
]
missing = [
    token for token in required_checkpoint
    if token not in checkpoint
]
if missing:
    print(f"ERROR: Task 10.2 checkpoint is incomplete: {missing}")
    sys.exit(1)

focused = re.search(
    r"Focused Task 10\.2 tests \| (\d+) passed",
    checkpoint,
)
full = re.search(
    r"Full Flutter suite \| (\d+) passed",
    checkpoint,
)
if focused is None or full is None:
    print("ERROR: checkpoint has no parsed test counts.")
    sys.exit(1)

if int(focused.group(1)) < 60:
    print(
        "ERROR: focused Task 10.2 count is unexpectedly low: "
        f"{focused.group(1)}"
    )
    sys.exit(1)

if int(full.group(1)) < int(focused.group(1)):
    print(
        "ERROR: full suite count cannot be lower than focused count."
    )
    sys.exit(1)

for placeholder in (
    "TBD",
    "TODO",
    "<placeholder>",
    "REPLACE_ME",
):
    if placeholder in checkpoint or placeholder in design:
        print(f"ERROR: unresolved placeholder found: {placeholder}")
        sys.exit(1)

print(
    "OK: Task 10.2 is finalized with recorded focused tests, "
    "clean analyze, full suite, Linux build, permission details, "
    "crash boundary, and cross-platform boundary."
)
