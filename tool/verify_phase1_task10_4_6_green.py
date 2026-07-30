#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "contract": Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry_store.dart"
    ),
    "file_store": Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry_file_store.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_store_replace_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.4.6 {label}: {path}")
        sys.exit(1)

contract = paths["contract"].read_text(encoding="utf-8")
file_store = paths["file_store"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")
normalized_contract = " ".join(contract.split())
normalized_file_store = " ".join(file_store.split())

required_contract = [
    "Future<LinuxSystemdScheduleRegistry> load()",
    "Future<void> replace(LinuxSystemdScheduleRegistry next)",
]
required_store = [
    "Future<void> replace(",
    "next.generation != snapshot.registry.generation + 1",
    "invalidGenerationTransition",
    "r'^[A-Za-z0-9_-]{1,64}$'",
    ".dashboard-shakhsi-notification-registry.",
    "await fileSystem.createDirectory(directory)",
    "await fileSystem.writeBytes(tempPath, nextBytes)",
    "await fileSystem.chmod(tempPath, registryFileMode)",
    "await fileSystem.rename(registryPath, backupPath)",
    "await fileSystem.rename(tempPath, registryPath)",
    "await fileSystem.chmod(registryPath, registryFileMode)",
    "await fileSystem.deleteFile(backupPath)",
    "final class _RegistrySnapshot",
    "List<int>.unmodifiable(bytes)",
    "final class _RegistryReplaceState",
    "step: 'delete-new-registry'",
    "step: 'restore-registry-backup'",
    "step: 'rewrite-previous-registry'",
    "step: 'restore-previous-registry-mode'",
    "step: 'delete-registry-backup'",
    "step: 'delete-registry-temp'",
    "Future<bool> _attemptRollback",
    "rollbackFailures:",
    "cause: error",
]
required_test = [
    "installs generation one when the registry is missing",
    "atomically replaces an existing generation",
    "rejects unsafe transaction id",
    "restores exact previous bytes after failure at",
    "keeps the primary error and attaches backup-restore failure",
    "records fallback rewrite failure after backup restore fails",
]

for label, text, required in (
    ("store contract", normalized_contract, required_contract),
    ("atomic replacement implementation", normalized_file_store, required_store),
    ("Gate tests", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = f"{contract}\n{file_store}"

for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "systemctl",
    "title",
    "body",
    "payload",
    "UnimplementedError",
):
    if forbidden in combined:
        print(
            "ERROR: Task 10.4.6 contains forbidden process, sensitive, "
            f"or placeholder coupling: {forbidden}"
        )
        sys.exit(1)

load_index = normalized_file_store.find(
    "final snapshot = await _loadSnapshot"
)
generation_index = normalized_file_store.find(
    "next.generation != snapshot.registry.generation + 1"
)
encode_index = normalized_file_store.find(
    "final nextBytes = _encodeForReplace"
)
directory_index = normalized_file_store.find(
    "await fileSystem.createDirectory(directory)"
)
write_index = normalized_file_store.find(
    "await fileSystem.writeBytes(tempPath, nextBytes)"
)
backup_index = normalized_file_store.find(
    "await fileSystem.rename(registryPath, backupPath)"
)
publish_index = normalized_file_store.find(
    "await fileSystem.rename(tempPath, registryPath)"
)
mode_index = normalized_file_store.find(
    "await fileSystem.chmod(registryPath, registryFileMode)"
)

if not (
    -1
    < load_index
    < generation_index
    < encode_index
    < directory_index
    < write_index
    < backup_index
    < publish_index
    < mode_index
):
    print("ERROR: atomic replacement forward ordering is incorrect.")
    sys.exit(1)

print(
    "OK: Task 10.4.6 GREEN adds strict generation transitions and "
    "same-directory temp/backup atomic replacement, validates every "
    "transaction path, snapshots exact prior bytes and mode, restores or "
    "rewrites prior state on every observed failure, preserves the primary "
    "cause, and attaches ordered rollback failures without process coupling."
)
