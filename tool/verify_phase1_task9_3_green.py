#!/usr/bin/env python3
from pathlib import Path

TEST = Path("test/core/notifications/notification_response_source_test.dart")
PRODUCTION = Path("lib/core/notifications/notification_response_source.dart")

for path in (TEST, PRODUCTION):
    if not path.is_file():
        raise SystemExit(f"missing required file: {path}")

text = PRODUCTION.read_text(encoding="utf-8")
required = [
    "final class NotificationResponseSource",
    "StreamController<String?>.broadcast(sync: true)",
    "void publishRuntimePayload(String? rawPayload)",
    "final class NotificationLaunchDetails",
    "final class NotificationColdStartGateway",
    "Future<String?> takeInitialPayload()",
    "_operationTail = _operationTail.then",
    "_consumed = true",
    "result.completeError(error, stackTrace)",
]
missing = [token for token in required if token not in text]
if missing:
    raise SystemExit(f"GREEN implementation is missing required behavior: {missing}")

details_index = text.index("final details = await _loadDetails();")
consumed_index = text.index("_consumed = true", details_index)
complete_index = text.index("result.complete(", details_index)
if consumed_index > complete_index:
    raise SystemExit("launch details must be consumed before returning the payload")

print("OK: Task 9.3 GREEN runtime source and cold-start gateway are present.")
