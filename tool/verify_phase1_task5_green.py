#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'lib/core/notifications/device_time_zone_source.dart': [
        'FlutterTimezone.getLocalTimezone',
        'timezone.identifier',
    ],
    'lib/core/notifications/notification_time_zone_initializer.dart': [
        'timezone_data.initializeTimeZones',
        "const fallback = 'Etc/UTC'",
        '_initialization = null',
    ],
    'lib/core/notifications/local_notifications_initializer.dart': [
        'await _timeZoneInitializer.initialize();',
        'await _driver.initialize();',
        '_initialization = null',
    ],
    'lib/core/notifications/flutter_local_notifications_driver.dart': [
        'FlutterLocalNotificationsPlugin',
        'WindowsInitializationSettings',
        'LinuxInitializationSettings',
        'requestAlertPermission: false',
    ],
    'android/app/build.gradle.kts': [
        'isCoreLibraryDesugaringEnabled = true',
        'multiDexEnabled = true',
        'com.android.tools:desugar_jdk_libs:2.1.4',
    ],
    'android/app/src/main/AndroidManifest.xml': [
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'ScheduledNotificationReceiver',
        'ScheduledNotificationBootReceiver',
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

print('Phase 1 Task 5 GREEN contract verified.')
