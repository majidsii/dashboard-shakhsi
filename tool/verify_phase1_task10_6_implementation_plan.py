#!/usr/bin/env python3
from pathlib import Path
import re
import sys

plan_path = Path(
    "docs/superpowers/plans/"
    "2026-08-02-linux-notification-delivery-entrypoint-platform-wiring-implementation.md"
)
design_path = Path(
    "docs/superpowers/specs/"
    "2026-07-29-linux-systemd-notification-pipeline-design.md"
)

if not plan_path.is_file():
    print(f"ERROR: missing Task 10.6 implementation plan: {plan_path}")
    sys.exit(1)

if not design_path.is_file():
    print(f"ERROR: missing shared design: {design_path}")
    sys.exit(1)

plan = plan_path.read_text(encoding="utf-8")
design = design_path.read_text(encoding="utf-8")

required_header = (
    "# Linux Notification Delivery Entrypoint and Platform Wiring "
    "Implementation Plan",
    "**Goal:**",
    "**Architecture:**",
    "**Tech Stack:**",
    "## Global Constraints",
    "## File Map",
    "## Plan Self-Review",
)
missing_header = [token for token in required_header if token not in plan]
if missing_header:
    print(f"ERROR: plan header/structure incomplete: {missing_header}")
    sys.exit(1)

gate_headings = re.findall(
    r"^# Gate 10\.6\.(\d+) — .+$",
    plan,
    flags=re.MULTILINE,
)
if gate_headings != [str(index) for index in range(1, 10)]:
    print(
        "ERROR: Task 10.6 must contain exactly Gates 10.6.1 through 10.6.9; "
        f"found {gate_headings}"
    )
    sys.exit(1)

required_commits = (
    "feat: add notification schedule lookup",
    "feat: parse Linux notification delivery command",
    "feat: resolve Linux notification delivery executable",
    "feat: deliver persisted Linux notifications",
    "feat: run hidden Linux notification mode",
    "feat: select Linux systemd notification scheduler",
    "feat: reconcile Linux notifications at startup",
    "test: verify Linux notification delivery composition",
    "test: checkpoint Linux notification pipeline",
)
for subject in required_commits:
    if f"**Commit:** `{subject}`" not in plan:
        print(f"ERROR: missing exact Gate commit subject: {subject}")
        sys.exit(1)

required_contracts = (
    "Future<NotificationRequest?> getById(String scheduleId);",
    "LinuxNotificationDeliveryInvocation.parse",
    "LinuxHiddenNotificationDeliveryInvocation",
    "LinuxNotificationDeliveryResult",
    "LinuxExecutablePathSource",
    "ValidatedLinuxExecutablePathSource",
    "Future<LinuxSystemdNotificationUnit> create",
    "LinuxNotificationDeliveryResourcesFactory",
    "LinuxNotificationDeliveryService",
    "ApplicationEntrypoint",
    "notificationSchedulerProvider",
    "linuxSystemdNotificationSchedulerProvider",
    "NotificationStartupBootstrap",
    "linux_notification_pipeline_integration_test.dart",
)
missing_contracts = [token for token in required_contracts if token not in plan]
if missing_contracts:
    print(f"ERROR: plan contracts incomplete: {missing_contracts}")
    sys.exit(1)

required_constraints = (
    "exactly two application arguments",
    "A missing request is a benign stale timer",
    "does not delete or mutate Drift desired state",
    "not direct `Platform.isLinux` checks",
    "No automated test invokes real `systemctl`",
    "Task 10.6 uses nine review Gates and nine commits",
)
missing_constraints = [
    token for token in required_constraints if token not in plan
]
if missing_constraints:
    print(f"ERROR: global constraints incomplete: {missing_constraints}")
    sys.exit(1)

for gate in range(1, 10):
    section_start = plan.find(f"# Gate 10.6.{gate} —")
    next_start = plan.find(f"# Gate 10.6.{gate + 1} —")
    section_end = next_start if next_start >= 0 else plan.find(
        "## Plan Self-Review",
        section_start,
    )
    section = plan[section_start:section_end]
    for token in (
        "**Files:**",
        "- [ ] **Step 1:",
        "- [ ] **Step 2:",
        "- [ ] **Step 3:",
        "- [ ] **Step 4:",
        "- [ ] **Step 5:",
    ):
        if token not in section:
            print(
                f"ERROR: Gate 10.6.{gate} is missing required plan token: "
                f"{token}"
            )
            sys.exit(1)

for forbidden in (
    "TBD",
    "TODO",
    "FIXME",
    "implement later",
    "fill in details",
    "add appropriate error handling",
    "write tests for the above",
    "similar to Task",
):
    if forbidden.lower() in plan.lower():
        print(f"ERROR: plan contains placeholder language: {forbidden}")
        sys.exit(1)

if "# Task 10.6 — Delivery Entrypoint and Platform Wiring" not in design:
    print("ERROR: shared design is missing Task 10.6.")
    sys.exit(1)

if "Task 10.6" not in design or "**Pending**" not in design:
    print("ERROR: Task 10.6 must remain pending before implementation.")
    sys.exit(1)

print(
    "OK: Task 10.6 implementation plan defines nine TDD review Gates for "
    "exact repository lookup, hidden command parsing, executable validation, "
    "persisted delivery, pre-UI hidden bootstrap, lazy platform selection, "
    "single-flight startup reconciliation, integrated fake composition, and "
    "the final cross-task checkpoint while preserving non-Linux behavior and "
    "the documented durability boundary."
)
