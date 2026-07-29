#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "environment": Path(
        "lib/core/notifications/linux_systemd_environment.dart"
    ),
    "resolver": Path(
        "lib/core/notifications/"
        "linux_systemd_user_unit_path_resolver.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_user_unit_path_resolver_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.2.1 {label} file: {path}")
        sys.exit(1)

environment = paths["environment"].read_text(encoding="utf-8")
resolver = paths["resolver"].read_text(encoding="utf-8")
tests = paths["test"].read_text(encoding="utf-8")

required_environment = [
    "abstract interface class LinuxSystemdEnvironment",
    "final class PlatformLinuxSystemdEnvironment",
    "Platform.environment[name]",
]
required_resolver = [
    "final class LinuxSystemdConfigurationException",
    "final class LinuxSystemdUserUnitPathResolver",
    "_environment.value('XDG_CONFIG_HOME')",
    "_environment.value('HOME')",
    "'.config/systemd/user'",
    "'systemd/user'",
    "_validateAbsoluteBase",
    "_containsControlCharacter",
    "_removeTrailingSlashes",
]

for label, text, required in (
    ("environment", environment, required_environment),
    ("resolver", resolver, required_resolver),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(
            f"ERROR: Task 10.2.1 {label} implementation "
            f"is incomplete: {missing}"
        )
        sys.exit(1)

if tests.count("test(") != 12:
    print(
        "ERROR: expected exactly 12 focused resolver tests, "
        f"found {tests.count('test(')}."
    )
    sys.exit(1)

for forbidden in (
    "Directory(",
    "createSync(",
    "create(recursive:",
    "systemctl",
):
    if forbidden in resolver or forbidden in environment:
        print(
            "ERROR: Task 10.2.1 must only resolve paths; "
            f"forbidden operation found: {forbidden}"
        )
        sys.exit(1)

print(
    "OK: Task 10.2.1 environment source, XDG/HOME resolver, "
    "validation, and 12 focused tests are present."
)
