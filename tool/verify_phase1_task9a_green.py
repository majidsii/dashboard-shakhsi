#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]

checks = {
    'lib/core/notifications/notification_route_intent.dart': [
        'sealed class NotificationRouteIntent',
        'NotificationTaskRouteIntent',
        'NotificationSectionRouteIntent',
        'NotificationRouteParseIgnored',
        'deduplicationKey',
    ],
    'lib/core/notifications/notification_route_parser.dart': [
        'final class NotificationRouteParser',
        '_validatePayloadVersion',
        '_fromAllowListedRoute',
        '_fromOwner',
        'unsupportedDestination',
    ],
    'test/core/notifications/notification_route_parser_test.dart': [
        'allow-listed task route becomes a typed task intent',
        'unsupported payload version is distinguished safely',
    ],
}

for relative, markers in checks.items():
    path = root / relative
    if not path.is_file():
        raise SystemExit(f'Missing GREEN file: {relative}')
    source = path.read_text(encoding='utf-8')
    for marker in markers:
        if marker not in source:
            raise SystemExit(
                f'Missing GREEN marker {marker!r} in {relative}'
            )

print('Phase 1 Task 9A GREEN contract verified.')
