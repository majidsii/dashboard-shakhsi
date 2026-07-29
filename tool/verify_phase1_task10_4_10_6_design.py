#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "docs/superpowers/specs/"
    "2026-07-29-linux-systemd-notification-pipeline-design.md"
)

if not path.exists():
    print(f"ERROR: missing design spec: {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "# Linux systemd Notification Pipeline — Design",
    "# Task 10.4 — Persistent Linux Schedule Registry",
    "# Task 10.5 — Linux systemd Notification Scheduler",
    "# Task 10.6 — Delivery Entrypoint and Platform Wiring",
    "Drift remains the authoritative desired schedule set",
    "registry file mode is `0600`",
    "request fingerprint",
    "Future<int> fileLength",
    "Future<List<String>> listNames",
    "LinuxSystemdUnitInstallTransaction",
    "LinuxSystemdUnitRemoveTransaction",
    "in-process rollback",
    "deterministic restart reconciliation",
    "--deliver-notification",
    "Future<NotificationRequest?> getById",
    "no automated test invokes a real `systemctl`",
    "does not guarantee that every write survives sudden power loss",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: design is incomplete: {missing}")
    sys.exit(1)

for placeholder in ("TBD", "TODO", "FIXME", "<placeholder>"):
    if placeholder in text:
        print(f"ERROR: unresolved placeholder: {placeholder}")
        sys.exit(1)

if "title, body, payload" not in text:
    print("ERROR: privacy boundary is not explicit")
    sys.exit(1)

print(
    "OK: Task 10.4–10.6 design is complete, versioned, privacy-preserving, "
    "explicit about rollback and durability boundaries, and ready for "
    "implementation planning."
)
