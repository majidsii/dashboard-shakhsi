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
    "static BigInt _fnv1a64(List<int> bytes)",
    "BigInt.parse(",
    "'cbf29ce484222325'",
    "'100000001b3'",
    "'ffffffffffffffff'",
    "hash ^= BigInt.from(byte);",
    "hash = (hash * prime) & mask64;",
    "final hex = hash.toRadixString(16).padLeft(16, '0');",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: BigInt FNV-1a hotfix is incomplete: {missing}")
    sys.exit(1)

for forbidden in (
    "hash.toUnsigned(64)",
    "static int _fnv1a64",
    "const mask64 = 0xffffffffffffffff",
):
    if forbidden in text:
        print(f"ERROR: old signed-int hash path remains: {forbidden}")
        sys.exit(1)

print(
    "OK: Task 10.1 now computes FNV-1a entirely in an unsigned "
    "64-bit BigInt domain."
)
