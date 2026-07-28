#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'test/core/notifications/platform_notification_scheduler_test.dart': [
        'future request uses native scheduling with private content',
        'future Linux request remains deferred without a native call',
        'cancelByOwner cancels only matching decodable pending items',
        'Linux reconcile does not replay due notifications on startup',
    ],
    'test/support/fake_native_notification_gateway.dart': [
        'final class FakeNativeNotificationGateway',
        'Future<List<NativePendingNotification>> pending',
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

print('Phase 1 Task 6 RED contract verified.')
