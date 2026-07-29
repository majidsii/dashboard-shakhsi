#!/usr/bin/env python3
from pathlib import Path
import re
import sys

production_paths = [
    Path("lib/core/notifications/linux_systemd_environment.dart"),
    Path(
        "lib/core/notifications/"
        "linux_systemd_user_unit_path_resolver.dart"
    ),
    Path("lib/core/notifications/linux_systemd_file_system.dart"),
    Path(
        "lib/core/notifications/"
        "dart_io_linux_systemd_file_system.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_systemd_user_unit_store_exception.dart"
    ),
    Path(
        "lib/core/notifications/"
        "linux_systemd_user_unit_store.dart"
    ),
]

test_paths = [
    Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_path_resolver_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "dart_io_linux_systemd_file_system_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_store_install_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_store_rollback_test.dart"
    ),
    Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_store_remove_test.dart"
    ),
    Path("test/support/fake_linux_systemd_file_system.dart"),
]

missing = [
    str(path)
    for path in production_paths + test_paths
    if not path.exists()
]
if missing:
    print("ERROR: Task 10.2 files are missing:")
    for path in missing:
        print(f"  - {path}")
    sys.exit(1)

texts = {
    path: path.read_text(encoding="utf-8")
    for path in production_paths + test_paths
}

required_by_path = {
    production_paths[0]: [
        "abstract interface class LinuxSystemdEnvironment",
        "final class PlatformLinuxSystemdEnvironment",
        "Platform.environment[name]",
    ],
    production_paths[1]: [
        "final class LinuxSystemdUserUnitPathResolver",
        "_environment.value('XDG_CONFIG_HOME')",
        "_environment.value('HOME')",
        "'.config/systemd/user'",
    ],
    production_paths[2]: [
        "enum LinuxSystemdEntryType",
        "abstract interface class LinuxSystemdFileSystem",
        "Future<int> readMode(String path)",
        "Future<void> chmod(String path, int mode)",
    ],
    production_paths[3]: [
        "FileSystemEntity.type(",
        "followLinks: false",
        "posix.chmodWithMode(path, mode)",
        "stat.mode & 0x1FF",
    ],
    production_paths[4]: [
        "enum LinuxSystemdUserUnitStoreOperation",
        "final class LinuxSystemdRollbackFailure",
        "final class LinuxSystemdUserUnitStoreException",
        "List<LinuxSystemdRollbackFailure>.unmodifiable",
    ],
    production_paths[5]: [
        "Future<void> install(LinuxSystemdRenderedUnits units)",
        "Future<void> remove(LinuxSystemdUnitNames names) async",
        "final state = _InstallTransactionState()",
        "await _rollback(",
        "rollbackFailures: rollbackFailures",
        "final class _ExistingUnitSnapshot",
        "operation: 'remove'",
    ],
    test_paths[5]: [
        "final class FakeLinuxSystemdFileSystem",
        "Queue<Object>",
        "void failNext(",
        "Future<int> readMode(String path)",
    ],
}

for path, required in required_by_path.items():
    text = texts[path]
    missing_tokens = [token for token in required if token not in text]
    if missing_tokens:
        print(f"ERROR: incomplete Task 10.2 file: {path}")
        for token in missing_tokens:
            print(f"  - missing token: {token}")
        sys.exit(1)

pubspec = Path("pubspec.yaml")
if not pubspec.exists():
    print("ERROR: pubspec.yaml is missing.")
    sys.exit(1)

pubspec_text = pubspec.read_text(encoding="utf-8")
if not re.search(r"(?m)^\s*posix:\s*\^?6\.5\.0\s*$", pubspec_text):
    print("ERROR: pubspec.yaml must contain posix: ^6.5.0.")
    sys.exit(1)

production_text = "\n".join(
    texts[path] for path in production_paths
)
for forbidden in (
    "Process.run",
    "Process.start",
    "/bin/sh",
    "sh -c",
    "systemctl",
):
    if forbidden in production_text:
        print(
            "ERROR: Task 10.2 production code contains forbidden "
            f"command execution: {forbidden}"
        )
        sys.exit(1)

store_path = production_paths[5]
store_text = texts[store_path]
if "static const int _unitFileMode = 0x1A4;" not in store_text:
    print("ERROR: final systemd unit mode must be 0644 (0x1A4).")
    sys.exit(1)

if store_text.find("deleteFile(timerPath)") >= store_text.find(
    "deleteFile(servicePath)"
):
    print("ERROR: removal must delete timer before service.")
    sys.exit(1)

lib_root = Path("lib")
external_references = []
for path in lib_root.rglob("*.dart"):
    if path == store_path:
        continue
    text = path.read_text(encoding="utf-8")
    if "LinuxSystemdUserUnitStore(" in text:
        external_references.append(str(path))

if external_references:
    print(
        "ERROR: Task 10.2 store is already wired outside its own file. "
        "Platform integration belongs to a later Task:"
    )
    for path in external_references:
        print(f"  - {path}")
    sys.exit(1)

for test_path in test_paths:
    text = texts[test_path]
    for forbidden in (
        "Platform.environment",
        "/home/shabin/.config/systemd/user",
        "Directory('/home/",
        'Directory("/home/',
    ):
        if forbidden in text:
            print(
                f"ERROR: focused test touches real user state: "
                f"{test_path}: {forbidden}"
            )
            sys.exit(1)

print(
    "OK: Task 10.2 structure is complete: six production files, "
    "six test-support files, POSIX FFI chmod, full install rollback, "
    "safe removal, no systemctl, and no platform wiring."
)
