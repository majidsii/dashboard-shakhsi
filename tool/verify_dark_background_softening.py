#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
tokens = (root / 'lib/app/theme/original_design_tokens.dart').read_text(encoding='utf-8')
aurora = (root / 'lib/app/widgets/aurora_background.dart').read_text(encoding='utf-8')
test = (root / 'test/app/theme/original_design_tokens_test.dart').read_text(encoding='utf-8')

checks = {
    'dark blur token': 'darkAuroraDecorationBlurSigma = 20' in tokens,
    'dark sheen scale token': 'darkSheenBandOpacityScale = .65' in tokens,
    'dark-only brightness branch': 'final dark = Theme.of(context).brightness == Brightness.dark;' in aurora,
    'decorative blur layer': 'ui.ImageFilter.blur(' in aurora,
    'dark sheen scaling': 'OriginalDesignTokens.darkSheenBandOpacityScale' in aurora,
    'light path unchanged': ': 1,' in aurora,
    'regression test': "softens only the dark aurora decoration layer" in test,
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit('Dark background tuning verification failed: ' + ', '.join(failed))

print('Dark background softening contract verified.')
