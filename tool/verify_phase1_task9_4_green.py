from pathlib import Path

PRODUCTION = Path("lib/core/notifications/notification_routing_startup_service.dart")
TEST = Path("test/core/notifications/notification_routing_startup_service_test.dart")

for path in (PRODUCTION, TEST):
    if not path.is_file():
        raise SystemExit(f"GREEN verification failed: missing {path}")

text = PRODUCTION.read_text(encoding="utf-8")
required = [
    "final class NotificationRoutingStartupService",
    "NotificationResponseSource",
    "NotificationColdStartGateway",
    "NotificationRouteParser",
    "NotificationNavigationQueue",
    "_bufferedRuntimePayloads",
    "Future<void> start()",
    "Future<void> dispose()",
]
missing = [value for value in required if value not in text]
if missing:
    raise SystemExit(f"GREEN verification failed: missing implementation markers: {missing}")

if text.count("_responseSource.payloads.listen") != 1:
    raise SystemExit(
        "GREEN verification failed: runtime source should be subscribed at one controlled location"
    )

if "_routeParser.parse(rawPayload)" not in text or "_navigationQueue.enqueue(intent)" not in text:
    raise SystemExit(
        "GREEN verification failed: payloads are not connected through parser to queue"
    )

print("OK: Task 9.4 startup service connects cold-start and runtime payloads safely.")
