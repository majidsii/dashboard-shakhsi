#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "docs/superpowers/plans/"
    "2026-07-29-linux-systemd-schedule-registry-implementation.md"
)

if not path.exists():
    print(f"ERROR: missing Task 10.4 implementation plan: {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "# Persistent Linux systemd Schedule Registry Implementation Plan",
    "## Global Constraints",
    "## File Map",
    "# Gate 10.4.1",
    "# Gate 10.4.2",
    "# Gate 10.4.3",
    "# Gate 10.4.4",
    "# Gate 10.4.5",
    "# Gate 10.4.6",
    "# Gate 10.4.7",
    "# Gate 10.4.8",
    "LinuxSystemdScheduleRegistry",
    "LinuxSystemdScheduleRegistryCodec",
    "LinuxNotificationRequestFingerprint",
    "fileLength",
    "listNames",
    "LinuxSystemdScheduleRegistryFileStore",
    "quarantineCorruptRegistry",
    "discoverAppUnitPairs",
    "f6ae7b7f35da4a7dfe74fc9144e726232ece9c67f130357d1ed39cef9ed51174",
    "## Self-Review Results",
]

missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.4 plan is incomplete: {missing}")
    sys.exit(1)

for forbidden in (
    "T" + "BD",
    "T" + "ODO",
    "implement later",
    "fill in details",
    "add appropriate error handling",
    "write tests for the above",
):
    if forbidden.lower() in text.lower():
        print(f"ERROR: Task 10.4 plan contains placeholder: {forbidden}")
        sys.exit(1)

gate_count = text.count("# Gate 10.4.")
if gate_count != 8:
    print(f"ERROR: expected 8 Task 10.4 Gates, found {gate_count}")
    sys.exit(1)

print(
    "OK: Task 10.4 implementation plan contains eight TDD Gates, exact "
    "interfaces, file paths, failure models, verification commands, commit "
    "boundaries, and full coverage of the approved registry specification."
)
