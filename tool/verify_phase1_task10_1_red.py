#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path(
    "test/core/notifications/linux_systemd_unit_renderer_test.dart"
)
production_paths = [
    Path(
        "lib/core/notifications/linux_systemd_notification_unit.dart"
    ),
    Path(
        "lib/core/notifications/linux_systemd_unit_renderer.dart"
    ),
]

if not test_path.exists():
    print(f"ERROR: missing Task 10.1 RED test: {test_path}")
    sys.exit(1)

existing = [str(path) for path in production_paths if path.exists()]
if existing:
    print(
        "ERROR: RED expects Task 10.1 production files to be absent, "
        f"but found: {', '.join(existing)}"
    )
    sys.exit(1)

text = test_path.read_text(encoding="utf-8")
required = [
    "LinuxSystemdNotificationUnit",
    "LinuxSystemdUnitNames",
    "LinuxSystemdUnitRenderer",
    "renders an exact one-shot UTC calendar time",
    "quotes executable paths and command arguments safely",
    "does not expose the raw schedule key in unit file names",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.1 RED coverage is incomplete: {missing}")
    sys.exit(1)

print(
    "OK: Task 10.1 RED test is installed and production files are absent. "
    "Run the focused Flutter test and confirm the missing-import failure."
)
