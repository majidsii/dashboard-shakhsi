#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


TEST_PATH = Path(
    "test/core/notifications/"
    "linux_systemd_notification_scheduler_final_checkpoint_test.dart"
)
CHECKPOINT_PATH = Path(
    "docs/superpowers/checkpoints/"
    "2026-07-30-linux-systemd-notification-scheduler-checkpoint.md"
)
DESIGN_PATH = Path(
    "docs/superpowers/specs/"
    "2026-07-29-linux-systemd-notification-pipeline-design.md"
)
PREPARE_PATH = Path("tool/prepare_phase1_task10_5_checkpoint.py")

GATE_SUBJECT_GROUPS = (
    ("feat: define retained systemd unit transactions",),
    ("feat: retain Linux unit install rollback state",),
    ("feat: retain Linux unit removal snapshots",),
    ("feat: define Linux scheduler contracts",),
    ("feat: schedule Linux systemd notifications",),
    ("feat: rollback failed Linux schedules",),
    ("feat: cancel Linux systemd notifications",),
    (
        "feat: serialize Linux scheduler owner operations",
        "feat: serialize Linux scheduler mutations",
    ),
    ("feat: recover Linux notification inventory",),
    ("feat: reconcile Linux notification schedules",),
)


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    sys.exit(1)


for label, path in (
    ("final checkpoint test", TEST_PATH),
    ("checkpoint evidence", CHECKPOINT_PATH),
    ("shared design", DESIGN_PATH),
    ("checkpoint preparation tool", PREPARE_PATH),
):
    if not path.is_file():
        fail(f"missing {label}: {path}")

test = TEST_PATH.read_text(encoding="utf-8")
checkpoint = CHECKPOINT_PATH.read_text(encoding="utf-8")
design = DESIGN_PATH.read_text(encoding="utf-8")
prepare = PREPARE_PATH.read_text(encoding="utf-8")

required_test_tokens = (
    "completes the full fake lifecycle and reports partial repair",
    "composes production store renderer and driver without real systemd",
    "await harness.scheduler.schedule(original)",
    "await harness.scheduler.schedule(changed)",
    "await harness.scheduler.schedule(due)",
    "await harness.scheduler.cancel(cancelRequest.scheduleId)",
    "await harness.scheduler.cancelByOwner(ownerA)",
    "await harness.scheduler.reconcile(",
    "harness.registry.corruptNextLoad()",
    "LinuxSystemdNotificationSchedulerFailure.partialReconciliation",
    "throwsUnsupportedError",
    "LinuxSystemdUserUnitStore(",
    "FakeLinuxSystemdFileSystem()",
    "LinuxSystemdUnitRenderer()",
    "LinuxSystemdUserDriver(processRunner: runner)",
)
missing_test = [token for token in required_test_tokens if token not in test]
if missing_test:
    fail(f"final lifecycle coverage is incomplete: {missing_test}")

for forbidden in (
    "Process.start",
    "Process.run",
    "Directory.systemTemp",
    "systemctl --user",
    "Future.delayed(",
    "TODO",
    "FIXME",
    "UnimplementedError",
):
    if forbidden in test:
        fail(f"final checkpoint test contains forbidden behavior: {forbidden}")

required_checkpoint = (
    "Status: **Implemented and freshly verified**",
    "Task 10.5 focused tests: **",
    "Full project tests: **",
    "`flutter analyze`: **No issues found**",
    "`flutter build linux --debug`: **Succeeded**",
    "`git diff --check`: **Clean**",
    "Task 10.6 — Delivery Entrypoint and Platform Wiring — is still **pending**",
    "Retained transaction guarantees",
    "Scheduling and locking guarantees",
    "Cancellation and rollback guarantees",
    "Reconciliation guarantees",
)
missing_checkpoint = [
    token for token in required_checkpoint
    if token not in checkpoint
]
if missing_checkpoint:
    fail(f"checkpoint evidence is incomplete: {missing_checkpoint}")

hashes = re.findall(r"\| 10\.5\.\d+ \| `([0-9a-f]{40})` \|", checkpoint)
if len(hashes) != 10 or len(set(hashes)) != 10:
    fail(
        "checkpoint must contain 10 distinct exact 40-character Gate hashes"
    )

focused_match = re.search(
    r"Task 10\.5 focused tests: \*\*(\d+) passed\*\*",
    checkpoint,
)
full_match = re.search(
    r"Full project tests: \*\*(\d+) passed\*\*",
    checkpoint,
)
if focused_match is None or full_match is None:
    fail("checkpoint test counts are not parseable")

focused_count = int(focused_match.group(1))
full_count = int(full_match.group(1))
if focused_count < 2:
    fail("focused test count is unexpectedly small")
if full_count < 911:
    fail(
        f"full test count must include the two checkpoint tests; got {full_count}"
    )
if full_count < focused_count:
    fail("full test count is smaller than focused test count")

required_design = (
    "Status: Approved architecture; Tasks 10.4 and 10.5 implemented; "
    "Task 10.6 pending",
    "- Task 10.5 — Linux systemd Notification Scheduler: "
    "**Implemented**",
    "Status: **Implemented** — [checkpoint]",
    "- Task 10.6 — Delivery Entrypoint and Platform Wiring: **Pending**",
)
missing_design = [token for token in required_design if token not in design]
if missing_design:
    fail(f"shared design status is incomplete: {missing_design}")

for accepted_subjects in GATE_SUBJECT_GROUPS:
    if not any(subject in checkpoint for subject in accepted_subjects):
        fail(
            "checkpoint is missing an accepted Gate subject: "
            f"{accepted_subjects}"
        )

required_prepare = (
    "git diff",
    "--check",
    "No issues found!",
    "Built build/linux/x64/debug/bundle/dashboard_shakhsi",
    "_gate_hashes()",
    "_update_design(",
)
missing_prepare = [token for token in required_prepare if token not in prepare]
if missing_prepare:
    fail(f"checkpoint preparation tool is incomplete: {missing_prepare}")

diff_check = subprocess.run(
    ("git", "diff", "--check"),
    check=False,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)
if diff_check.returncode != 0:
    fail(f"git diff --check failed:\n{diff_check.stdout.rstrip()}")

print(
    "OK: Task 10.5 is checkpointed with two final lifecycle tests, production "
    "adapter composition without real systemd, 10 distinct Gate hashes, "
    f"{focused_count} focused and {full_count} full passing tests, clean "
    "analyze/build/diff evidence, implemented design status, retained "
    "transaction and locking guarantees, rollback/cancellation and "
    "reconciliation guarantees, and Task 10.6 explicitly pending."
)
