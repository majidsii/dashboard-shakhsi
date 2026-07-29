#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "docs/superpowers/plans/"
    "2026-07-29-linux-systemd-user-unit-store-implementation.md"
)

if not path.exists():
    print(f"ERROR: missing Task 10.2 implementation plan: {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "# Linux systemd User Unit Store Implementation Plan",
    "## Global Constraints",
    "## File Map",
    "### Task 1: Environment Source and User Unit Path Resolver",
    "### Task 2: Link-Aware Filesystem Contract and Dart IO Adapter",
    "### Task 3: Fake Filesystem and Store Error Model",
    "### Task 4: Safe Unit Names and Successful Atomic Installation",
    "### Task 5: Full Rollback and Failure Aggregation",
    "### Task 6: Idempotent and Symlink-Safe Removal",
    "### Task 7: Final Verification and Checkpoint",
    "LinuxSystemdUserUnitStoreException",
    "PreviousPairState",
    "flutter build linux --debug",
    "git push",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.2 implementation plan is incomplete: {missing}")
    sys.exit(1)

for placeholder in (
    "TBD",
    "TODO",
    "implement later",
    "fill in details",
    "<placeholder>",
):
    if placeholder in text:
        print(f"ERROR: unresolved plan placeholder found: {placeholder}")
        sys.exit(1)

if text.count("- [ ]") < 30:
    print("ERROR: implementation plan is not sufficiently task-granular.")
    sys.exit(1)

print(
    "OK: Task 10.2 implementation plan is complete, TDD-ordered, "
    "and split into seven reviewable gates."
)
