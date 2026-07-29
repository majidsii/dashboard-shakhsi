#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "docs/superpowers/specs/"
    "2026-07-29-linux-systemd-user-unit-store-design.md"
)

if not path.exists():
    print(f"ERROR: missing Task 10.2 design spec: {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")
required = [
    "# Linux systemd User Unit Store — Design",
    "## Platform scope",
    "## Resolved configuration path",
    "### LinuxSystemdFileSystem",
    "### LinuxSystemdUserUnitStore",
    "## Installation transaction",
    "## Rollback semantics",
    "## Removal semantics",
    "## Crash boundary",
    "## Test strategy",
    "## Acceptance criteria",
    "Android, iOS, macOS, and Windows production behavior is unchanged",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.2 design spec is incomplete: {missing}")
    sys.exit(1)

for placeholder in ("TBD", "TODO", "<placeholder>"):
    if placeholder in text:
        print(f"ERROR: unresolved placeholder found: {placeholder}")
        sys.exit(1)

print("OK: Task 10.2 Linux systemd user-unit store design spec is complete.")
