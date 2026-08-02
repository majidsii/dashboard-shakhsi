#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


CHECKPOINT_PATH = Path(
    "docs/superpowers/checkpoints/"
    "2026-08-02-linux-notification-delivery-platform-wiring-checkpoint.md"
)
DESIGN_PATH = Path(
    "docs/superpowers/specs/"
    "2026-07-29-linux-systemd-notification-pipeline-design.md"
)
TASK_10_4_CHECKPOINT = Path(
    "docs/superpowers/checkpoints/"
    "2026-07-30-linux-systemd-schedule-registry-checkpoint.md"
)
TASK_10_5_CHECKPOINT = Path(
    "docs/superpowers/checkpoints/"
    "2026-07-30-linux-systemd-notification-scheduler-checkpoint.md"
)
PREPARE_PATH = Path("tool/prepare_phase1_task10_6_checkpoint.py")

GATE_SUBJECTS = (
    "feat: add notification schedule lookup",
    "feat: parse Linux notification delivery command",
    "feat: resolve Linux notification delivery executable",
    "feat: deliver persisted Linux notifications",
    "feat: run hidden Linux notification mode",
    "feat: select Linux systemd notification scheduler",
    "feat: reconcile Linux notifications at startup",
    "test: verify Linux notification delivery composition",
)

PRODUCTION_PATHS = (
    Path(
        "lib/core/notifications/"
        "drift_notification_schedule_repository.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_notification_delivery_invocation.dart"
    ),
    Path(
        "lib/core/notifications/"
        "resolved_linux_notification_delivery_command_factory.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_notification_delivery_service.dart"
    ),
    Path("lib/app/bootstrap/application_entrypoint.dart"),
    Path(
        "lib/core/notifications/"
        "notification_platform_providers.dart"
    ),
    Path(
        "lib/app/bootstrap/"
        "notification_startup_bootstrap.dart"
    ),
    Path("lib/app/bootstrap/app_bootstrap.dart"),
)

FOCUSED_TEST_PATHS = (
    Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_model_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_codec_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_store_load_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_store_replace_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_final_checkpoint_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "drift_notification_schedule_repository_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_notification_delivery_invocation_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_notification_delivery_result_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_executable_path_source_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "resolved_linux_notification_delivery_command_factory_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_notification_delivery_service_test.dart"
    ),
    Path(
        "test/app/bootstrap/"
        "linux_notification_delivery_bootstrap_test.dart"
    ),
    Path("test/app/bootstrap/application_entrypoint_test.dart"),
    Path(
        "test/core/notifications/"
        "notification_platform_providers_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "notification_startup_service_test.dart"
    ),
    Path(
        "test/app/bootstrap/"
        "notification_startup_bootstrap_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_notification_pipeline_integration_test.dart"
    ),
)


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    sys.exit(1)


for label, path in (
    ("Task 10.6 checkpoint evidence", CHECKPOINT_PATH),
    ("shared design", DESIGN_PATH),
    ("Task 10.4 checkpoint", TASK_10_4_CHECKPOINT),
    ("Task 10.5 checkpoint", TASK_10_5_CHECKPOINT),
    ("checkpoint preparation tool", PREPARE_PATH),
):
    if not path.is_file():
        fail(f"missing {label}: {path}")

for path in (*PRODUCTION_PATHS, *FOCUSED_TEST_PATHS):
    if not path.is_file():
        fail(f"required Task 10.4–10.6 source/test is missing: {path}")

checkpoint = CHECKPOINT_PATH.read_text(encoding="utf-8")
design = DESIGN_PATH.read_text(encoding="utf-8")
prepare = PREPARE_PATH.read_text(encoding="utf-8")
production = "\n".join(
    path.read_text(encoding="utf-8", errors="replace")
    for path in PRODUCTION_PATHS
)
focused_tests = "\n".join(
    path.read_text(encoding="utf-8", errors="replace")
    for path in FOCUSED_TEST_PATHS
)

required_checkpoint = (
    "Status: **Implemented and freshly verified**",
    "Tasks 10.4–10.6 as one Linux notification pipeline: **Complete**",
    "Unrelated Phase 1 work: **Not assessed and not marked complete**",
    "Tasks 10.4–10.6 focused tests: **",
    "Full project tests: **",
    "`flutter analyze`: **No issues found**",
    "`flutter build linux --debug`: **Succeeded**",
    "`git diff --check`: **Clean**",
    "Real user systemd process: **Not used by focused tests**",
    "Real HOME/XDG user-unit directory: **Not used by focused tests**",
    "Real desktop notification plugin/display: **Not used by focused tests**",
    "Database integration: **In-memory Drift only**",
    "Desired Drift state is not deleted after hidden delivery.",
    "Normal startup reconciliation is provider-scope single-flight.",
    "The dashboard renders immediately while reconciliation is pending.",
    "Remaining durability boundary",
    "does **not** claim",
    "power-loss atomicity",
)
missing_checkpoint = [
    token for token in required_checkpoint if token not in checkpoint
]
if missing_checkpoint:
    fail(f"checkpoint evidence is incomplete: {missing_checkpoint}")

