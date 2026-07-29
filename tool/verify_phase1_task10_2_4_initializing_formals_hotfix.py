#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "lib/core/notifications/linux_systemd_user_unit_store.dart"
)

if not path.exists():
    print(f"ERROR: missing {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "factory LinuxSystemdUserUnitStore({",
    "return LinuxSystemdUserUnitStore._(",
    "LinuxSystemdUserUnitStore._(",
    "this._pathResolver",
    "this._fileSystem",
    "this._transactionIdFactory",
]
missing = [token for token in required if token not in text]
if missing:
    print(
        "ERROR: Task 10.2.4 initializing-formals hotfix "
        f"is incomplete: {missing}"
    )
    sys.exit(1)

for forbidden in (
    "_pathResolver = pathResolver",
    "_fileSystem = fileSystem",
    "_transactionIdFactory = transactionIdFactory",
    "ignore: prefer_initializing_formals",
):
    if forbidden in text:
        print(
            "ERROR: legacy initializer or lint suppression remains: "
            f"{forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.2.4 preserves the public named-parameter API "
    "and uses initializing formals internally."
)
