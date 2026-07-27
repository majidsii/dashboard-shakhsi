#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

EXPECTED = {
    "lib/features/tasks/domain/task_item.dart": [
        "final class TaskItem",
        "TaskItem copyWith",
        "priority < 0 || priority > 3",
        "clearCompletedAt",
    ],
    "lib/features/tasks/domain/task_repository.dart": [
        "abstract interface class TaskRepository",
        "Stream<List<TaskItem>> watchAll()",
        "Future<void> reorder(List<String> orderedIds)",
    ],
    "lib/features/finance/domain/finance_transaction.dart": [
        "enum FinanceTransactionType { income, expense }",
        "final class FinanceTransaction",
        "void validateExactPositiveMoney",
        "Money.financeScale",
    ],
    "lib/features/finance/domain/debt.dart": [
        "final class Debt",
        "Money get remaining => total - paid",
        "double get progressForChart",
    ],
    "lib/features/finance/domain/installment_plan.dart": [
        "final class InstallmentPlan",
        "int get remainingCount",
        "Money get remaining",
        "double get progressForChart",
    ],
    "lib/features/finance/domain/finance_repository.dart": [
        "abstract interface class FinanceRepository",
        "Future<void> recordDebtPayment",
        "Future<void> payNextInstallment",
    ],
}

for relative, markers in EXPECTED.items():
    path = ROOT / relative
    if not path.is_file():
        raise SystemExit(f"Missing Task 2 GREEN file: {relative}")
    source = path.read_text(encoding="utf-8")
    for marker in markers:
        if marker not in source:
            raise SystemExit(f"Missing marker in {relative}: {marker}")

print("Persistence Task 2 GREEN source contract verified.")
