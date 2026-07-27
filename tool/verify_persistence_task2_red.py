#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TASK_TEST = ROOT / 'test/features/tasks/domain/task_item_test.dart'
FINANCE_TEST = ROOT / 'test/features/finance/domain/finance_domain_test.dart'

checks = {
    TASK_TEST: [
        "task trims its title",
        "task rejects an empty title",
        "copyWith can complete and reopen a task",
    ],
    FINANCE_TEST: [
        "transaction rejects a zero amount",
        "debt exposes an exact remaining amount",
        "installment plan calculates exact remaining value",
        "12345678901",
    ],
}

for path, markers in checks.items():
    if not path.is_file():
        raise SystemExit(f'Missing Task 2 RED test file: {path.relative_to(ROOT)}')
    source = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in source:
            raise SystemExit(
                f'Missing marker {marker!r} in {path.relative_to(ROOT)}'
            )

print('Persistence Task 2 RED tests contract verified.')
