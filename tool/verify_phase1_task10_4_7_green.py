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
        "linux_systemd_schedule_registry_store_recovery_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.4.7 {label}: {path}")
        sys.exit(1)

contract = paths["contract"].read_text(encoding="utf-8")
file_store = paths["file_store"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_contract = [
    "Future<LinuxSystemdScheduleRegistry> load()",
    "Future<void> replace(LinuxSystemdScheduleRegistry next)",
    "Future<void> quarantineCorruptRegistry()",
    "Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs()",
]
required_store = [
    "import 'dart:collection'",
    "Future<void> quarantineCorruptRegistry() async",
    "LinuxSystemdScheduleRegistryOperation.quarantine",
    "'$transactionId.corrupt'",
    "fileSystem.rename(registryPath, quarantinePath)",
    "Future<LinuxSystemdUnitDiscovery>",
    "discoverAppUnitPairs() async",
    "LinuxSystemdScheduleRegistryOperation.discover",
    "r'^(dashboard-shakhsi-notification-[0-9a-f]{16})\\.service$'",
    "r'^(dashboard-shakhsi-notification-[0-9a-f]{16})\\.timer$'",
    "fileSystem.listNames(directory)",
    "SplayTreeMap<String, _DiscoveredUnitParts>",
    "fileSystem.typeOf(path)",
    "LinuxSystemdScheduleRegistryFailure.unsafeAppUnitPath",
    "LinuxSystemdUnitNames.parseBaseName(entry.key)",
    "LinuxSystemdPartialUnitPair(",
    "LinuxSystemdUnitDiscovery(",
    "LinuxSystemdScheduleRegistryFailure.quarantineFailed",
    "LinuxSystemdScheduleRegistryFailure.discoveryFailed",
]
required_test = [
    "missing registry quarantine is idempotent",
    "renames corrupt registry byte-for-byte without decoding it",
    "never overwrites existing quarantine",
    "maps rename failure to quarantineFailed",
    "discovers exact complete and partial app-owned pairs only",
    "sorts complete and partial pairs by base name",
    "inspects each exact matched name exactly once",
    "ignores unrelated symlink without inspecting it",
    "maps listing failure to discoveryFailed",
    "maps exact child inspection failure and preserves child path",
]

for label, text, required in (
    ("store contract", contract, required_contract),
    ("recovery implementation", file_store, required_store),
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
            "ERROR: Task 10.4.7 contains forbidden process, direct "
            f"filesystem, sensitive, or placeholder coupling: {forbidden}"
        )
        sys.exit(1)

quarantine_start = file_store.find(
    "Future<void> quarantineCorruptRegistry() async"
)
discovery_start = file_store.find(
    "discoverAppUnitPairs() async"
)
snapshot_start = file_store.find(
    "Future<_RegistrySnapshot> _loadSnapshot"
)

if not (-1 < quarantine_start < discovery_start < snapshot_start):
    print("ERROR: recovery methods are not installed in the expected class.")
    sys.exit(1)

quarantine_body = file_store[quarantine_start:discovery_start]
for forbidden in (
    "codec.decodeBytes",
    "fileSystem.readBytes",
    "fileSystem.fileLength",
    "fileSystem.readMode",
    "fileSystem.deleteFile",
    "fileSystem.writeBytes",
    "fileSystem.chmod",
):
    if forbidden in quarantine_body:
        print(
            "ERROR: quarantine decodes, deletes, reads, rewrites, or "
            f"changes corrupt bytes: {forbidden}"
        )
        sys.exit(1)

discovery_body = file_store[discovery_start:snapshot_start]
if discovery_body.count("fileSystem.listNames(directory)") != 1:
    print("ERROR: discovery must perform exactly one directory listing.")
    sys.exit(1)

if "recursive" in discovery_body or "followLinks" in discovery_body:
    print("ERROR: discovery bypasses the injected one-level filesystem API.")
    sys.exit(1)

print(
    "OK: Task 10.4.7 GREEN completes the registry-store contract with "
    "idempotent byte-preserving corrupt quarantine and deterministic one-pass "
    "app-unit discovery, exact lowercase-hex ownership patterns, complete/"
    "partial grouping, matched-path link safety, destination non-overwrite, "
    "and typed resolver/listing/inspection/rename failures."
)
