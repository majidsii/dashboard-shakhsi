#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = (
    root
    / "lib/features/dashboard/presentation/widgets/"
    "finance_panel.dart"
)
source = path.read_text(encoding="utf-8")

start = source.find("final class _FinanceCard")
end = source.find(
    "final class _FinanceSegmentedControl",
    start,
)
if start == -1 or end == -1:
    raise SystemExit("_FinanceCard source range was not found.")

block = source[start:end]
required = [
    "Flexible(",
    "child: Text(",
    "maxLines: 1",
    "overflow: TextOverflow.ellipsis",
]
missing = [marker for marker in required if marker not in block]
if missing:
    raise SystemExit(
        "Missing finance header markers: " + ", ".join(missing)
    )

print("Task 9 finance header overflow hotfix verified.")
