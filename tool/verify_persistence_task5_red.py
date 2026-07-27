#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
test_file = (
    root
    / "test/features/finance/application/"
    "finance_report_service_test.dart"
)

if not test_file.is_file():
    raise SystemExit(f"Missing Task 5 RED test: {test_file}")

source = test_file.read_text(encoding="utf-8")
required_markers = [
    "FinanceReportService",
    "summary preserves exact eight-decimal values",
    "'0.30000003'",
    "summary separates the current Jalali month",
    "trend returns six chronological Jalali month points",
    "categories aggregate expenses and sort descending",
    "week returns seven local days and ignores income",
    "Money.zeroIRT",
    "Jalali.fromDateTime",
]

missing = [marker for marker in required_markers if marker not in source]
if missing:
    raise SystemExit(
        "Missing Task 5 RED markers: " + ", ".join(missing)
    )

print("Persistence Task 5 RED tests contract verified.")
