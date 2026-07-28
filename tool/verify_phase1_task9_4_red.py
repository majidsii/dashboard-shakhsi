from pathlib import Path

TEST = Path("test/core/notifications/notification_routing_startup_service_test.dart")
PRODUCTION = Path("lib/core/notifications/notification_routing_startup_service.dart")

if not TEST.is_file():
    raise SystemExit(f"RED verification failed: missing {TEST}")

text = TEST.read_text(encoding="utf-8")
required = [
    "NotificationRoutingStartupService",
    "parses and enqueues a valid cold-start payload",
    "registers runtime listening before loading cold-start details",
    "allows cold-start retry without duplicating runtime delivery",
    "dispose during cold-start loading prevents late navigation",
]
missing = [value for value in required if value not in text]
if missing:
    raise SystemExit(f"RED verification failed: missing test markers: {missing}")

if PRODUCTION.exists():
    raise SystemExit(
        "RED verification failed: production implementation already exists; "
        "the focused test would not prove the missing feature"
    )

print("OK: Task 9.4 RED tests are present and production code is absent.")
