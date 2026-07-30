#!/usr/bin/env python3
from pathlib import Path
import re
import sys

plan_path = Path(
    "docs/superpowers/plans/"
    "2026-07-30-linux-systemd-notification-scheduler-implementation.md"
)

if not plan_path.exists():
    print(f"ERROR: missing Task 10.5 implementation plan: {plan_path}")
    sys.exit(1)

text = plan_path.read_text(encoding="utf-8")

required_header = [
    "# Linux systemd Notification Scheduler Implementation Plan",
    "> **For agentic workers:** REQUIRED SUB-SKILL:",
    "**Goal:**",
    "**Architecture:**",
    "**Tech Stack:**",
    "## Global Constraints",
    "## File Map",
    "## Required Commit Sequence",
    "## Final Acceptance Checklist",
]
required_gates = [
    "Gate 10.5.1 — Retained Unit Transaction Contracts",
    "Gate 10.5.2 — Retained Install Transaction",
    "Gate 10.5.3 — Retained Remove Transaction",
    "Gate 10.5.4 — Delivery Factory and Scheduler Error Model",
    "Gate 10.5.5 — Immediate and Future Schedule Flow",
    "Gate 10.5.6 — Schedule Rollback and Cancellation Preservation",
    "Gate 10.5.7 — Cancel Flow and Cancel Rollback",
    "Gate 10.5.8 — Scheduler Locks and Owner Cancellation",
    "Gate 10.5.9 — Reconciliation Normalization and Inventory Recovery",
    "Gate 10.5.10 — Reconciliation Repair and Partial Reporting",
    "Gate 10.5.11 — Final Task 10.5 Checkpoint",
]
required_contracts = [
    "abstract interface class LinuxSystemdUnitStore",
    "abstract interface class LinuxSystemdUnitInstallTransaction",
    "abstract interface class LinuxSystemdUnitRemoveTransaction",
    "abstract interface class LinuxNotificationDeliveryCommandFactory",
    "final class LinuxSystemdNotificationScheduler",
    "implements NotificationScheduler",
    "LinuxSystemdNotificationSchedulerException",
    "AsyncWriterPreferringRwLock",
    "AsyncFifoKeyedMutex<String>",
]
required_behavior = [
    "Monotonic logical registry restoration",
    "Cancellation rule",
    "Due flow:",
    "Future flow order:",
    "Rollback sequence after unit apply begins:",
    "Cancel order:",
    "Corrupt recovery:",
    "Repair classification per desired request:",
    "last value winning",
    "No cross-resource",
]
required_commands = [
    "flutter analyze",
    'script -qefc "flutter --color test"',
    "flutter build linux --debug",
    "git diff --check",
    "git commit -m",
]

for label, tokens in (
    ("header", required_header),
    ("Gates", required_gates),
    ("contracts", required_contracts),
    ("behavior", required_behavior),
    ("verification commands", required_commands),
):
    missing = [token for token in tokens if token not in text]
    if missing:
        print(f"ERROR: Task 10.5 plan missing {label}: {missing}")
        sys.exit(1)

gate_numbers = re.findall(r"^# Gate 10\.5\.(\d+) —", text, re.MULTILINE)
if gate_numbers != [str(value) for value in range(1, 12)]:
    print(f"ERROR: Gate sequence is not exactly 1..11: {gate_numbers}")
    sys.exit(1)

commit_lines = re.findall(r"^\d+\. `([^`]+)`$", text, re.MULTILINE)
if len(commit_lines) != 11:
    print(
        "ERROR: Task 10.5 plan must contain exactly 11 ordered commit "
        f"subjects; found {len(commit_lines)}"
    )
    sys.exit(1)

for forbidden in (
    "TBD",
    "TODO",
    "fill in details",
    "implement later",
    "Add appropriate error handling",
    "Write tests for the above",
    "Similar to Task",
):
    if forbidden.lower() in text.lower():
        print(f"ERROR: plan contains placeholder language: {forbidden}")
        sys.exit(1)

if text.count("Follow RED") != 1:
    print("ERROR: global RED/GREEN workflow must be declared exactly once.")
    sys.exit(1)

print(
    "OK: Task 10.5 implementation plan defines eleven ordered TDD Gates, "
    "retained unit transactions, scheduler contracts, immediate/future flow, "
    "typed rollback and cancellation preservation, cancel/owner locking, "
    "deterministic corruption recovery and reconciliation, final checkpoint, "
    "eleven commits, and complete verification commands without placeholders."
)
