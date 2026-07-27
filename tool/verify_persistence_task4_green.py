#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
repo = root / 'lib/features/finance/data/drift_finance_repository.dart'
test = root / 'test/features/finance/data/drift_finance_repository_test.dart'
for path in (repo, test):
    if not path.is_file(): raise SystemExit(f'Missing Task 4 GREEN file: {path}')
source = repo.read_text(encoding='utf-8')
markers = [
    'final class DriftFinanceRepository implements FinanceRepository',
    'Stream<List<FinanceTransaction>> watchTransactions()',
    'Stream<List<Debt>> watchDebts()',
    'leftOuterJoin(',
    'List<Debt> _mapDebtJoinRows(List<TypedResult> rows)',
    'Future<void> recordDebtPayment({',
    'مبلغ پرداخت از مانده بدهی بیشتر است.',
    'Future<void> payNextInstallment({',
    'همه اقساط این برنامه پرداخت شده‌اند.',
    '_database.transaction(() async',
    'FinanceTransactionType _transactionType(String value)',
    'نوع تراکنش ذخیره‌شده نامعتبر است.',
]
missing = [m for m in markers if m not in source]
if missing: raise SystemExit('Missing Task 4 GREEN markers: ' + ', '.join(missing))
if '<dynamic>' in test.read_text(encoding='utf-8'):
    raise SystemExit('Loose dynamic ordering remains in Task 4 test.')
print('Persistence Task 4 GREEN source contract verified.')
