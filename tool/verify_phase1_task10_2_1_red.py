#!/usr/bin/env python3
from pathlib import Path
import sys

test_path = Path(
    "test/core/notifications/"
    "linux_systemd_user_unit_path_resolver_test.dart"
)
production_paths = [
    Path("lib/core/notifications/linux_systemd_environment.dart"),
    Path(
        "lib/core/notifications/"
        "linux_systemd_user_unit_path_resolver.dart"
    ),
]

if not test_path.exists():
    print(f"ERROR: missing Task 10.2.1 RED test: {test_path}")
    sys.exit(1)

existing = [str(path) for path in production_paths if path.exists()]
if existing:
    print(
        "ERROR: RED expects Task 10.2.1 production files to be absent, "
        f"but found: {', '.join(existing)}"
    )
    sys.exit(1)

text = test_path.read_text(encoding="utf-8")
required = [
    "prefers non-empty XDG_CONFIG_HOME",
    "falls back to HOME dot config",
    "treats whitespace-only XDG_CONFIG_HOME as missing",
    "removes trailing slashes before appending suffix",
    "rejects missing configuration bases",
    "rejects a defined relative XDG_CONFIG_HOME",
    "rejects control characters in a configuration base",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.2.1 RED coverage is incomplete: {missing}")
    sys.exit(1)

if text.count("test(") != 12:
    print(
        "ERROR: expected exactly 12 Task 10.2.1 tests, "
        f"found {text.count('test(')}."
    )
    sys.exit(1)

print(
    "OK: Task 10.2.1 RED tests are installed and the environment "
    "and resolver production files are intentionally absent."
)
