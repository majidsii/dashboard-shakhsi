#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'lib/core/notifications/notification_permission.dart': [
        'enum NotificationPermissionStatus',
        'NotificationPermissionGateway',
        'NotificationPermissionHealth',
        'allowsDelivery',
    ],
    'lib/core/notifications/notification_permission_service.dart': [
        'final class NotificationPermissionService',
        'NotificationTestResult',
        'sendTestNotification',
        'system-test-notification',
    ],
    'lib/core/notifications/flutter_local_notifications_driver.dart': [
        'NotificationPermissionGateway',
        'requestNotificationsPermission',
        'checkPermissions',
        'NotificationHostPlatform.windows',
    ],
    'lib/core/providers/persistence_providers.dart': [
        'notificationPermissionGatewayProvider',
        'notificationPermissionServiceProvider',
        'notificationPermissionHealthProvider',
        'hostPlatform: ref.watch(notificationHostPlatformProvider)',
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

print('Phase 1 Task 8 GREEN contract verified.')
