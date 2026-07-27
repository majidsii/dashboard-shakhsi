#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
provider_file = (
    root / "lib/core/providers/persistence_providers.dart"
)

if not provider_file.is_file():
    raise SystemExit(
        f"Missing Task 6 GREEN provider file: {provider_file}"
    )

source = provider_file.read_text(encoding="utf-8")
markers = [
    "final appDatabaseProvider = Provider<AppDatabase>",
    "ref.onDispose(database.close)",
    "final taskRepositoryProvider = Provider<TaskRepository>",
    "DriftTaskRepository(",
    "final financeRepositoryProvider = Provider<FinanceRepository>",
    "DriftFinanceRepository(",
    "final taskItemsProvider = StreamProvider<List<TaskItem>>",
    "financeTransactionsProvider",
    "StreamProvider<List<FinanceTransaction>>",
    "final debtsProvider = StreamProvider<List<Debt>>",
    "installmentPlansProvider",
    "StreamProvider<List<InstallmentPlan>>",
    "financeReportServiceProvider",
    "Provider<FinanceReportService>",
]

missing = [marker for marker in markers if marker not in source]
if missing:
    raise SystemExit(
        "Missing Task 6 GREEN markers: " + ", ".join(missing)
    )

print("Persistence Task 6 GREEN source contract verified.")
