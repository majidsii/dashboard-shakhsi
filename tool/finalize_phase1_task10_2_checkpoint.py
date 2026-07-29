#!/usr/bin/env python3
from argparse import ArgumentParser
from pathlib import Path
import re
import subprocess
import sys

CHECKPOINT_PATH = Path(
    "docs/superpowers/checkpoints/"
    "2026-07-29-linux-systemd-user-unit-store-checkpoint.md"
)
DESIGN_PATH = Path(
    "docs/superpowers/specs/"
    "2026-07-29-linux-systemd-user-unit-store-design.md"
)

def read_log(path: Path, label: str) -> str:
    if not path.exists():
        raise ValueError(f"{label} log does not exist: {path}")
    return path.read_text(encoding="utf-8", errors="replace")

def parse_test_count(text: str, label: str) -> int:
    matches = re.findall(
        r"\+(\d+):\s+All tests passed!",
        text,
    )
    if not matches:
        raise ValueError(
            f"{label} log does not contain a successful Flutter "
            "test summary."
        )
    return int(matches[-1])

def git_output(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()

parser = ArgumentParser(
    description=(
        "Validate fresh Task 10.2 verification logs, update the design "
        "status, and write the evidence checkpoint."
    )
)
parser.add_argument("--focused-log", type=Path, required=True)
parser.add_argument("--analyze-log", type=Path, required=True)
parser.add_argument("--full-log", type=Path, required=True)
parser.add_argument("--build-log", type=Path, required=True)
args = parser.parse_args()

try:
    focused_text = read_log(args.focused_log, "focused test")
    analyze_text = read_log(args.analyze_log, "analyze")
    full_text = read_log(args.full_log, "full test")
    build_text = read_log(args.build_log, "Linux build")

    focused_count = parse_test_count(
        focused_text,
        "focused test",
    )
    full_count = parse_test_count(full_text, "full test")

    if "No issues found!" not in analyze_text:
        raise ValueError(
            "analyze log does not contain 'No issues found!'."
        )

    build_markers = (
        "Built build/linux/x64/debug/bundle/",
        "Built build/linux/",
    )
    if not any(marker in build_text for marker in build_markers):
        raise ValueError(
            "Linux build log does not contain a successful bundle marker."
        )

    if not DESIGN_PATH.exists():
        raise ValueError(f"design document is missing: {DESIGN_PATH}")

    design = DESIGN_PATH.read_text(encoding="utf-8")
    status_pattern = re.compile(r"(?m)^Status:\s*.+$")
    if not status_pattern.search(design):
        raise ValueError("design document has no Status line.")

    updated_design = status_pattern.sub(
        "Status: Implemented and verified",
        design,
        count=1,
    )
    DESIGN_PATH.write_text(updated_design, encoding="utf-8")

    head = git_output("rev-parse", "--short=12", "HEAD")
    branch = git_output("branch", "--show-current")

    checkpoint = f"""# Linux systemd User Unit Store — Verification Checkpoint

Date: 2026-07-29  
Phase: 1  
Task: 10.2  
Branch: `{branch}`  
Implementation HEAD before checkpoint commit: `{head}`

## Verified scope

- injected environment source
- XDG-first and HOME-fallback path resolution
- link-aware filesystem contract
- Dart IO adapter using POSIX FFI for chmod
- exact `0644` unit permissions
- safe two-file preparation and replacement
- complete in-process rollback for full and partial previous pairs
- original-cause preservation with rollback failure aggregation
- idempotent and symlink-safe removal
- no `systemctl` invocation
- no scheduler/platform integration in this Task
- no real user systemd directory touched by focused tests

## Fresh verification evidence

| Gate | Result |
|---|---:|
| Focused Task 10.2 tests | {focused_count} passed |
| Flutter analyze | No issues found |
| Full Flutter suite | {full_count} passed |
| Linux debug build | Successful |
| `git diff --check` | Run separately before commit |

## Permission implementation

The Dart IO adapter applies permissions through
`package:posix` and `chmodWithMode(path, mode)`. It does not invoke a shell,
`Process.run`, or `systemctl`.

The final service and timer mode is decimal `420`, equivalent to octal `0644`.

## Transaction guarantees

The install transaction:

1. validates final and transaction-owned paths without following symlinks
2. snapshots previous bytes and POSIX modes
3. writes and chmods both temporary units
4. backs up existing service and timer files
5. installs both prepared files through same-directory rename
6. removes backups after successful commit
7. restores the exact previous complete or partial pair after an observed failure
8. keeps the original error primary and appends rollback failures

## Known crash boundary

Task 10.2 guarantees rollback for failures observed by the running process.

A power loss, kernel crash, or forced process termination between filesystem
operations is not recovered through a persistent journal. Persistent
crash-recovery journaling remains deferred to a later hardening task.

## Cross-platform boundary

This Task adds Linux storage primitives only. It does not wire the store into
the scheduler and does not change Android, iOS, macOS, or Windows behavior.

## Next task

Task 10.3 — `systemctl --user` command driver.
"""

    CHECKPOINT_PATH.parent.mkdir(parents=True, exist_ok=True)
    CHECKPOINT_PATH.write_text(checkpoint, encoding="utf-8")

except (ValueError, subprocess.CalledProcessError) as error:
    print(f"ERROR: {error}")
    sys.exit(1)

print(
    "OK: fresh verification evidence accepted; design status updated "
    f"and checkpoint written to {CHECKPOINT_PATH}."
)
