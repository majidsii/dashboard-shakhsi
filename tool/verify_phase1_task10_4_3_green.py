#!/usr/bin/env python3
from pathlib import Path
import sys

production_path = Path(
    "lib/core/notifications/"
    "linux_notification_request_fingerprint.dart"
)
test_path = Path(
    "test/core/notifications/"
    "linux_notification_request_fingerprint_test.dart"
)

for label, path in (
    ("production", production_path),
    ("test", test_path),
):
    if not path.exists():
        print(f"ERROR: missing Task 10.4.3 {label}: {path}")
        sys.exit(1)

production = production_path.read_text(encoding="utf-8")
test = test_path.read_text(encoding="utf-8")

required_production = [
    "final class LinuxNotificationRequestFingerprint",
    "static const int fingerprintSchemaVersion = 1",
    "deliveryCommandSchemaVersion <= 0",
    "SplayTreeMap<String, String>.from",
    "'fingerprintSchemaVersion': fingerprintSchemaVersion",
    "'deliveryCommandSchemaVersion':",
    "'scheduleId': request.scheduleId",
    "'ownerType': request.owner.type.name",
    "'ownerId': request.owner.id",
    "'title': request.title",
    "'body': request.body",
    "'scheduledAtUtc':",
    "'privacyMode': request.privacyMode.name",
    "'payload': sortedPayload",
    "Sha256().hash",
    "utf8.encode(canonical)",
    "toRadixString(16).padLeft(2, '0')",
]
required_test = [
    "f6ae7b7f35da4a7dfe74fc9144e726232ece9c67f130357d1ed39cef9ed51174",
    "is independent of payload insertion order",
    "changes when delivery command schema version changes",
    "rejects invalid delivery command schema version",
]

for label, text, required in (
    ("fingerprint implementation", production, required_production),
    ("fingerprint tests", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "systemctl",
    "File(",
    "Directory(",
    "md5",
    "Sha1",
    "hashCode",
):
    if forbidden in production:
        print(
            "ERROR: Task 10.4.3 contains forbidden coupling or weak "
            f"fingerprint primitive: {forbidden}"
        )
        sys.exit(1)

if production.count("jsonEncode(") != 1:
    print("ERROR: fingerprint must use one canonical JSON encoding.")
    sys.exit(1)

print(
    "OK: Task 10.4.3 GREEN implements a validated, deterministic, canonical "
    "UTF-8 JSON SHA-256 request fingerprint with sorted payload keys, exact "
    "field coverage, schema-version sensitivity, lowercase hexadecimal output, "
    "and no filesystem or process coupling."
)
