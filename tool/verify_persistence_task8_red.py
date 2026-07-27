#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
test_path = (
    root
    / "test/features/dashboard/"
    "finance_panel_persistence_test.dart"
)

if not test_path.is_file():
    raise SystemExit(
        f"Missing Task 8 RED test: {test_path}"
    )

source = test_path.read_text(encoding="utf-8")

required = [
    "financeRepositoryProvider.overrideWithValue(repository)",
    "repository stream updates cards objects and recent transactions exactly",
    "finance forms write exact transactions debts and installments",
    "payment and delete controls call the finance repository",
    "123456712345678",
    "1000000000000001",
    "final class _MemoryFinanceRepository implements FinanceRepository",
]

missing = [marker for marker in required if marker not in source]
if missing:
    raise SystemExit(
        "Missing Task 8 RED markers: " + ", ".join(missing)
    )

production_files = [
    root
    / "lib/features/dashboard/presentation/widgets/"
    "finance_panel.dart",
]

for production_file in production_files:
    if not production_file.is_file():
        raise SystemExit(
            f"Expected existing production file is missing: "
            f"{production_file}"
        )

print("Persistence Task 8 RED contract verified.")
