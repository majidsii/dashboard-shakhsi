#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "docs/superpowers/plans/"
    "2026-07-29-linux-systemctl-user-command-driver-implementation.md"
)

if not path.exists():
    print(f"ERROR: missing Task 10.3 implementation plan: {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "# Linux systemctl User Command Driver Implementation Plan",
    "## Global Constraints",
    "## File Map",
    "### Task 1: Immutable Process Request, Result, Cancellation, and Error Models",
    "### Task 2: Bounded Byte Capture and UTF-8 Diagnostics",
    "### Task 3: Fake and Recording Process Runners",
    "### Task 4: Dart IO Runner — Normal Completion and Concurrent Stream Draining",
    "### Task 5: Timeout, Cancellation, and Two-Stage Termination",
    "### Task 6: Validated Timer Names, Typed Status, and Strict Parser",
    "### Task 7: Writer-Preferring Read/Write Lock and FIFO Keyed Mutex",
    "### Task 8: Daemon Reload and Machine-Readable Status Driver",
    "### Task 9: Idempotent Mutations, Postconditions, Reconciliation, and Locking",
    "### Task 10: Final Structure Audit, Evidence Checkpoint, and Design Finalization",
    "Process.start",
    "runInShell: false",
    "SIGTERM",
    "SIGKILL",
    "256 KiB",
    "SYSTEMD_PAGERSECURE=1",
    "LinuxSystemdPostconditionException",
    "writer-preferring",
    "flutter build linux --debug",
    "git push",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.3 implementation plan is incomplete: {missing}")
    sys.exit(1)

for placeholder in (
    "TBD",
    "TODO",
    "implement later",
    "fill in details",
    "<placeholder>",
    "REPLACE_ME",
):
    if placeholder in text:
        print(f"ERROR: unresolved plan placeholder found: {placeholder}")
        sys.exit(1)

checkbox_count = text.count("- [ ]")
if checkbox_count < 48:
    print(
        "ERROR: Task 10.3 plan is not sufficiently granular: "
        f"{checkbox_count} checkbox steps."
    )
    sys.exit(1)

if text.count("```") % 2 != 0:
    print("ERROR: unbalanced Markdown code fences.")
    sys.exit(1)

print(
    "OK: Task 10.3 implementation plan is complete, TDD-ordered, "
    "and split into ten independently reviewable gates."
)
