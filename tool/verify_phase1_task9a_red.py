#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'test/core/notifications/notification_route_parser_test.dart': [
        'allow-listed task route becomes a typed task intent',
        'missing route falls back to the notification owner',
        'query fragments and extra path segments are rejected',
        'unsupported payload version is distinguished safely',
    ],
}

for relative, markers in checks.items():
    path = root / relative
    if not path.is_file():
        raise SystemExit(f'Missing RED file: {relative}')
    source = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in source:
            raise SystemExit(
                f'Missing RED marker {marker!r} in {relative}'
            )

print('Phase 1 Task 9A RED contract verified.')
