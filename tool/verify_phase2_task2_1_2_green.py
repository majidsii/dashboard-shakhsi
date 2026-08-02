#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess
import sys

source_path = Path('lib/features/tasks/domain/task_item.dart')
status_path = Path('lib/features/tasks/domain/task_status.dart')
repository_path = Path('lib/features/tasks/data/drift_task_repository.dart')
test_path = Path('test/features/tasks/domain/task_item_test.dart')

required_files = (
    source_path,
    status_path,
    repository_path,
    test_path,
    Path('lib/features/dashboard/presentation/widgets/tasks_panel.dart'),
    Path('test/core/database/database_restart_test.dart'),
    Path('test/core/providers/persistence_providers_test.dart'),
    Path('test/features/tasks/data/drift_task_repository_test.dart'),
    Path('test/features/dashboard/tasks_panel_persistence_test.dart'),
)
for path in required_files:
    if not path.is_file():
        print(f'ERROR: missing Gate 2.1.2 file: {path}')
        sys.exit(1)

source = source_path.read_text(encoding='utf-8')
repository = repository_path.read_text(encoding='utf-8')
test = test_path.read_text(encoding='utf-8')

required_source = (
    'required this.displayNumber',
    'required this.status',
    'required this.positionInStatus',
    'this.canceledAtUtc',
    'final int displayNumber;',
    'final TaskStatus status;',
    'final int positionInStatus;',
    'final DateTime? canceledAtUtc;',
    'bool get isDone => status == TaskStatus.completed;',
    'bool get isActive =>',
    'int get sortOrder => positionInStatus;',
    'clearCompletedAt = false',
    'clearCanceledAt = false',
    '_validateStatusTimestamps(',
    'case TaskStatus.completed:',
    'case TaskStatus.canceled:',
    'case TaskStatus.planned:',
    'case TaskStatus.inProgress:',
)
missing = [token for token in required_source if token not in source]
if missing:
    print(f'ERROR: TaskItem v2 contract incomplete: {missing}')
    sys.exit(1)

for forbidden in (
    'required this.isDone',
    'required this.sortOrder',
    'final bool isDone;',
    'final int sortOrder;',
):
    if forbidden in source:
        print(f'ERROR: old TaskItem canonical field remains: {forbidden}')
        sys.exit(1)

required_repository = (
    'displayNumbers[row.id]!',
    'row.isDone',
    'TaskStatus.completed',
    'TaskStatus.planned',
    'positionInStatus: row.sortOrder',
    '(row.completedAtUtc ?? row.updatedAtUtc).toUtc()',
    'task.status == TaskStatus.inProgress',
    'task.status == TaskStatus.canceled',
    'sortOrder: Value<int>(task.positionInStatus)',
)
missing = [token for token in required_repository if token not in repository]
if missing:
    print(f'ERROR: schema-v2 repository compatibility incomplete: {missing}')
    sys.exit(1)


copy_with_match = re.search(
    r"final updated = original\.copyWith\((?P<body>.*?)\n\s*\);",
    Path(
        "test/features/tasks/data/drift_task_repository_test.dart"
    ).read_text(encoding="utf-8"),
    flags=re.DOTALL,
)
if copy_with_match is None:
    print("ERROR: repository update TaskItem.copyWith fixture is missing.")
    sys.exit(1)

copy_with_body = copy_with_match.group("body")
if "sortOrder:" in copy_with_body:
    print("ERROR: legacy sortOrder remains in TaskItem.copyWith.")
    sys.exit(1)
if "positionInStatus:" not in copy_with_body:
    print("ERROR: TaskItem.copyWith does not update positionInStatus.")
    sys.exit(1)

required_tests = (
    'keeps canonical v2 fields and compatibility getters',
    'rejects invalid identity number priority and position',
    'rejects local timestamps in canonical timestamp fields',
    'enforces terminal timestamps for every status',
    'copyWith transitions and preserves immutable fields',
    'equality and hash include canonical v2 state',
)
missing = [token for token in required_tests if token not in test]
if missing:
    print(f'ERROR: TaskItem v2 test coverage incomplete: {missing}')
    sys.exit(1)


def task_item_calls(text: str) -> list[str]:
    calls = []
    cursor = 0
    marker = 'TaskItem('
    while True:
        start = text.find(marker, cursor)
        if start < 0:
            return calls
        index = start + len(marker)
        depth = 1
        while index < len(text) and depth:
            char = text[index]
            if char == '(':
                depth += 1
            elif char == ')':
                depth -= 1
            index += 1
        if depth != 0:
            print('ERROR: unbalanced TaskItem constructor call.')
            sys.exit(1)
        calls.append(text[start:index])
        cursor = index

scan_paths = (
    Path('lib/features/tasks/data/drift_task_repository.dart'),
    Path('lib/features/dashboard/presentation/widgets/tasks_panel.dart'),
    Path('test/core/database/database_restart_test.dart'),
    Path('test/core/providers/persistence_providers_test.dart'),
    Path('test/features/tasks/data/drift_task_repository_test.dart'),
    Path('test/features/dashboard/tasks_panel_persistence_test.dart'),
    Path('test/features/tasks/domain/task_item_test.dart'),
)
for path in scan_paths:
    for call in task_item_calls(path.read_text(encoding='utf-8')):
        for required in ('displayNumber:', 'status:', 'positionInStatus:'):
            if required not in call:
                print(f'ERROR: non-canonical TaskItem call in {path}: missing {required}')
                sys.exit(1)
        for forbidden in ('isDone:', 'sortOrder:'):
            if forbidden in call:
                print(f'ERROR: legacy TaskItem argument remains in {path}: {forbidden}')
                sys.exit(1)

panel = Path('lib/features/dashboard/presentation/widgets/tasks_panel.dart').read_text(encoding='utf-8')
if 'math.max(highest, task.displayNumber)' not in panel:
    print('ERROR: current panel does not allocate a temporary positive number.')
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
    'OK: Gate 2.1.2 GREEN establishes canonical TaskItem v2 identity, '
    'display number, four-state status, status-local position, UTC and '
    'terminal timestamp invariants, immutable copy semantics, complete '
    'equality, old isDone/sortOrder read compatibility, safe schema-v2 '
    'planned/completed mapping, rejection of lossy inProgress/canceled writes, '
    'and migrated repository/UI/test construction sites.'
)
