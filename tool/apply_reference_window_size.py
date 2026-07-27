#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
runner = root / 'linux' / 'runner' / 'my_application.cc'
if not runner.exists():
    raise SystemExit(f'Linux runner not found: {runner}. Run the native bootstrap first.')
text = runner.read_text(encoding='utf-8')
pattern = r'gtk_window_set_default_size\(window,\s*\d+,\s*\d+\);'
replacement = 'gtk_window_set_default_size(window, 1180, 780);'
updated, count = re.subn(pattern, replacement, text, count=1)
if count != 1:
    raise SystemExit('Could not find gtk_window_set_default_size in Linux runner.')
runner.write_text(updated, encoding='utf-8')
print('Linux reference window size set to 1180 x 780.')
