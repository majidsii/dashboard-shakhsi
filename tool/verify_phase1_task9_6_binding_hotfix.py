#!/usr/bin/env python3
from pathlib import Path
import sys

binding_path = Path("lib/app/router/notification_router_binding.dart")
test_path = Path("test/app/router/notification_go_router_adapter_test.dart")

for path in (binding_path, test_path):
    if not path.exists():
        print(f"ERROR: missing required Task 9.6 file: {path}")
        sys.exit(1)

binding = binding_path.read_text(encoding="utf-8")
tests = test_path.read_text(encoding="utf-8")

required_binding = [
    "late final NotificationNavigationQueue _navigationQueue;",
    "_navigationQueue = ref.read(notificationNavigationQueueProvider);",
    "_navigationQueue.markRouterUnavailable();",
    "_navigationQueue.markRouterReady(",
]
missing_binding = [
    token for token in required_binding if token not in binding
]
if missing_binding:
    print(
        "ERROR: binding lifecycle hotfix is incomplete: "
        f"{missing_binding}"
    )
    sys.exit(1)

dispose_start = binding.find("void dispose()")
dispose_end = binding.find("super.dispose();", dispose_start)
if dispose_start == -1 or dispose_end == -1:
    print("ERROR: could not locate dispose() implementation.")
    sys.exit(1)

dispose_block = binding[dispose_start:dispose_end]
if "ref.read(" in dispose_block:
    print("ERROR: dispose() still accesses ref after ConsumerState disposal.")
    sys.exit(1)

required_test_tokens = [
    "pumpWidget completes the first frame and its post-frame callbacks",
    "Future entries must now use the second router.",
    "testWidgets('marks the queue unavailable when unmounted'",
]
missing_tests = [token for token in required_test_tokens if token not in tests]
if missing_tests:
    print(f"ERROR: widget lifecycle tests are incomplete: {missing_tests}")
    sys.exit(1)

drain_start = tests.find(
    "testWidgets('drains queued intents after the router first frame'"
)
drain_end = tests.find(
    "testWidgets('routes runtime queue entries while mounted'",
    drain_start,
)
drain_block = tests[drain_start:drain_end]
if "expect(queue.isRouterReady, isFalse);" in drain_block:
    print(
        "ERROR: stale pre-frame readiness assertion remains in drain test."
    )
    sys.exit(1)
if "expect(queue.isRouterReady, isTrue);" not in drain_block:
    print("ERROR: drain test no longer confirms router readiness.")
    sys.exit(1)

rebind_start = tests.find(
    "testWidgets('rebinds future navigation to a replacement router'"
)
rebind_end = tests.find(
    "testWidgets('starts the routing bootstrap without blocking its child'",
    rebind_start,
)
rebind_block = tests[rebind_start:rebind_end]
if "expect(queue.isRouterReady, isFalse);" in rebind_block:
    print(
        "ERROR: stale unavailable assertion remains after replacement pump."
    )
    sys.exit(1)
if "expect(queue.isRouterReady, isTrue);" not in rebind_block:
    print("ERROR: replacement test no longer confirms router readiness.")
    sys.exit(1)

unmount_start = tests.find(
    "testWidgets('marks the queue unavailable when unmounted'"
)
unmount_end = tests.find(
    "testWidgets('rebinds future navigation to a replacement router'",
    unmount_start,
)
unmount_block = tests[unmount_start:unmount_end]
if "expect(queue.isRouterReady, isFalse);" not in unmount_block:
    print(
        "ERROR: unmount test must confirm the queue becomes unavailable."
    )
    sys.exit(1)

print(
    "OK: Task 9.6 binding lifecycle and focused timing assertions "
    "are correctly targeted."
)
