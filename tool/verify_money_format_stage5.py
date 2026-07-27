#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
checks = {
    root / 'lib/core/money/money.dart': [
        'static const int financeScale = 8;',
        'parseMajorUnits(',
        'formatMajorUnits(',
        'Money clamp(',
    ],
    root / 'lib/core/money/money_input_formatter.dart': [
        'final class MoneyInputFormatter',
        "return groups.join('٬');",
        "..write('٫')",
    ],
    root / 'lib/app/widgets/original_controls.dart': [
        'final List<TextInputFormatter>? inputFormatters;',
        'inputFormatters: widget.inputFormatters,',
    ],
    root / 'lib/features/dashboard/presentation/widgets/finance_preview_models.dart': [
        'final Money amount;',
        'final Money balance;',
        'static Money parseAmount(String raw)',
        'static int parseCount(String raw)',
    ],
    root / 'lib/features/dashboard/presentation/widgets/finance_panel.dart': [
        'MoneyInputFormatter()',
        'TextInputType.numberWithOptions(decimal: true)',
        '.clamp(Money.zeroIRT, amount)',
    ],
    root / 'test/core/money/money_input_formatter_test.dart': [
        "'۱۲۳٬۴۵۶٬۷۸۹'",
        "'۱٬۲۳۴٫۱۲۳۴۵۶۷۸'",
    ],
}

errors = []
for path, markers in checks.items():
    if not path.is_file():
        errors.append(f'Missing file: {path.relative_to(root)}')
        continue
    text = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in text:
            errors.append(f'Missing marker in {path.relative_to(root)}: {marker}')

model_text = (root / 'lib/features/dashboard/presentation/widgets/finance_preview_models.dart').read_text(encoding='utf-8')
for forbidden in ('final int amount;', 'static int parseAmount(String raw)'):
    if forbidden in model_text:
        errors.append(f'Legacy integer money contract remains: {forbidden}')

if errors:
    print('\n'.join(errors))
    raise SystemExit(1)

print('Money format stage 5 contract verified.')
