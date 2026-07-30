#!/usr/bin/env python3
"""Verify the complete Task 10.4 Linux schedule registry checkpoint."""

from __future__ import annotations

import re
import sys
from pathlib import Path

PRODUCTION_FILES = [
    Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry_exception.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_systemd_registry_json_decoder.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry_codec.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_notification_request_fingerprint.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_systemd_file_system.dart"
    ),
    Path(
        "lib/core/notifications/"
        "dart_io_linux_systemd_file_system.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry_store.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry_file_store.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_systemd_notification_unit.dart"
    ),
]

TEST_FILES = [
    Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_model_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_registry_json_decoder_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_codec_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_notification_request_fingerprint_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_file_system_registry_extensions_test.dart"
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
        "linux_systemd_schedule_registry_store_recovery_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_final_checkpoint_test.dart"
    ),
]

CHECKPOINT = Path(
    "docs/superpowers/checkpoints/"
    "2026-07-30-linux-systemd-schedule-registry-checkpoint.md"
)
DESIGN = Path(
    "docs/superpowers/specs/"
    "2026-07-29-linux-systemd-notification-pipeline-design.md"
)
PREPARE = Path("tool/prepare_phase1_task10_4_checkpoint.py")


def _fail(message: str) -> None:
    print(f"ERROR: {message}")
    raise SystemExit(1)


def _require_files(paths: list[Path], label: str) -> None:
    missing = [str(path) for path in paths if not path.exists()]
    if missing:
        _fail(f"missing {label}: {missing}")


def _require_tokens(
    text: str,
    tokens: list[str],
    label: str,
) -> None:
    missing = [token for token in tokens if token not in text]
    if missing:
        _fail(f"incomplete {label}: {missing}")


def main() -> None:
    _require_files(PRODUCTION_FILES, "Task 10.4 production files")
    _require_files(TEST_FILES, "Task 10.4 tests")
    _require_files([CHECKPOINT, DESIGN, PREPARE], "checkpoint artifacts")

    decoder = PRODUCTION_FILES[2].read_text(encoding="utf-8")
    codec = PRODUCTION_FILES[3].read_text(encoding="utf-8")
    fingerprint = PRODUCTION_FILES[4].read_text(encoding="utf-8")
    filesystem = PRODUCTION_FILES[5].read_text(encoding="utf-8")
    store_contract = PRODUCTION_FILES[7].read_text(encoding="utf-8")
    store = PRODUCTION_FILES[8].read_text(encoding="utf-8")
    registry_model = PRODUCTION_FILES[0].read_text(encoding="utf-8")
    checkpoint_test = TEST_FILES[-1].read_text(encoding="utf-8")
    checkpoint = CHECKPOINT.read_text(encoding="utf-8")
    design = DESIGN.read_text(encoding="utf-8")

    _require_tokens(
        decoder,
        [
            "if (!keys.add(key))",
            "Map<String, Object?> _parseObject()",
            "List<Object?> _parseArray()",
            "LinuxSystemdScheduleRegistryFailure.malformedJson",
        ],
        "duplicate-aware JSON decoder",
    )
    _require_tokens(
        codec,
        [
            "static const int maximumFileBytes = 1 << 20",
            "static const int maximumEntries = 10000",
            "utf8.decode(bytes, allowMalformed: false)",
            "utf8.encode('$encoded\\n')",
        ],
        "strict registry codec",
    )
    _require_tokens(
        fingerprint,
        [
            "Sha256().hash",
            "SplayTreeMap<String, String>.from",
            "deliveryCommandSchemaVersion",
        ],
        "request fingerprint",
    )
    _require_tokens(
        filesystem,
        [
            "Future<int> fileLength(String path)",
            "Future<List<String>> listNames(String directoryPath)",
        ],
        "filesystem contract",
    )
    _require_tokens(
        store_contract,
        [
            "Future<LinuxSystemdScheduleRegistry> load()",
            "Future<void> replace(LinuxSystemdScheduleRegistry next)",
            "Future<void> quarantineCorruptRegistry()",
            "Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs()",
        ],
        "final registry store interface",
    )
    _require_tokens(
        store,
        [
            "'dashboard-shakhsi-notification-registry.json'",
            "static const int registryFileMode = 0x180",
            "Future<LinuxSystemdScheduleRegistry> load()",
            "Future<void> replace(",
            "Future<void> quarantineCorruptRegistry()",
            "discoverAppUnitPairs() async",
            "atomicReplacementFailed",
            "quarantineFailed",
            "discoveryFailed",
        ],
        "registry file store",
    )
    _require_tokens(
        checkpoint_test,
        [
            "runs the complete fake-filesystem registry lifecycle",
            "verifies the real Linux temporary-directory adapter",
            "Directory.systemTemp.createTemp",
            "Platform.isLinux",
            "LinuxNotificationRequestFingerprint",
            "quarantineCorruptRegistry",
            "discoverAppUnitPairs",
            "unsafeAppUnitPath",
        ],
        "final lifecycle checkpoint",
    )

    sensitive_fields = re.findall(
        r"\b(?:final|required)\s+(?:String|Map<[^>]+>)\s+"
        r"(title|body|payload)\b",
        registry_model,
    )
    if sensitive_fields:
        _fail(
            "registry model stores sensitive notification fields: "
            f"{sorted(set(sensitive_fields))}"
        )

    production_text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in PRODUCTION_FILES
    )
    for forbidden in (
        "linux_process_runner.dart",
        "linux_systemd_user_driver.dart",
        "systemctl",
    ):
        if forbidden in production_text:
            _fail(
                "Task 10.4 production imports or invokes scheduler/process "
                f"coupling: {forbidden}"
            )

    unresolved = sorted(
        set(re.findall(r"__[A-Z0-9_]+__", checkpoint))
    )
    if unresolved:
        _fail(
            "checkpoint must be finalized before verification; "
            f"unresolved placeholders: {unresolved}"
        )

    hashes = re.findall(r"`([0-9a-f]{40})`", checkpoint)
    if len(set(hashes)) < 7:
        _fail(
            "checkpoint must contain seven distinct exact pre-checkpoint "
            "Gate commit hashes"
        )

    _require_tokens(
        checkpoint,
        [
            "Status: Implemented and verified",
            "Task 10.4 focused tests",
            "Full Flutter test suite",
            "does **not** claim cross-resource power-loss atomicity",
            "Task 10.5 remains pending",
            "Task 10.6 remains pending",
            "This checkpoint commit",
        ],
        "checkpoint document",
    )
    _require_tokens(
        design,
        [
            "Task 10.4 — Persistent Linux Schedule Registry: "
            "**Implemented**",
            "Task 10.5 — Linux systemd Notification Scheduler: "
            "**Pending**",
            "Task 10.6 — Delivery Entrypoint and Platform Wiring: "
            "**Pending**",
            "# Task 10.4 — Persistent Linux Schedule Registry\n\n"
            "Status: **Implemented**",
            "# Task 10.5 — Linux systemd Notification Scheduler\n\n"
            "Status: **Pending**",
            "# Task 10.6 — Delivery Entrypoint and Platform Wiring\n\n"
            "Status: **Pending**",
        ],
        "design implementation status",
    )

    print(
        "OK: Task 10.4 complete checkpoint verifies all production and test "
        "artifacts, duplicate-aware JSON, strict bounds, SHA-256 privacy, "
        "filesystem inventory, the four-method store contract, exact 0600 "
        "registry persistence, fake and real-adapter lifecycles, seven exact "
        "Gate hashes, durability boundaries, and pending Task 10.5/10.6 status."
    )


if __name__ == "__main__":
    main()
