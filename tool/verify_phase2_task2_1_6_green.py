#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess
import sys

paths = {
    'panel': Path('lib/features/dashboard/presentation/widgets/tasks_panel.dart'),
    'interface': Path('lib/features/tasks/domain/task_repository.dart'),
    'repository': Path('lib/features/tasks/data/drift_task_repository.dart'),
    'panel_test': Path('test/features/dashboard/tasks_panel_test.dart'),
    'persistence_test': Path('test/features/dashboard/tasks_panel_persistence_test.dart'),
    'repository_test': Path('test/features/tasks/data/drift_task_repository_test.dart'),
    'restart_test': Path('test/core/database/database_restart_test.dart'),
}
for label, path in paths.items():
    if not path.is_file():
        print(f'ERROR: missing {label}: {path}')
        sys.exit(1)

text = {
    label: path.read_text(encoding='utf-8')
    for label, path in paths.items()
}
panel = text['panel']

required_panel = (
    'task.status != TaskStatus.canceled',
    'panelTasks.where((task) => task.isDone).length',
    'panelTasks.where((task) => task.isActive).length',
    'task.isActive && task.priority == 3',
    'Future<void> _addTask() async',
    'displayNumber: 1',
    'await repository.transition(',
    'status: TaskStatus.planned',
    'targetPosition: 0',
    'final targetStatus = task.status == TaskStatus.completed',
    '_TaskNumber(displayNumber: task.displayNumber)',
    "ValueKey<String>('task-number-$displayNumber')",
    '_fa(displayNumber)',
)
missing = [token for token in required_panel if token not in panel]
if missing:
    print(f'ERROR: TasksPanel status compatibility incomplete: {missing}')
    sys.exit(1)

for forbidden in (
    '.setDone(',
    'await repository.reorder(',
    'Future<void> _addTask(List<TaskItem> tasks)',
    '_TaskNumber(index:',
):
    if forbidden in panel:
        print(f'ERROR: legacy TasksPanel operation remains: {forbidden}')
        sys.exit(1)

for label in ('interface', 'repository', 'persistence_test'):
    source = text[label]
    for forbidden in (
        'Future<void> setDone(',
        'Future<void> reorder(List<String> orderedIds)',
    ):
        if forbidden in source:
            print(f'ERROR: temporary adapter remains in {label}: {forbidden}')
            sys.exit(1)

required_tests = (
    'counts planned and in-progress as active and hides canceled tasks',
    'add creates planned then moves it to position zero',
    'in-progress toggles to completed through transition',
    'completed toggles back to planned through transition',
    'delete completed preserves canceled persisted tasks',
    'current panel excludes canceled from rows counts and progress',
    "ValueKey<String>('task-number-4')",
    'repository.transitionCalls.single.status',
)
all_tests = text['panel_test'] + text['persistence_test']
missing = [token for token in required_tests if token not in all_tests]
if missing:
    print(f'ERROR: panel compatibility tests incomplete: {missing}')
    sys.exit(1)

required_repository_tests = (
    'repository.reorderWithinStatus(',
    "test('delete compacts only the removed task status'",
    'status: TaskStatus.planned',
)
missing = [
    token
    for token in required_repository_tests
    if token not in text['repository_test']
]
if missing:
    print(f'ERROR: repository adapter-removal tests incomplete: {missing}')
    sys.exit(1)

if re.search(
    r'''test\s*\(\s*['"]transition stores UTC completion and clears it when reopened['"]''',
    text['repository_test'],
) is None:
    print('ERROR: repository transition completion/reopen test is missing.')
    sys.exit(1)

if '.setDone(' in text['restart_test'] or '.reorder(' in text['restart_test']:
    print('ERROR: restart test still consumes removed compatibility adapters.')
    sys.exit(1)

repository = text['repository']
delete_match = re.search(
    r'''
    Future<void>\s+delete\s*\(\s*String\s+id\s*\)\s*
    \{
      (?P<body>.*?)
    \n\s*\}
    \n\s*
    @override
    \s*
    Future<void>\s+deleteCompleted
    ''',
    repository,
    flags=re.DOTALL | re.VERBOSE,
)
if delete_match is None:
    print('ERROR: could not locate the delete() implementation.')
    sys.exit(1)

delete_body = delete_match.group('body')
delete_body_compact = re.sub(r'[\s,]+', '', delete_body)

required_delete_tokens = (
    '_database.transaction(',
    'getSingleOrNull()',
    'TaskStatus.parseStorage(current.status)',
    '_database.delete(',
    '_orderedRowsForStatus(status)',
    '_writePositionsWithTemporaryOffset(remainingIds)',
)
missing = [
    token
    for token in required_delete_tokens
    if token not in delete_body_compact
]
if missing:
    print(
        'ERROR: delete no longer compacts source-status positions '
        f'transactionally: {missing}'
    )
    sys.exit(1)

transaction_index = delete_body_compact.find('_database.transaction(')
lookup_index = delete_body_compact.find('getSingleOrNull()')
status_index = delete_body_compact.find(
    'TaskStatus.parseStorage(current.status)'
)
delete_index = delete_body_compact.find('_database.delete(')
query_index = delete_body_compact.find('_orderedRowsForStatus(status)')
compact_index = delete_body_compact.find(
    '_writePositionsWithTemporaryOffset(remainingIds)'
)
if not (
    transaction_index <= lookup_index < status_index < delete_index
    < query_index < compact_index
):
    print(
        'ERROR: delete() operation order is no longer '
        'lookup -> parse status -> delete -> query remaining -> compact.'
    )
    sys.exit(1)

if "row.status.equals(TaskStatus.completed.storageValue)" not in repository:
    print('ERROR: deleteCompleted no longer targets completed status explicitly.')
    sys.exit(1)

check = subprocess.run(
    ('git', 'diff', '--check'),
    check=False,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)
if check.returncode != 0:
    print(f'ERROR: git diff --check failed:\n{check.stdout.rstrip()}')
    sys.exit(1)

print(
    'OK: Gate 2.1.6 GREEN preserves the current Persian Tasks panel while '
    'counting planned/inProgress as active, counting only completed as done, '
    'hiding canceled tasks, displaying immutable task numbers, creating '
    'planned tasks at position zero, toggling through atomic transitions, '
    'retaining completed-only cleanup, removing temporary adapters, and '
    'verifying transactional delete compaction independent of dart formatting.'
)
