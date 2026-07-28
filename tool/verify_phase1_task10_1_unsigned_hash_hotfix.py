#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "lib/core/notifications/linux_systemd_notification_unit.dart"
)

if not path.exists():
    print(f"ERROR: missing {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "final hash = _fnv1a64(utf8.encode(scheduleKey));",
    "final unsignedHash = hash.toUnsigned(64);",
    "final hex = unsignedHash.toRadixString(16).padLeft(16, '0');",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: unsigned FNV-1a hotfix is incomplete: {missing}")
    sys.exit(1)

if "final hex = hash.toRadixString(16)" in text:
    print("ERROR: signed hash conversion is still present.")
    sys.exit(1)

print(
    "OK: Task 10.1 converts the 64-bit hash to unsigned before "
    "building systemd unit names."
)
