#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

required_tests = {
    'test/core/database/notification_schedule_migration_test.dart': [
        'version one migrates to two without losing task data',
        'notification_schedules',
    ],
    'test/core/notifications/drift_notification_schedule_repository_test.dart': [
        'upsert round-trips a request and preserves created time',
        'replaceAll removes stale rows and is idempotent',
    ],
    'test/core/providers/notification_persistence_providers_test.dart': [
        'notificationScheduleRepositoryProvider',
        'notificationSchedulesProvider',
    ],
}

for relative, markers in required_tests.items():
    path = root / relative
    if not path.is_file():
        raise SystemExit(f'Missing RED test: {relative}')
    source = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in source:
            raise SystemExit(f'Missing RED marker {marker!r} in {relative}')

database_test = (
    root / 'test/core/database/app_database_test.dart'
).read_text(encoding='utf-8')
if 'expect(database.schemaVersion, 2);' not in database_test:
    raise SystemExit('Database schema RED expectation was not updated to 2.')
if "'notification_schedules'" not in database_test:
    raise SystemExit('Notification table RED expectation is missing.')

print('Phase 1 Task 2 RED contract verified.')
