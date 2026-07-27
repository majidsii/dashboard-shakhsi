#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'lib/core/database/app_database.dart': [
        'class NotificationScheduleRows extends Table',
        "String get tableName => 'notification_schedules'",
        'int get schemaVersion => 2',
        'if (from < 2)',
        'migrator.createTable(notificationScheduleRows)',
    ],
    'lib/core/notifications/notification_schedule_repository.dart': [
        'abstract interface class NotificationScheduleRepository',
        'Future<void> replaceAll',
    ],
    'lib/core/notifications/drift_notification_schedule_repository.dart': [
        'final class DriftNotificationScheduleRepository',
        'insertOnConflictUpdate',
        'deleteByOwner',
        'jsonEncode',
        'jsonDecode',
    ],
    'lib/core/providers/persistence_providers.dart': [
        'appClockProvider',
        'notificationScheduleRepositoryProvider',
        'notificationSchedulesProvider',
    ],
    'lib/core/database/app_database.g.dart': [
        'class $NotificationScheduleRowsTable',
        "static const String $name = 'notification_schedules'",
    ],
}

for relative, markers in checks.items():
    path = root / relative
    if not path.is_file():
        raise SystemExit(f'Missing GREEN file: {relative}')
    source = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in source:
            raise SystemExit(f'Missing GREEN marker {marker!r} in {relative}')

print('Phase 1 Task 2 GREEN contract verified.')
