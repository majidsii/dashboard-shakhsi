#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'test/core/notifications/notification_permission_service_test.dart': [
        'test notification is blocked while permission is denied',
        'NotificationPermissionService.testScheduleId',
    ],
    'test/core/notifications/flutter_notification_permission_mapping_test.dart': [
        'notificationPermissionStatusFromNullableBool',
        'allowsDelivery',
    ],
    'test/core/providers/notification_permission_providers_test.dart': [
        'notificationPermissionGatewayProvider',
        'notificationPermissionHealthProvider',
    ],
    'test/support/fake_notification_permission_gateway.dart': [
        'final class FakeNotificationPermissionGateway',
        'requestCallCount',
    ],
}

for relative, markers in checks.items():
    path = root / relative
    if not path.is_file():
        raise SystemExit(f'Missing RED file: {relative}')
    source = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in source:
            raise SystemExit(f'Missing RED marker {marker!r} in {relative}')

print('Phase 1 Task 8 RED contract verified.')
