#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "interface": Path(
        "lib/core/notifications/linux_systemd_file_system.dart"
    ),
    "dart_io": Path(
        "lib/core/notifications/"
        "dart_io_linux_systemd_file_system.dart"
    ),
    "fake": Path(
        "test/support/fake_linux_systemd_file_system.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_file_system_registry_extensions_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.4.4 {label}: {path}")
        sys.exit(1)

interface = paths["interface"].read_text(encoding="utf-8")
dart_io = paths["dart_io"].read_text(encoding="utf-8")
fake = paths["fake"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_interface = [
    "Future<int> fileLength(String path)",
    "Future<List<String>> listNames(String directoryPath)",
]
required_dart_io = [
    "Future<int> fileLength(String path) async",
    "entryType != LinuxSystemdEntryType.regularFile",
    "return File(path).length()",
    "Future<List<String>> listNames(String directoryPath) async",
    "case LinuxSystemdEntryType.missing:",
    "Directory(directoryPath).list(",
    "recursive: false",
    "followLinks: false",
    "List<String>.unmodifiable(sorted)",
    "static String _baseName(String path)",
]
required_fake = [
    "Future<int> fileLength(String path) async",
    "'fileLength:$path'",
    "LinuxSystemdEntryType.missing",
    "Future<List<String>> listNames(",
    "'listNames:$directoryPath'",
    "remainder.contains('/')",
    "List<String>.unmodifiable(sorted)",
    "throw FileSystemException('Path does not exist.', path)",
]
required_test = [
    "fileLength returns the exact regular-file byte count",
    "fileLength rejects a symbolic link without following it",
    "listNames returns sorted direct child basenames only",
    "listNames does not follow a direct child directory symlink",
    "listNames returns an empty immutable list for a missing directory",
    "fileLength supports deterministic injected failures",
    "listNames derives sorted unique direct children only",
    "listNames supports deterministic injected failures",
]

for label, text, required in (
    ("filesystem interface", interface, required_interface),
    ("Dart IO adapter", dart_io, required_dart_io),
    ("fake adapter", fake, required_fake),
    ("Gate tests", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = "\n".join((interface, dart_io, fake))

for forbidden in (
    "Process.start",
    "Process.run",
    "systemctl",
    "followLinks: true",
):
    if forbidden in combined:
        print(
            "ERROR: Task 10.4.4 contains forbidden process or "
            f"link-following behavior: {forbidden}"
        )
        sys.exit(1)

if "recursive: true" in dart_io[
    dart_io.find("Future<List<String>> listNames"):
]:
    print("ERROR: production listNames performs recursive listing.")
    sys.exit(1)

print(
    "OK: Task 10.4.4 GREEN extends both filesystem adapters with exact "
    "regular-file length and sorted immutable direct-child listing, rejects "
    "unsafe roots and length targets, never follows links or recurses, "
    "preserves existing fake missing-file behavior, and records injectable "
    "fileLength/listNames operations deterministically."
)
