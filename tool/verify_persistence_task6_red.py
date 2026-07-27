#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
test_file = (
    root / "test/core/providers/persistence_providers_test.dart"
)

if not test_file.is_file():
    raise SystemExit(f"Missing Task 6 RED test: {test_file}")

source = test_file.read_text(encoding="utf-8")
markers = [
    "appDatabaseProvider.overrideWithValue(database)",
    "repository providers use the overridden database",
    "taskItemsProvider emits persisted tasks",
    "financeTransactionsProvider emits repository data",
    "debt and installment providers emit live values",
    "financeReportServiceProvider is stable per container",
    "ProviderListenable<AsyncValue<T>>",
    "DriftTaskRepository",
    "DriftFinanceRepository",
]

missing = [marker for marker in markers if marker not in source]
if missing:
    raise SystemExit(
        "Missing Task 6 RED markers: " + ", ".join(missing)
    )

print("Persistence Task 6 RED tests contract verified.")
