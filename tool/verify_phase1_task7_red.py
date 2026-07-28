#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'test/core/notifications/notification_host_platform_test.dart': [
        'web always maps to unsupported',
        'iOS and Fuchsia fail closed',
    ],
    'test/core/notifications/notification_startup_service_test.dart': [
        'initializes plugin before reconcile and runs only once',
        'failed reconcile can be retried',
        'disabled startup does not initialize',
    ],
    'test/core/providers/notification_runtime_providers_test.dart': [
        'notificationHostPlatformProvider',
        'notificationStartupProvider',
        'PlatformNotificationScheduler',
    ],
    'test/app/bootstrap/notification_bootstrap_test.dart': [
        'initializeNotificationsForApp',
        'NotificationStartup',
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

print('Phase 1 Task 7 RED contract verified.')
