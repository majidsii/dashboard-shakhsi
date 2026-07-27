#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'lib/core/notifications/stable_notification_id.dart': [
        'final class StableNotificationId',
        '0x811c9dc5',
        '0x7fffffff',
    ],
    'lib/core/notifications/notification_payload_codec.dart': [
        'final class NotificationPayloadCodec',
        "'version': _version",
        'NotificationOwnerType.values.byName',
        'Map<String, String>.unmodifiable',
    ],
    'lib/core/notifications/notification_delivery_policy.dart': [
        'final class NotificationDeliveryPolicy',
        'NotificationPrivacyMode.private',
        'یک یادآور جدید دارید.',
    ],
    'lib/core/notifications/notification_platform_capabilities.dart': [
        'enum NotificationHostPlatform',
        'NotificationHostPlatform.linux',
        'supportsScheduledDelivery: false',
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

print('Phase 1 Task 4 GREEN contract verified.')
