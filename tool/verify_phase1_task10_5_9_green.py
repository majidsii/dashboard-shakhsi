#!/usr/bin/env python3
from pathlib import Path
import sys

scheduler_path = Path(
    'lib/core/notifications/linux_systemd_notification_scheduler.dart'
)
test_path = Path(
    'test/core/notifications/'
    'linux_systemd_notification_scheduler_reconcile_inventory_test.dart'
)

for label, path in (
    ('scheduler', scheduler_path),
    ('inventory tests', test_path),
):
    if not path.exists():
        print(f'ERROR: missing Task 10.5.9 {label}: {path}')
        sys.exit(1)

scheduler = scheduler_path.read_text(encoding='utf-8')
test = test_path.read_text(encoding='utf-8')

required_scheduler = [
    '() => _reconcileInventoryUnlocked(expected)',
    'Future<void> _reconcileInventoryUnlocked(',
    'final desiredById = <String, NotificationRequest>{}',
    'desiredById[request.scheduleId] = request',
    'request.scheduledAtUtc.isAfter(nowUtc)',
    'left.scheduleId.compareTo(right.scheduleId)',
    'on LinuxSystemdScheduleRegistryException',
    '_registryStore.quarantineCorruptRegistry',
    'registry = LinuxSystemdScheduleRegistry.empty()',
    '_registryStore.discoverAppUnitPairs',
    'discovery.completePairs',
    'discovery.partialPairs',
    'desiredBaseNames.contains(names.baseName)',
    'LinuxSystemdUnitNames.parseBaseName(partial.baseName)',
    'candidatesByBaseName.values.toList()',
    'left.sortKey.compareTo(right.sortKey)',
    '_unitStore.beginRemove(candidate.names)',
    '_driver.disableAndStop(',
    'action: transaction.apply',
    'if (removals.isNotEmpty)',
    'action: _driver.reloadDaemon',
    'if (registryChanged)',
    '_registryStore.replace(nextRegistry)',
    'action: removal.transaction.finalize',
    '_rollbackReconciliationCleanup(',
    'generation: registry.generation + 1',
    'final class _ReconciliationCleanupCandidate',
]
missing_scheduler = [
    token for token in required_scheduler if token not in scheduler
]
if missing_scheduler:
    print(
        'ERROR: Task 10.5.9 GREEN implementation incomplete: '
        f'{missing_scheduler}'
    )
    sys.exit(1)

required_tests = [
    'last value wins before due filtering',
    'stale cleanup is processed in schedule ID order',
    'due request cleans stale state without immediate delivery',
    'removes stale registry entry while preserving desired future entry',
    'removes orphan complete pair absent from registry and desired state',
    'preserves orphan complete pair when it belongs to desired future state',
    'removes service-only and timer-only partial pairs',
    'quarantines corruption, discovers once, and removes all exact pairs',
    'mismatched-name corruption is quarantined and cleaned by discovery',
    'empty inventory is a true no-op after one load and discovery',
]
missing_tests = [token for token in required_tests if token not in test]
if missing_tests:
    print(f'ERROR: Task 10.5.9 tests incomplete: {missing_tests}')
    sys.exit(1)

for forbidden in (
    'Process.start',
    'Process.run',
    'Directory.systemTemp',
    'UnimplementedError',
    'TODO',
    'FIXME',
):
    if forbidden in scheduler:
        print(
            'ERROR: Task 10.5.9 contains direct IO/process or placeholder: '
            f'{forbidden}'
        )
        sys.exit(1)

public_start = scheduler.find(
    'Future<void> reconcile(List<NotificationRequest> expected)'
)
helper_start = scheduler.find(
    'Future<void> _reconcileInventoryUnlocked(', public_start
)
schedule_start = scheduler.find(
    'Future<void> _scheduleUnlocked(', helper_start
)
if not (-1 < public_start < helper_start < schedule_start):
    print('ERROR: reconcile method boundaries are invalid.')
    sys.exit(1)

public_body = scheduler[public_start:helper_start]
helper_body = scheduler[helper_start:schedule_start]

if '_globalLock.runWrite' not in public_body:
    print('ERROR: reconcile does not hold the global write lock.')
    sys.exit(1)

for forbidden_call in (
    '_scheduleUnlocked(',
    '_gateway.showNow(',
    '_gateway.schedule(',
    '_unitStore.beginInstall(',
):
    if forbidden_call in helper_body:
        print(
            'ERROR: Gate 10.5.9 performs repair or delivery too early: '
            f'{forbidden_call}'
        )
        sys.exit(1)

if helper_body.count('_registryStore.discoverAppUnitPairs') != 1:
    print(
        'ERROR: reconciliation must discover inventory exactly once; found '
        f"{helper_body.count('_registryStore.discoverAppUnitPairs')} calls."
    )
    sys.exit(1)

normalize_index = helper_body.find(
    'desiredById[request.scheduleId] = request'
)
filter_index = helper_body.find(
    'request.scheduledAtUtc.isAfter(nowUtc)', normalize_index
)
sort_index = helper_body.find(
    'left.scheduleId.compareTo(right.scheduleId)', filter_index
)
load_index = helper_body.find('_registryStore.load', sort_index)
quarantine_index = helper_body.find(
    '_registryStore.quarantineCorruptRegistry', load_index
)
discovery_index = helper_body.find(
    '_registryStore.discoverAppUnitPairs', quarantine_index
)
cleanup_sort_index = helper_body.find(
    'left.sortKey.compareTo(right.sortKey)', discovery_index
)
begin_index = helper_body.find(
    '_unitStore.beginRemove(candidate.names)', cleanup_sort_index
)
disable_index = helper_body.find(
    '_driver.disableAndStop(', begin_index
)
apply_index = helper_body.find('action: transaction.apply', disable_index)
reload_index = helper_body.find(
    'action: _driver.reloadDaemon', apply_index
)
replace_index = helper_body.find(
    '_registryStore.replace(nextRegistry)', reload_index
)
finalize_index = helper_body.find(
    'action: removal.transaction.finalize', replace_index
)

if not (
    -1
    < normalize_index
    < filter_index
    < sort_index
    < load_index
    < quarantine_index
    < discovery_index
    < cleanup_sort_index
    < begin_index
    < disable_index
    < apply_index
    < reload_index
    < replace_index
    < finalize_index
):
    print('ERROR: reconciliation normalization/cleanup order is incorrect.')
    sys.exit(1)

if 'if (expected.isEmpty)' in public_body or 'if (expected.isEmpty)' in helper_body:
    print(
        'ERROR: reconcile still returns early for empty expected inventory.'
    )
    sys.exit(1)

if 'showNowCalls, 0' not in test or 'installCalls, 0' not in test:
    print('ERROR: tests do not prove cleanup-only reconciliation.')
    sys.exit(1)

print(
    'OK: Task 10.5.9 GREEN normalizes desired requests with last-value-wins, '
    'filters due items without delivery, sorts deterministically, recovers typed '
    'registry corruption through quarantine, performs one exact discovery, '
    'removes stale registry state, orphan complete pairs, and partial pairs, '
    'preserves desired future inventory, uses retained removals with one coherent '
    'daemon reload, writes only changed confirmed registry state, and leaves '
    'future repair for Gate 10.5.10.'
)
