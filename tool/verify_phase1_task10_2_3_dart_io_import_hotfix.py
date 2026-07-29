#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path("test/support/fake_linux_systemd_file_system.dart")

if not path.exists():
    print(f"ERROR: missing {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "import 'dart:convert';",
    "import 'dart:io';",
    "throw FileSystemException(",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 10.2.3 dart:io import hotfix is incomplete: {missing}")
    sys.exit(1)

if text.count("import 'dart:io';") != 1:
    print("ERROR: dart:io import must appear exactly once.")
    sys.exit(1)

print(
    "OK: Task 10.2.3 fake filesystem imports dart:io for "
    "FileSystemException."
)
