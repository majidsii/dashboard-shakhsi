#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
test_file = (
    root
    / "test/features/finance/data/drift_finance_repository_test.dart"
)

if not test_file.is_file():
    raise SystemExit(f"Missing RED test file: {test_file}")

source = test_file.read_text(encoding="utf-8")
required_markers = [
    "DriftFinanceRepository",
    "transactions round-trip exact eight-decimal money",
    "123456712345678",
    "watchDebts aggregates exact payment sums",
    "recordDebtPayment rejects amount above remaining debt",
    "مبلغ پرداخت از مانده بدهی بیشتر است.",
    "payNextInstallment inserts sequential payment numbers",
    "fully paid installment plan rejects another payment",
    "همه اقساط این برنامه پرداخت شده‌اند.",
    "deleting parents cascades to their payment rows",
    "SequenceIdGenerator(prefix: 'finance')",
]

missing = [marker for marker in required_markers if marker not in source]
if missing:
    raise SystemExit(
        "Missing Task 4 RED markers: " + ", ".join(missing)
    )

print("Persistence Task 4 RED tests contract verified.")
