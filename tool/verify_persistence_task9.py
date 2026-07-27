#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
test_path = root / "test/core/database/database_restart_test.dart"

if not test_path.is_file():
    raise SystemExit(f"Missing Task 9 restart test: {test_path}")

source = test_path.read_text(encoding="utf-8")
required = [
    "NativeDatabase(file)",
    "await first.close();",
    "final second = AppDatabase",
    "DriftTaskRepository",
    "DriftFinanceRepository",
    "123456712345678",
    "350000000000002",
    "reopenedPlans.single.paidCount, 2",
    "PRAGMA user_version",
]
for marker in required:
    if marker not in source:
        raise SystemExit(f"Missing Task 9 marker: {marker}")

for forbidden in (
    "TaskRowsCompanion",
    "FinanceTransactionRowsCompanion",
    "DebtRowsCompanion",
    "InstallmentPlanRowsCompanion",
):
    if forbidden in source:
        raise SystemExit(
            "Restart test must use public repository APIs, "
            f"but found {forbidden}"
        )

print("Persistence Task 9 verification contract verified.")
