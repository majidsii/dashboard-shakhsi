#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TASKS = ROOT / 'lib/features/dashboard/presentation/widgets/tasks_panel.dart'
TEST = ROOT / 'test/features/dashboard/tasks_panel_test.dart'

required_files = [TASKS, TEST]
missing = [str(path.relative_to(ROOT)) for path in required_files if not path.is_file() or path.stat().st_size == 0]
if missing:
    raise SystemExit('Missing stage-3 files:\n- ' + '\n- '.join(missing))

source = TASKS.read_text(encoding='utf-8')
markers = {
    'active-before-done ordering': 'if (a.done != b.done) return a.done ? 1 : -1;',
    'Persian row numbering': "ValueKey<String>('task-number-$index')",
    'priority cycling': 'entry.$2.priority = (entry.$2.priority + 1) % 4',
    'inline edit action': "semanticLabel: 'ویرایش کار'",
    'delete action': "semanticLabel: 'حذف کار'",
    'version-one footer copy': "فعال · ${_fa(doneCount)} انجام‌شده",
    'version-one empty copy': 'هنوز کاری اضافه نکرده‌اید',
    'row backdrop blur': 'blurSigma: OriginalDesignTokens.rowBlurSigma',
    'row backdrop saturation': 'saturation: OriginalDesignTokens.rowSaturation',
    'animated removal': 'Duration(milliseconds: 250)',
}

missing_markers = [name for name, marker in markers.items() if marker not in source]
if missing_markers:
    raise SystemExit('Missing task fidelity markers:\n- ' + '\n- '.join(missing_markers))

if 'Material(' in source or 'InkWell(' in source:
    raise SystemExit('Task panel reintroduced Material/Ink ripple controls.')

print('Task fidelity stage 3 contract verified.')
