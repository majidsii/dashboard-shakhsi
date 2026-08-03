#!/usr/bin/env python3
from pathlib import Path
import py_compile
import re
import subprocess
import sys

interface_path = Path('lib/features/tasks/domain/task_repository.dart')
repository_path = Path('lib/features/tasks/data/drift_task_repository.dart')
test_path = Path(
    'test/features/tasks/data/drift_task_repository_transition_test.dart'
)
panel_test_path = Path(
    'test/features/dashboard/tasks_panel_persistence_test.dart'
)

for label, path in (
    ('TaskRepository interface', interface_path),
    ('DriftTaskRepository', repository_path),
    ('transition tests', test_path),
    ('panel TaskRepository fake', panel_test_path),
):
    if not path.is_file():
        print(f'ERROR: missing {label}: {path}')
        sys.exit(1)

interface = interface_path.read_text(encoding='utf-8')
repository = repository_path.read_text(encoding='utf-8')
test = test_path.read_text(encoding='utf-8')
panel_test = panel_test_path.read_text(encoding='utf-8')

required_interface = (
    'Future<void> transition({',
    'required String id,',
    'required TaskStatus status,',
    'required int targetPosition,',
    'required DateTime changedAtUtc,',
    'Future<void> reorderWithinStatus({',
    'required List<String> orderedIds,',
)
missing = [token for token in required_interface if token not in interface]
if missing:
    print(f'ERROR: TaskRepository Gate 2.1.5 contract is incomplete: {missing}')
    sys.exit(1)

required_repository = (
    'return _database.transaction(() async {',
    "throw const ValidationFailure('کار موردنظر پیدا نشد.');",
    'final normalizedChangedAt = changedAtUtc.toUtc();',
    'await _writePositionsWithTemporaryOffset(sourceIds);',
    'await _writePositionsWithTemporaryOffset(targetIds);',
    'await _writeTransitionedTask(',
    'final suppliedIds = orderedIds.toSet();',
    'suppliedIds.length != orderedIds.length',
    'orderedIds.length != currentIds.length',
    '!suppliedIds.containsAll(currentIds)',
    '_writePositionsWithTemporaryOffset(orderedIds)',
    'final temporaryOffset = 1000000 + orderedIds.length;',
    'status == TaskStatus.completed',
    'status == TaskStatus.canceled',
    'targetPosition: 0,',
)
missing = [token for token in required_repository if token not in repository]
if missing:
    print(f'ERROR: atomic repository implementation is incomplete: {missing}')
    sys.exit(1)

if repository.count('Future<void> transition({') != 1:
    print('ERROR: expected exactly one transition implementation.')
    sys.exit(1)
if repository.count('Future<void> reorderWithinStatus({') != 1:
    print('ERROR: expected exactly one reorderWithinStatus implementation.')
    sys.exit(1)

transition_match = re.search(
    r'Future<void> transition\(\{(?P<body>.*?)\n  \}\n\n  @override\n  Future<void> reorderWithinStatus',
    repository,
    flags=re.DOTALL,
)
if transition_match is None:
    print('ERROR: could not inspect transition implementation.')
    sys.exit(1)
transition_body = transition_match.group('body')
if '_database.transaction(() async {' not in transition_body:
    print('ERROR: transition is not wrapped in one Drift transaction.')
    sys.exit(1)

reorder_match = re.search(
    r'Future<void> reorderWithinStatus\(\{(?P<body>.*?)\n  \}\n\n  @override\n  Future<void> setDone',
    repository,
    flags=re.DOTALL,
)
if reorder_match is None:
    print('ERROR: could not inspect reorderWithinStatus implementation.')
    sys.exit(1)
reorder_body = reorder_match.group('body')
validation_index = reorder_body.find('if (suppliedIds.length')
write_index = reorder_body.find('await _writePositionsWithTemporaryOffset')
if validation_index < 0 or write_index < 0 or validation_index > write_index:
    print('ERROR: reorderWithinStatus must validate the full inventory before writes.')
    sys.exit(1)

required_tests = (
    'transition compacts source and inserts at exact target position',
    'transition maintains terminal timestamps across status changes',
    'transition clamps negative and oversized target positions',
    'missing transition id fails without writes',
    'transition survives file restart with contiguous positions',
    'reorderWithinStatus writes contiguous positions only in one status',
    'reorderWithinStatus rejects invalid inventories without writes',
    'expect(await _snapshot(repository), before);',
    'AppDatabase? database;',
    'final setupDatabase = database;',
    'await setupDatabase?.close();',
)
if 'late AppDatabase database;' in test:
    print(
        'ERROR: restart test still keeps the setUp database non-nullable, '
        'which can leave multiple AppDatabase instances open.'
    )
    sys.exit(1)

missing = [token for token in required_tests if token not in test]
if missing:
    print(f'ERROR: Gate 2.1.5 test evidence is incomplete: {missing}')
    sys.exit(1)

required_fake = (
    'Future<void> transition({',
    'Future<void> reorderWithinStatus({',
    'return transition(',
    'clearCompletedAt: true',
    'clearCanceledAt: true',
)
missing = [token for token in required_fake if token not in panel_test]
if missing:
    print(f'ERROR: panel TaskRepository fake is incomplete: {missing}')
    sys.exit(1)

for forbidden in (
    'DELETE FROM tasks',
    'DROP TABLE tasks',
    'deleteAll',
):
    if forbidden in repository:
        print(f'ERROR: destructive transition implementation found: {forbidden}')
        sys.exit(1)

for path in (Path(__file__),):
    try:
        py_compile.compile(str(path), doraise=True)
    except py_compile.PyCompileError as error:
        print(f'ERROR: verifier does not compile: {error.msg}')
        sys.exit(1)

diff_check = subprocess.run(
    ('git', 'diff', '--check'),
    check=False,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)
if diff_check.returncode != 0:
    print(f'ERROR: git diff --check failed:\n{diff_check.stdout.rstrip()}')
    sys.exit(1)

print(
    'OK: Gate 2.1.5 GREEN adds transactional status transitions with source '
    'compaction, clamped target insertion, UTC terminal timestamp projection, '
    'restart durability, and validate-first per-status reorder using temporary '
    'offset positions; invalid inventories and missing tasks fail without '
    'partial writes, and the current panel fake implements the new contract.'
)
