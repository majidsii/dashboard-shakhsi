#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(
    "test/core/notifications/notification_routing_providers_test.dart"
)

if not path.exists():
    print(f"ERROR: missing {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")

required = [
    "await Future<void>.delayed(Duration.zero);",
    "late StateSetter rebuildBootstrap;",
    "final loader = () async {",
    "child: StatefulBuilder(",
    "rebuildBootstrap(() {",
    "generation += 1;",
]
missing = [token for token in required if token not in text]
if missing:
    print(f"ERROR: Task 9.5 deterministic test hotfix is incomplete: {missing}")
    sys.exit(1)

if text.count("testWidgets('starts routing once for repeated widget rebuilds'") != 1:
    print("ERROR: expected exactly one repeated-rebuild test.")
    sys.exit(1)

print(
    "OK: Task 9.5 tests now wait for FutureProvider startup and "
    "rebuild inside one stable ProviderScope."
)
