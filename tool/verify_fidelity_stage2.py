#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
required_files = [
    root / 'lib/app/theme/original_theme.dart',
    root / 'lib/app/theme/theme_mode_controller.dart',
    root / 'lib/app/widgets/original_icon.dart',
    root / 'lib/core/date_time/persian_date_label.dart',
    root / 'lib/features/dashboard/presentation/widgets/finance_panel.dart',
]
checks = {
    root / 'lib/app/theme/original_design_tokens.dart': [
        'glassSaturation = 1.85',
        'fieldSaturation = 1.50',
        'referenceWindowWidth = 1180',
        'referenceWindowHeight = 780',
    ],
    root / 'lib/app/widgets/original_glass.dart': [
        '_SaturatedBackdrop',
        'ColorFilter.matrix',
    ],
    root / 'lib/app/widgets/aurora_background.dart': [
        'assets/images/original_grain.png',
        'ImageRepeat.repeat',
    ],
    root / 'lib/app/widgets/original_controls.dart': [
        'OriginalPressable',
        'AnimatedScale',
    ],
    root / 'lib/features/dashboard/presentation/dashboard_screen.dart': [
        'AnimatedPositionedDirectional',
        'tasksTabWidth',
        'financeTabWidth',
    ],
    root / 'lib/features/dashboard/presentation/widgets/tasks_panel.dart': [
        '_DesktopToolbar',
        'textDirection: TextDirection.rtl',
    ],
    root / 'pubspec.yaml': [
        'assets/images/original_grain.png',
        'Vazirmatn-Variable.ttf',
    ],
}

missing_files = [str(path.relative_to(root)) for path in required_files if not path.is_file()]
if missing_files:
    raise SystemExit(
        'Fidelity stage 2 missing required files:\n- ' + '\n- '.join(missing_files)
    )

missing_markers = []
for path, markers in checks.items():
    if not path.is_file():
        missing_markers.append(f'{path.relative_to(root)}: file missing')
        continue
    text = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in text:
            missing_markers.append(f'{path.relative_to(root)}: {marker}')

if missing_markers:
    raise SystemExit(
        'Fidelity stage 2 missing markers:\n- ' + '\n- '.join(missing_markers)
    )
print('Fidelity stage 2 contract verified.')
