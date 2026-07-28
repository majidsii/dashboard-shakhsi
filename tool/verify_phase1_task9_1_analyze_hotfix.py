#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path("lib/core/notifications/notification_route_intent.dart")
if not path.is_file():
    print(f"ERROR: missing {path}")
    sys.exit(1)

text = path.read_text(encoding="utf-8")
classes = [
    "NotificationTaskRouteIntent",
    "NotificationHabitRouteIntent",
    "NotificationChallengeRouteIntent",
    "NotificationGoalRouteIntent",
    "NotificationDebtRouteIntent",
    "NotificationInstallmentRouteIntent",
    "NotificationTransactionRouteIntent",
]

missing = []
for class_name in classes:
    expected = f"const {class_name}(super.entityId);"
    if expected not in text:
        missing.append(expected)

legacy_fragments = [
    ": super(taskId)",
    ": super(habitId)",
    ": super(challengeId)",
    ": super(goalId)",
    ": super(debtId)",
    ": super(installmentId)",
    ": super(transactionId)",
]
legacy = [fragment for fragment in legacy_fragments if fragment in text]

if missing or legacy:
    if missing:
        print("ERROR: missing super-parameter constructors:")
        for item in missing:
            print(f"  - {item}")
    if legacy:
        print("ERROR: legacy forwarding constructors remain:")
        for item in legacy:
            print(f"  - {item}")
    sys.exit(1)

print("OK: all entity route intents use positional super parameters.")
