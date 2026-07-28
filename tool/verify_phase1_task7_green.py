#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'lib/core/notifications/notification_host_platform.dart': [
        'detectNotificationHostPlatform',
        'TargetPlatform.iOS',
        'NotificationHostPlatform.unsupported',
    ],
    'lib/core/notifications/notification_startup_service.dart': [
        'abstract interface class NotificationStartup',
        'final class NotificationStartupService',
        'await _initializer.initialize();',
        'await _coordinator.reconcileFromPersistence();',
        '_initialization = null',
    ],
    'lib/core/providers/persistence_providers.dart': [
        'notificationHostPlatformProvider',
        'notificationPlatformCapabilitiesProvider',
        'localNotificationsDriverProvider',
        'nativeNotificationGatewayProvider',
        'notificationStartupProvider',
        'PlatformNotificationScheduler',
    ],
    'lib/app/bootstrap/app_bootstrap.dart': [
        'initializeNotificationsForApp',
        'UncontrolledProviderScope',
        'while initializing local notifications',
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

print('Phase 1 Task 7 GREEN contract verified.')