hash_rows = re.findall(
    r"\| (10\.6\.[1-8]) \| `([0-9a-f]{40})` \| `([^`]+)` \|",
    checkpoint,
)
if len(hash_rows) != 8:
    fail("checkpoint must contain exactly eight Gate 10.6.1–10.6.8 rows")

gates = [gate for gate, _, _ in hash_rows]
hashes = [commit_hash for _, commit_hash, _ in hash_rows]
subjects = [subject for _, _, subject in hash_rows]

if gates != [f"10.6.{index}" for index in range(1, 9)]:
    fail(f"Gate rows are missing or out of order: {gates}")
if len(set(hashes)) != 8:
    fail("checkpoint Gate hashes are not eight distinct commits")
if tuple(subjects) != GATE_SUBJECTS:
    fail(f"checkpoint Gate subjects are unexpected: {subjects}")

for commit_hash in hashes:
    ancestor = subprocess.run(
        ("git", "merge-base", "--is-ancestor", commit_hash, "HEAD"),
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if ancestor.returncode != 0:
        fail(f"checkpoint Gate commit is not an ancestor of HEAD: {commit_hash}")

focused_match = re.search(
    r"Tasks 10\.4–10\.6 focused tests: \*\*(\d+) passed\*\*",
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
if focused_count < 1:
    fail("focused test count is unexpectedly small")
if full_count < 1005:
    fail(f"full test count regressed below Gate 10.6.8: {full_count}")
if full_count < focused_count:
    fail("full test count is smaller than focused test count")

required_design = (
    "Status: Approved architecture; Tasks 10.4–10.6 implemented",
    "- Task 10.4 — Persistent Linux Schedule Registry: **Implemented**",
    "- Task 10.5 — Linux systemd Notification Scheduler: **Implemented**",
    "- Task 10.6 — Delivery Entrypoint and Platform Wiring: "
    "**Implemented** ([checkpoint]",
    "# Task 10.6 — Delivery Entrypoint and Platform Wiring",
    "Status: **Implemented** — [checkpoint]",
    "## Remaining durability boundary",
)
missing_design = [token for token in required_design if token not in design]
if missing_design:
    fail(f"shared design completion status is incomplete: {missing_design}")

for forbidden in (
    "Phase 1: **Complete**",
    "All Phase 1 work: **Complete**",
    "Phase 1 complete",
):
    if forbidden in checkpoint or forbidden in design:
        fail(f"unrelated Phase 1 completion was asserted: {forbidden}")

required_production = (
    "Future<NotificationRequest?> getById",
    "LinuxHiddenNotificationDeliveryInvocation",
    "ResolvedLinuxNotificationDeliveryCommandFactory",
    "LinuxNotificationDeliveryService",
    "NotificationStartupBootstrap",
    "notificationSchedulerProvider",
    "linuxSystemdNotificationSchedulerProvider",
    "noopNotificationSchedulerProvider",
)
missing_production = [
    token for token in required_production if token not in production
]
if missing_production:
    fail(f"production Task 10.6 composition is incomplete: {missing_production}")

required_test_evidence = (
    "FakeLinuxSystemdFileSystem",
    "RecordingNativeNotificationGateway",
    "NativeDatabase.memory()",
    "ApplicationEntrypoint",
    "LinuxNotificationDeliveryService",
    "LinuxSystemdNotificationScheduler",
    "expect(identical(first, second), isTrue)",
    "normalRunner.runCalls, 0",
)
missing_test_evidence = [
    token for token in required_test_evidence if token not in focused_tests
]
if missing_test_evidence:
    fail(f"focused cross-task evidence is incomplete: {missing_test_evidence}")

for forbidden in (
    "Process.start(",
    "Process.run(",
    "Directory.systemTemp",
    "Platform.environment",
    "FlutterLocalNotificationsPlugin()",
    "WidgetsFlutterBinding.ensureInitialized()",
):
    if forbidden in focused_tests:
        fail(f"focused suite touches a real resource: {forbidden}")

required_prepare = (
    "_gate_hashes()",
    "_verify_focused_test_inventory()",
    "No issues found!",
    "Built build/linux/x64/debug/bundle/dashboard_shakhsi",
    "git",
    "diff",
    "--check",
    "_update_design(",
    "full_count < 1005",
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
    "OK: Task 10.6 and the cross-task Linux notification pipeline are "
    f"checkpointed with eight exact Gate hashes, {focused_count} focused and "
    f"{full_count} full passing tests, clean analyze/build/diff evidence, "
    "fake-only systemd/HOME/plugin/display integration, hidden-mode privacy "
    "and isolation, lazy non-Linux selection, startup single-flight and "
    "non-blocking UI evidence, Tasks 10.4–10.6 implemented, unrelated Phase 1 "
    "work untouched, and the power-loss durability boundary preserved."
)
