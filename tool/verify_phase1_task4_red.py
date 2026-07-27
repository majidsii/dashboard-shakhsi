#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'test/core/notifications/stable_notification_id_test.dart': [
        'StableNotificationId.fromScheduleId',
        'positive 31-bit id',
    ],
    'test/core/notifications/notification_payload_codec_test.dart': [
        'NotificationPayloadCodec.encode',
        'NotificationPayloadCodec.decode',
        'deterministic regardless of payload insertion order',
    ],
    'test/core/notifications/notification_delivery_policy_test.dart': [
        'NotificationDeliveryPolicy.contentFor',
        'private mode hides sensitive title and body',
    ],
    'test/core/notifications/notification_platform_capabilities_test.dart': [
        'NotificationHostPlatform.linux',
        'supportsScheduledDelivery',
        'unsupported platforms fail closed',
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

print('Phase 1 Task 4 RED contract verified.')
