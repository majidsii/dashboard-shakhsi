#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    root / 'lib/core/date_time/local_day_boundary.dart': [
        'final class LocalDayBoundary',
        'LocalDate dateFor',
        'DateTime nextBoundaryAfter',
    ],
    root / 'lib/core/notifications/notification_owner.dart': [
        'enum NotificationOwnerType',
        'final class NotificationOwner',
        'recurringTransaction',
        'dailySummary',
    ],
    root / 'lib/core/notifications/notification_request.dart': [
        'enum NotificationPrivacyMode',
        'final class NotificationRequest',
        'Map<String, String>.unmodifiable',
        '_requireUtc',
    ],
    root / 'lib/core/notifications/notification_scheduler.dart': [
        'abstract interface class NotificationScheduler',
        'Future<void> schedule',
        'Future<void> cancelByOwner',
        'Future<void> reconcile',
    ],
    root / 'test/support/fake_notification_scheduler.dart': [
        'final class FakeNotificationScheduler',
        '_requests.removeWhere',
        '_requests[request.scheduleId] = request',
    ],
}

for path, markers in checks.items():
    if not path.is_file():
        raise SystemExit(f'Missing GREEN file: {path.relative_to(root)}')
    source = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in source:
            raise SystemExit(
                f'Missing marker {marker!r} in {path.relative_to(root)}'
            )

for path in (
    root / 'test/core/date_time/local_day_boundary_test.dart',
    root / 'test/core/notifications/notification_request_test.dart',
):
    source = path.read_text(encoding='utf-8')
    if '() => const LocalDayBoundary' in source:
        raise SystemExit('Invalid const boundary test is still present.')
    if '() => const NotificationOwner' in source:
        raise SystemExit('Invalid const owner test is still present.')

print('Phase 1 Task 1 GREEN contract verified.')
