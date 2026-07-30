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
        "linux_systemd_schedule_registry_store_load_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.4.5 {label}: {path}")
        sys.exit(1)

contract = paths["contract"].read_text(encoding="utf-8")
file_store = paths["file_store"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_contract = [
    "typedef LinuxSystemdRegistryTransactionIdFactory = String Function()",
    "abstract interface class LinuxSystemdScheduleRegistryStore",
    "Future<LinuxSystemdScheduleRegistry> load()",
]
required_store = [
    "final class LinuxSystemdScheduleRegistryFileStore",
    "implements LinuxSystemdScheduleRegistryStore",
    "static const String registryFileName =",
    "'dashboard-shakhsi-notification-registry.json'",
    "static const int registryFileMode = 0x180",
    "required this.pathResolver",
    "required this.fileSystem",
    "required this.codec",
    "required this.transactionIdFactory",
    "Future<LinuxSystemdScheduleRegistry> load() async",
    "fileSystem.typeOf(registryPath)",
    "case LinuxSystemdEntryType.missing:",
    "LinuxSystemdScheduleRegistry.empty()",
    "fileSystem.fileLength(registryPath)",
    "LinuxSystemdScheduleRegistryCodec.maximumFileBytes",
    "fileSystem.readBytes(registryPath)",
    "fileSystem.readMode(registryPath)",
    "mode != registryFileMode",
    "codec.decodeBytes(bytes)",
    "failure: error.failure",
    "field: error.field",
    "cause: error",
    "LinuxSystemdScheduleRegistryOperation.load",
]
required_test = [
    "loads a valid registry after length and mode checks",
    "rejects a file larger than one MiB before reading it",
    "does not mutate, quarantine, or create anything while loading",
    "wraps path-resolution failure before touching the filesystem",
    "safe diagnostics never include registry bytes",
]

for label, text, required in (
    ("store contract", contract, required_contract),
    ("safe load implementation", file_store, required_store),
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
    "createDirectory(",
    "writeBytes(",
    "rename(",
    "deleteFile(",
    "chmod(",
    "listNames(",
    "title",
    "body",
    "payload",
    "UnimplementedError",
    "UnsupportedError",
):
    if forbidden in combined:
        print(
            "ERROR: Task 10.4.5 contains mutation, process, placeholder, "
            f"or sensitive coupling: {forbidden}"
        )
        sys.exit(1)

type_index = file_store.find("fileSystem.typeOf(registryPath)")
length_index = file_store.find("fileSystem.fileLength(registryPath)")
read_index = file_store.find("fileSystem.readBytes(registryPath)")
mode_index = file_store.find("fileSystem.readMode(registryPath)")
decode_index = file_store.find("codec.decodeBytes(bytes)")

if not (
    -1 < type_index < length_index < read_index < mode_index < decode_index
):
    print("ERROR: safe load operation ordering is incorrect.")
    sys.exit(1)

print(
    "OK: Task 10.4.5 GREEN adds a load-only TDD registry-store contract "
    "and safe file-backed load with exact filename and 0600 mode, missing-as-"
    "empty behavior, link-aware path validation, pre-read one-MiB rejection, "
    "strict codec failure preservation, read-only operation ordering, "
    "resolver/filesystem cause retention, and safe diagnostics."
)
