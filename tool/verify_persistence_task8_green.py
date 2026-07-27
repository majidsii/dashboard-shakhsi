#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
panel = root / 'lib/features/dashboard/presentation/widgets/finance_panel.dart'
persistence_test = root / 'test/features/dashboard/finance_panel_persistence_test.dart'
legacy_test = root / 'test/features/dashboard/finance_panel_test.dart'
repo_helper = root / 'test/support/memory_finance_repository.dart'
dashboard_test = root / 'test/features/dashboard/original_dashboard_screen_test.dart'

for path in [panel, persistence_test, legacy_test, repo_helper, dashboard_test]:
    if not path.is_file():
        raise SystemExit(f'Missing Task 8 GREEN file: {path}')

source = panel.read_text(encoding='utf-8')
required = [
    'final class FinancePanel extends ConsumerStatefulWidget',
    'ref.watch(financeTransactionsProvider)',
    'ref.watch(debtsProvider)',
    'ref.watch(installmentPlansProvider)',
    'ref.watch(financeReportServiceProvider)',
    'ref.read(financeRepositoryProvider).recordDebtPayment',
    '.payNextInstallment(',
    '.deleteTransaction(',
    '.deleteDebt(',
    '.deleteInstallmentPlan(',
    'FinanceTransaction.create(',
    'Debt(',
    'InstallmentPlan(',
    'static const IdGenerator _idGenerator = UuidV7IdGenerator();',
]
forbidden = [
    'final List<FinancePreviewTransaction> _transactions',
    'final List<FinancePreviewDebt> _debts',
    'final List<FinancePreviewInstallment> _installments',
    'int _nextId',
    'debt.paid =',
    'installment.paidCount +=',
]
missing = [marker for marker in required if marker not in source]
present = [marker for marker in forbidden if marker in source]
if missing:
    raise SystemExit('Missing Task 8 GREEN markers: ' + ', '.join(missing))
if present:
    raise SystemExit('Local finance state still present: ' + ', '.join(present))

helper_source = repo_helper.read_text(encoding='utf-8')
if 'implements FinanceRepository' not in helper_source:
    raise SystemExit('Deterministic finance repository helper is incomplete.')

for test_path in [persistence_test, legacy_test]:
    test_source = test_path.read_text(encoding='utf-8')
    if 'financeRepositoryProvider.overrideWithValue(repository)' not in test_source:
        raise SystemExit(f'Finance repository override missing in {test_path}')
    if 'pumpAndSettle' in test_source:
        raise SystemExit(f'Unbounded pumpAndSettle remains in {test_path}')

if 'appDatabaseProvider.overrideWithValue(database)' not in dashboard_test.read_text(encoding='utf-8'):
    raise SystemExit('Dashboard screen test does not isolate the database.')

print('Persistence Task 8 GREEN source contract verified.')
