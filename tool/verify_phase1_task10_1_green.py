#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "model": Path(
        "lib/core/notifications/linux_systemd_notification_unit.dart"
    ),
    "renderer": Path(
        "lib/core/notifications/linux_systemd_unit_renderer.dart"
    ),
    "test": Path(
        "test/core/notifications/linux_systemd_unit_renderer_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.1 {label} file: {path}")
        sys.exit(1)

model = paths["model"].read_text(encoding="utf-8")
renderer = paths["renderer"].read_text(encoding="utf-8")
tests = paths["test"].read_text(encoding="utf-8")

model_required = [
    "final class LinuxSystemdNotificationUnit",
    "must be a UTC DateTime",
    "must be an absolute path",
    "List<String>.unmodifiable(arguments)",
    "final class LinuxSystemdUnitNames",
    "dashboard-shakhsi-notification-$hex",
    "_fnv1a64",
]
renderer_required = [
    "final class LinuxSystemdRenderedUnits",
    "final class LinuxSystemdUnitRenderer",
    "Type=oneshot",
    "OnCalendar=${_formatUtcCalendar(unit.scheduledAtUtc)}",
    "AccuracySec=1s",
    "RandomizedDelaySec=0",
    "Persistent=true",
    "WantedBy=timers.target",
    ".replaceAll(r'$', r'$$')",
    ".replaceAll('%', '%%')",
]

for label, text, required in (
    ("model", model, model_required),
    ("renderer", renderer, renderer_required),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: Task 10.1 {label} is incomplete: {missing}")
        sys.exit(1)

test_count = tests.count("test(")
if test_count < 20:
    print(
        "ERROR: expected at least 20 focused Task 10.1 tests, "
        f"found {test_count}."
    )
    sys.exit(1)

print(
    "OK: Task 10.1 safe Linux systemd unit model, deterministic naming, "
    "renderer, and focused tests are present."
)
