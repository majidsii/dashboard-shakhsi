#!/usr/bin/env python3
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
db = (ROOT / 'lib/core/database/app_database.dart').read_text(encoding='utf-8')
test = (ROOT / 'test/core/database/app_database_test.dart').read_text(encoding='utf-8')
for bad in ('priority.isBetweenValues', 'type.isIn', 'installmentCount.isBiggerThanValue'):
    if bad in db:
        raise SystemExit(f'Recursive Drift getter remains: {bad}')
for marker in (
    'CHECK (priority BETWEEN 0 AND 3)',
    "CHECK (type IN ('income', 'expense'))",
    'CHECK (installment_count > 0)',
):
    if marker not in db:
        raise SystemExit(f'Missing constraint: {marker}')
if test.count("currencyCode: const Value('IRT')") != 2:
    raise SystemExit('Expected two explicit Value<String> wrappers.')
if test.count('scale: const Value(8)') != 2:
    raise SystemExit('Expected two explicit Value<int> wrappers.')
print('Persistence Task 1 analyzer hotfix contract verified.')
