#!/usr/bin/env python3
from pathlib import Path

path = Path('lib/core/notifications/notification_routing_startup_service.dart')
if not path.exists():
    raise SystemExit(f'ERROR: missing {path}')

text = path.read_text(encoding='utf-8')
required = [
    'factory NotificationRoutingStartupService({',
    'NotificationRoutingStartupService._(',
    'this._responseSource,',
    'this._coldStartGateway,',
    'this._routeParser,',
    'this._navigationQueue,',
    '// ignore: cancel_subscriptions',
    'await subscription?.cancel();',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit('ERROR: hotfix contract missing:\n- ' + '\n- '.join(missing))

for forbidden in [
    ': _responseSource = responseSource,',
    '_coldStartGateway = coldStartGateway,',
    '_routeParser = routeParser,',
    '_navigationQueue = navigationQueue;',
]:
    if forbidden in text:
        raise SystemExit(f'ERROR: legacy constructor assignment remains: {forbidden}')

print('OK: Task 9.4 analyze hotfix structure is present.')
