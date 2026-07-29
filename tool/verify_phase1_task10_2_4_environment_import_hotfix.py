#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "test/core/notifications/"
    "linux_systemd_user_unit_store_install_test.dart"
)

if not path.exists():
    print(f"ERROR: missing {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "linux_systemd_environment.dart",
    "implements LinuxSystemdEnvironment",
    "_MapLinuxSystemdEnvironment",
]
missing = [token for token in required if token not in text]
if missing:
    print(
        "ERROR: Task 10.2.4 environment import hotfix "
        f"is incomplete: {missing}"
    )
    sys.exit(1)

if text.count("linux_systemd_environment.dart") != 1:
    print(
        "ERROR: linux_systemd_environment.dart import "
        "must appear exactly once."
    )
    sys.exit(1)

print(
    "OK: Task 10.2.4 test imports LinuxSystemdEnvironment."
)
