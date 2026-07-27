#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
checks = {
    root / 'lib/app/widgets/original_controls.dart': [
        'excludeSemantics: widget.semanticLabel != null',
    ],
    root / 'lib/features/dashboard/presentation/widgets/tasks_panel.dart': [
        'final opacity = value.clamp(0.0, 1.0).toDouble();',
        'Opacity(opacity: opacity, child: child)',
    ],
    root / 'lib/features/dashboard/presentation/dashboard_screen.dart': [
        'fit: BoxFit.scaleDown',
        'mainAxisSize: MainAxisSize.min',
    ],
    root / 'lib/features/dashboard/presentation/widgets/finance_panel.dart': [
        'alignment: AlignmentDirectional.centerStart',
        'maxLines: 1',
    ],
}

missing = []
for path, markers in checks.items():
    if not path.is_file():
        missing.append(f'missing file: {path.relative_to(root)}')
        continue
    text = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in text:
            missing.append(f'{path.relative_to(root)} missing marker: {marker}')

if missing:
    raise SystemExit('\n'.join(missing))

print('Stage 5 test hotfix contract verified.')
