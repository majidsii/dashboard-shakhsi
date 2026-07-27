#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
checks = {
    root / 'test/core/date_time/local_day_boundary_test.dart': [
        'maps an instant before the boundary to the previous date',
        'returns the next boundary strictly after the instant',
        'rejects an invalid local start time',
    ],
    root / 'test/core/notifications/notification_request_test.dart': [
        'keeps an immutable UTC schedule',
        'rejects a non-UTC instant',
        'identifiers and title cannot be blank',
    ],
    root / 'test/core/notifications/fake_notification_scheduler_test.dart': [
        'replaces an existing request with the same schedule id',
        'cancelByOwner removes only requests belonging to that owner',
        'reconcile removes stale requests and is idempotent',
    ],
}

for path, markers in checks.items():
    if not path.is_file():
        raise SystemExit(f'Missing RED test: {path.relative_to(root)}')
    source = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in source:
            raise SystemExit(
                f'Missing marker {marker!r} in {path.relative_to(root)}'
            )

production_paths = [
    root / 'lib/core/date_time/local_day_boundary.dart',
    root / 'lib/core/notifications/notification_owner.dart',
    root / 'lib/core/notifications/notification_request.dart',
    root / 'lib/core/notifications/notification_scheduler.dart',
    root / 'test/support/fake_notification_scheduler.dart',
]
for path in production_paths:
    if path.exists():
        raise SystemExit(
            'RED package must not include implementation yet: '
            f'{path.relative_to(root)}'
        )

print('Phase 1 Task 1 RED contract verified.')
