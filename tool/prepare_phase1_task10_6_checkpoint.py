#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
from datetime import date
from pathlib import Path


GATES: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("10.6.1", ("feat: add notification schedule lookup",)),
    ("10.6.2", ("feat: parse Linux notification delivery command",)),
    ("10.6.3", ("feat: resolve Linux notification delivery executable",)),
    ("10.6.4", ("feat: deliver persisted Linux notifications",)),
    ("10.6.5", ("feat: run hidden Linux notification mode",)),
    ("10.6.6", ("feat: select Linux systemd notification scheduler",)),
    ("10.6.7", ("feat: reconcile Linux notifications at startup",)),
    ("10.6.8", ("test: verify Linux notification delivery composition",)),
)

ANSI_PATTERN = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
TEST_COUNT_PATTERN = re.compile(r"\+(\d+): All tests passed!")

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

FOCUSED_TEST_PATHS: tuple[Path, ...] = (
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


def _read_success_log(path: Path, marker: str, label: str) -> str:
    if not path.is_file():
        raise SystemExit(f"ERROR: missing {label} log: {path}")

    text = ANSI_PATTERN.sub(
        "",
        path.read_text(encoding="utf-8", errors="replace"),
    )
    if marker not in text:
        raise SystemExit(
            f"ERROR: {label} log does not contain success marker: {marker}"
        )
    return text


def _test_count(path: Path, label: str) -> int:
    text = _read_success_log(path, "All tests passed!", label)
    matches = TEST_COUNT_PATTERN.findall(text)
    if not matches:
        raise SystemExit(f"ERROR: could not parse test count from {path}")
    return int(matches[-1])


def _git_output(*args: str) -> str:
    result = subprocess.run(
        ("git", *args),
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise SystemExit(
            f"ERROR: git {' '.join(args)} failed:\n{result.stderr.strip()}"
        )
    return result.stdout


def _gate_hashes() -> list[tuple[str, str, str]]:
    history = _git_output(
        "log",
        "--all",
        "--format=%H%x09%s",
    ).splitlines()
    parsed: list[tuple[str, str]] = []

    for line in history:
        commit_hash, separator, subject = line.partition("\t")
        if separator and re.fullmatch(r"[0-9a-f]{40}", commit_hash):
            parsed.append((commit_hash, subject))

    evidence: list[tuple[str, str, str]] = []
    for gate, accepted_subjects in GATES:
        matches = [
            (commit_hash, subject)
            for commit_hash, subject in parsed
            if subject in accepted_subjects
        ]
        if not matches:
            raise SystemExit(
                f"ERROR: no exact commit found for Gate {gate}; "
                f"accepted subjects: {accepted_subjects}"
            )

        commit_hash, subject = matches[0]
        ancestor = subprocess.run(
            ("git", "merge-base", "--is-ancestor", commit_hash, "HEAD"),
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if ancestor.returncode != 0:
            raise SystemExit(
                f"ERROR: Gate {gate} commit is not an ancestor of HEAD: "
                f"{commit_hash}"
            )

        evidence.append((gate, commit_hash, subject))

    hashes = [commit_hash for _, commit_hash, _ in evidence]
    if len(set(hashes)) != len(hashes):
        raise SystemExit("ERROR: Gate evidence reused the same commit hash.")

    return evidence


def _verify_focused_test_inventory() -> None:
    missing = [str(path) for path in FOCUSED_TEST_PATHS if not path.is_file()]
    if missing:
        raise SystemExit(
            f"ERROR: focused Task 10.4–10.6 test inventory is missing: {missing}"
        )

    combined = "\n".join(
        path.read_text(encoding="utf-8", errors="replace")
        for path in FOCUSED_TEST_PATHS
    )

    required = (
        "FakeLinuxSystemdFileSystem",
        "RecordingNativeNotificationGateway",
        "NativeDatabase.memory()",
        "NotificationStartupBootstrap",
        "ApplicationEntrypoint",
        "LinuxNotificationDeliveryService",
        "LinuxSystemdNotificationScheduler",
    )
    missing_tokens = [token for token in required if token not in combined]
    if missing_tokens:
        raise SystemExit(
            "ERROR: focused suite no longer proves the fake integrated "
            f"pipeline: {missing_tokens}"
        )

    forbidden = (
        "Process.start(",
        "Process.run(",
        "Directory.systemTemp",
        "Platform.environment",
        "FlutterLocalNotificationsPlugin()",
        "WidgetsFlutterBinding.ensureInitialized()",
    )
    found_forbidden = [token for token in forbidden if token in combined]
    if found_forbidden:
        raise SystemExit(
            "ERROR: focused checkpoint tests touch real process, HOME, plugin, "
            f"or display resources: {found_forbidden}"
        )


def _replace_one_of(
    text: str,
    old_values: tuple[str, ...],
    new_value: str,
    *,
    label: str,
) -> str:
    if new_value in text:
        return text

    for old_value in old_values:
        if old_value in text:
            return text.replace(old_value, new_value, 1)

    raise SystemExit(f"ERROR: shared design {label} is unexpected.")


def _update_design(path: Path, checkpoint_relative: str) -> None:
    if not path.is_file():
        raise SystemExit(f"ERROR: shared design is missing: {path}")

    text = path.read_text(encoding="utf-8")

    text = _replace_one_of(
        text,
        (
            "Status: Approved architecture; Tasks 10.4 and 10.5 implemented; "
            "Task 10.6 pending",
            "Status: Approved architecture; Task 10.4 implemented; "
            "Tasks 10.5 and 10.6 pending",
            "Status: Approved architecture; ready for implementation planning",
        ),
        "Status: Approved architecture; Tasks 10.4–10.6 implemented",
        label="top-level status",
    )

    implementation_heading = "## Implementation status"
    if implementation_heading not in text:
        insertion = (
            "\n## Implementation status\n\n"
            "- Task 10.4 — Persistent Linux Schedule Registry: **Implemented**\n"
            "- Task 10.5 — Linux systemd Notification Scheduler: **Implemented**\n"
            "- Task 10.6 — Delivery Entrypoint and Platform Wiring: "
            f"**Implemented** ([checkpoint]({checkpoint_relative}))\n\n"
        )
        objective_index = text.find("\n## Objective")
        if objective_index < 0:
            raise SystemExit("ERROR: shared design objective section is missing.")
        text = text[:objective_index] + insertion + text[objective_index:]

    task_list_old = (
        "- Task 10.6 — Delivery Entrypoint and Platform Wiring: **Pending**"
    )
    task_list_new = (
        "- Task 10.6 — Delivery Entrypoint and Platform Wiring: "
        f"**Implemented** ([checkpoint]({checkpoint_relative}))"
    )
    text = _replace_one_of(
        text,
        (task_list_old,),
        task_list_new,
        label="Task 10.6 implementation-list status",
    )

    task_heading = "# Task 10.6 — Delivery Entrypoint and Platform Wiring"
    heading_index = text.find(task_heading)
    if heading_index < 0:
        raise SystemExit("ERROR: Task 10.6 design section is missing.")

    section_tail = text[heading_index:]
    section_new = (
        f"Status: **Implemented** — [checkpoint]({checkpoint_relative})"
    )
    if section_new not in section_tail:
        if "Status: **Pending**" not in section_tail:
            raise SystemExit(
                "ERROR: Task 10.6 section status is unexpected."
            )
        section_tail = section_tail.replace(
            "Status: **Pending**",
            section_new,
            1,
        )
        text = text[:heading_index] + section_tail

    if "## Remaining durability boundary" not in text:
        raise SystemExit(
            "ERROR: remaining power-loss durability boundary was removed."
        )

    path.write_text(text, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Finalize Task 10.6 and the Task 10.4–10.6 cross-task checkpoint "
            "from fresh local verification logs."
        )
    )
    parser.add_argument(
        "--focused-log",
        type=Path,
        default=Path("/tmp/task10-4-to-10-6-focused.log"),
    )
    parser.add_argument(
        "--full-log",
        type=Path,
        default=Path("/tmp/task10-6-full.log"),
    )
    parser.add_argument(
        "--analyze-log",
        type=Path,
        default=Path("/tmp/task10-6-analyze.log"),
    )
    parser.add_argument(
        "--build-log",
        type=Path,
        default=Path("/tmp/task10-6-build.log"),
    )
    args = parser.parse_args()

    focused_count = _test_count(args.focused_log, "focused test")
    full_count = _test_count(args.full_log, "full test")
    _read_success_log(
        args.analyze_log,
        "No issues found!",
        "flutter analyze",
    )
    _read_success_log(
        args.build_log,
        "Built build/linux/x64/debug/bundle/dashboard_shakhsi",
        "Linux debug build",
    )

    if full_count < focused_count:
        raise SystemExit(
            "ERROR: full test count is smaller than focused test count."
        )
    if full_count < 1005:
        raise SystemExit(
            f"ERROR: full test count regressed below Gate 10.6.8: {full_count}"
        )

    diff_check = subprocess.run(
        ("git", "diff", "--check"),
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if diff_check.returncode != 0:
        raise SystemExit(
            "ERROR: git diff --check failed:\n"
            f"{diff_check.stdout.rstrip()}"
        )

    for label, path in (
        ("Task 10.4 checkpoint", TASK_10_4_CHECKPOINT),
        ("Task 10.5 checkpoint", TASK_10_5_CHECKPOINT),
        ("shared design", DESIGN_PATH),
    ):
        if not path.is_file():
            raise SystemExit(f"ERROR: missing {label}: {path}")

    _verify_focused_test_inventory()
    evidence = _gate_hashes()

    CHECKPOINT_PATH.parent.mkdir(parents=True, exist_ok=True)
    table_rows = "\n".join(
        f"| {gate} | `{commit_hash}` | `{subject}` |"
        for gate, commit_hash, subject in evidence
    )

    checkpoint = f"""# Linux Notification Delivery and Platform Wiring — Task 10.6 Checkpoint

Date finalized: {date.today().isoformat()}  
Phase: 1  
Task: 10.6  
Cross-task scope: Tasks 10.4–10.6  
Status: **Implemented and freshly verified**

## Completion boundary

- Task 10.4 — Persistent Linux Schedule Registry: **Complete**
- Task 10.5 — Linux systemd Notification Scheduler: **Complete**
- Task 10.6 — Delivery Entrypoint and Platform Wiring: **Complete**
- Tasks 10.4–10.6 as one Linux notification pipeline: **Complete**
- Unrelated Phase 1 work: **Not assessed and not marked complete**

## Scope completed

Task 10.6 adds exact persisted schedule lookup, a strict hidden invocation,
validated absolute executable resolution, shell-free delivery commands,
persisted private notification delivery, hidden application dispatch before UI,
lazy platform scheduler selection, non-blocking startup reconciliation, and an
in-memory integrated Linux delivery checkpoint.

The pipeline retains Drift desired state after hidden delivery. Hidden systemd
arguments contain only the executable path, hidden-delivery flag, and schedule
identifier. Title, body, owner, privacy mode, and payload are loaded from Drift
at execution time.

## Gate commit evidence

| Gate | Commit | Subject |
|---|---|---|
{table_rows}

## Fresh verification evidence

- Tasks 10.4–10.6 focused tests: **{focused_count} passed**
- Full project tests: **{full_count} passed**
- `flutter analyze`: **No issues found**
- `flutter build linux --debug`: **Succeeded**
- `git diff --check`: **Clean**
- Real user systemd process: **Not used by focused tests**
- Real HOME/XDG user-unit directory: **Not used by focused tests**
- Real desktop notification plugin/display: **Not used by focused tests**
- Database integration: **In-memory Drift only**

## Hidden delivery guarantees

- Hidden arguments are parsed exactly and reject trailing or malformed input.
- Hidden mode is selected before dashboard, router, and normal startup work.
- Exact `scheduleId` lookup reads the complete persisted request.
- Missing requests exit successfully without displaying a notification.
- Private content uses the privacy policy while retaining exact navigation
  payload and stable display identity.
- Delivery resources close on success and typed failure.
- Desired Drift state is not deleted after hidden delivery.

## Platform and startup guarantees

- Linux selects `LinuxSystemdNotificationScheduler`.
- Android, macOS, and Windows retain the native platform scheduler.
- Unsupported targets select the no-op scheduler.
- Non-Linux branches do not construct Linux filesystem, registry, unit-store,
  process-runner, executable, or systemd dependencies.
- Normal startup reconciliation is provider-scope single-flight.
- The dashboard renders immediately while reconciliation is pending.
- Startup failure is reported with its stack trace without replacing the UI.
- A failed reconciliation can retry without repeating plugin initialization.

## Integrated pipeline evidence

The focused integration test covers:

1. persisted Drift schedule creation;
2. deterministic minimal systemd service command rendering;
3. controlled fake systemd enable/start/health mutation;
4. hidden entrypoint dispatch without normal UI startup;
5. exact persisted lookup;
6. privacy-safe immediate display;
7. payload and stable-ID preservation;
8. retained desired Drift state;
9. successful missing-request no-op;
10. lazy unsupported-platform selection;
11. one startup reconciliation per provider scope.

## Remaining durability boundary

No atomic transaction spans Drift, two systemd unit files, the systemd user
manager, and the registry file. The implementation provides in-process
rollback and deterministic restart reconciliation, but it does **not** claim
power-loss atomicity or explicit fsync durability across all resources.

This boundary remains documented by design and is not expanded by Task 10.6.

## Prior task checkpoints

- [Task 10.4 registry checkpoint](2026-07-30-linux-systemd-schedule-registry-checkpoint.md)
- [Task 10.5 scheduler checkpoint](2026-07-30-linux-systemd-notification-scheduler-checkpoint.md)
"""

    CHECKPOINT_PATH.write_text(checkpoint, encoding="utf-8")

    checkpoint_relative = (
        "../checkpoints/"
        "2026-08-02-linux-notification-delivery-platform-wiring-checkpoint.md"
    )
    _update_design(DESIGN_PATH, checkpoint_relative)

    print(
        "OK: Task 10.6 checkpoint prepared with "
        f"{focused_count} focused tests, {full_count} full tests, "
        "eight exact Gate commit hashes, clean analyze/build/diff evidence, "
        "Tasks 10.4–10.6 marked complete, unrelated Phase 1 work untouched, "
        "and the remaining power-loss durability boundary preserved."
    )


if __name__ == "__main__":
    main()
