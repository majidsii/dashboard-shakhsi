#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "docs/superpowers/specs/"
    "2026-07-29-linux-systemctl-user-command-driver-design.md"
)

if not path.exists():
    print(f"ERROR: missing Task 10.3 design spec: {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "# Linux systemctl User Command Driver — Design",
    "Status: Approved for implementation planning",
    "## Process architecture",
    "### FakeLinuxProcessRunner",
    "### RecordingLinuxProcessRunner",
    "## Timeout and cancellation",
    "SIGTERM",
    "SIGKILL",
    "## Bounded stdout and stderr",
    "256 KiB",
    "128 KiB prefix",
    "128 KiB suffix",
    "## Hardened child environment",
    "SYSTEMD_PAGERSECURE=1",
    "## Machine-readable status",
    "--property=LoadState",
    "--property=UnitFileState",
    "--property=ActiveState",
    "--property=SubState",
    "## Typed unit status",
    "## Mutating commands",
    "## Postcondition failure",
    "## Concurrency model",
    "global async read/write lock",
    "per-unit keyed async mutex",
    "writer-preferring",
    "## Error model",
    "## Test strategy",
    "## Acceptance criteria",
    "tests never invoke a real `systemctl`",
    "Android, iOS, macOS, and Windows behavior remains unchanged",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.3 design spec is incomplete: {missing}")
    sys.exit(1)

for placeholder in (
    "TBD",
    "TODO",
    "<placeholder>",
    "REPLACE_ME",
):
    if placeholder in text:
        print(f"ERROR: unresolved placeholder found: {placeholder}")
        sys.exit(1)

if text.count("```") % 2 != 0:
    print("ERROR: unbalanced Markdown code fences.")
    sys.exit(1)

print(
    "OK: Task 10.3 design spec is complete: injectable and recording "
    "process runners, bounded output, two-stage termination, typed status, "
    "postcondition verification, and deterministic locking."
)
