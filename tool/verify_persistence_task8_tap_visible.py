#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / "test/features/dashboard/finance_panel_persistence_test.dart"
source = path.read_text(encoding="utf-8")

required = [
    "Future<void> tapVisible(",
    "await tester.ensureVisible(target);",
    "finance-type-income",
    "finance-type-debt",
    "finance-type-installment",
]
for marker in required:
    if marker not in source:
        raise SystemExit(f"Missing marker: {marker}")

for key in (
    "finance-type-income",
    "finance-type-debt",
    "finance-type-installment",
):
    key_pos = source.index(key)
    window = source[max(0, key_pos - 180):key_pos + 180]
    if "await tapVisible(" not in window:
        raise SystemExit(f"{key} is not tapped through tapVisible")

print("Task 8 visible-control hotfix verified.")
