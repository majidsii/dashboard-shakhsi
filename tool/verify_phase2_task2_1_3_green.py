#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess
import sys

app_database_path = Path('lib/core/database/app_database.dart')
generated_path = Path('lib/core/database/app_database.g.dart')
repository_path = Path(
    'lib/features/tasks/data/drift_task_repository.dart'
)
migration_test_path = Path(
    'test/core/database/task_status_migration_test.dart'
)
notification_test_path = Path(
    'test/core/database/notification_schedule_migration_test.dart'
)
app_database_test_path = Path('test/core/database/app_database_test.dart')
restart_test_path = Path('test/core/database/database_restart_test.dart')

for label, path in (
    ('database source', app_database_path),
    ('generated database source', generated_path),
    ('task repository bridge', repository_path),
    ('task migration test', migration_test_path),
    ('notification migration test', notification_test_path),
    ('database test', app_database_test_path),
    ('restart test', restart_test_path),
):
    if not path.is_file():
        print(f'ERROR: missing Gate 2.1.3 {label}: {path}')
        sys.exit(1)

source = app_database_path.read_text(encoding='utf-8')
generated = generated_path.read_text(encoding='utf-8')
repository = repository_path.read_text(encoding='utf-8')
migration_test = migration_test_path.read_text(encoding='utf-8')
notification_test = notification_test_path.read_text(encoding='utf-8')
app_database_test = app_database_test_path.read_text(encoding='utf-8')
restart_test = restart_test_path.read_text(encoding='utf-8')

required_source = (
    'IntColumn get displayNumber => integer().unique()();',
    'TextColumn get status => text()();',
    'IntColumn get positionInStatus => integer()();',
    'DateTimeColumn get canceledAtUtc => dateTime().nullable()();',
    "CHECK (display_number > 0)",
    "CHECK (status IN ('planned', 'inProgress', 'completed', 'canceled'))",
    'CHECK (position_in_status >= 0)',
    "status = 'completed'",
    "status = 'canceled'",
    'int get schemaVersion => 3;',
    "ALTER TABLE tasks RENAME TO tasks_v2_legacy",
    'ROW_NUMBER() OVER (',
    'ORDER BY created_at_utc ASC, id ASC',
    'PARTITION BY is_done',
    'ORDER BY sort_order ASC, created_at_utc ASC, id ASC',
    "WHEN is_done = 1 THEN 'completed'",
    "ELSE 'planned'",
    'COALESCE(completed_at_utc, updated_at_utc)',
    'NULL AS canceled_at_utc',
    'DROP TABLE tasks_v2_legacy',
)
missing = [token for token in required_source if token not in source]
if missing:
    print(f'ERROR: schema-v3 source contract incomplete: {missing}')
    sys.exit(1)

for forbidden in (
    'BoolColumn get isDone',
    'IntColumn get sortOrder',
    'int get schemaVersion => 2;',
):
    if forbidden in source:
        print(f'ERROR: legacy TaskRows schema remains: {forbidden}')
        sys.exit(1)

if source.index('if (from < 2)') > source.index('if (from < 3)'):
    print('ERROR: version-one notification migration must run before task v3 migration.')
    sys.exit(1)

# Isolate the generated TaskRows table so unrelated tables cannot satisfy checks.
generated_match = re.search(
    r'class \$TaskRowsTable.*?(?=class \$FinanceTransactionRowsTable)',
    generated,
    flags=re.DOTALL,
)
if generated_match is None:
    print('ERROR: generated TaskRows table block could not be located.')
    sys.exit(1)

generated_task_rows = generated_match.group(0)
for token in (
    "'display_number'",
    "'status'",
    "'position_in_status'",
    "'canceled_at_utc'",
    'displayNumber',
    'positionInStatus',
    'canceledAtUtc',
):
    if token not in generated_task_rows:
        print(f'ERROR: build_runner output is stale; missing {token}.')
        sys.exit(1)
for forbidden in ("'is_done'", "'sort_order'", ' isDone ', ' sortOrder '):
    if forbidden in generated_task_rows:
        print(f'ERROR: build_runner output still contains legacy task field: {forbidden}')
        sys.exit(1)

required_repository = (
    'TaskStatus.parseStorage(row.status)',
    'displayNumber: row.displayNumber',
    'positionInStatus: row.positionInStatus',
    'canceledAtUtc: row.canceledAtUtc?.toUtc()',
    'status: Value<String>(task.status.storageValue)',
    'positionInStatus: Value<int>(task.positionInStatus)',
    'canceledAtUtc: Value<DateTime?>(task.canceledAtUtc)',
    'row.status.equals(TaskStatus.completed.storageValue)',
    'final statusOrder = left.status.index.compareTo(right.status.index);',
)
missing = [token for token in required_repository if token not in repository]
if missing:
    print(f'ERROR: schema-v3 repository bridge incomplete: {missing}')
    sys.exit(1)
for forbidden in ('row.isDone', 'row.sortOrder', 'isDone: Value<bool>', 'sortOrder: Value<int>'):
    if forbidden in repository:
        print(f'ERROR: repository still depends on removed schema-v2 field: {forbidden}')
        sys.exit(1)

required_migration_test = (
    'version two migrates tasks deterministically to schema three',
    '_createVersionTwoFixture',
    'PRAGMA user_version = 2',
    'expect(migrated.schemaVersion, 3)',
    "byId['task-a']!.displayNumber, 1",
    "byId['task-b']!.displayNumber, 2",
    "byId['task-c']!.positionInStatus, 0",
    "byId['task-b']!.positionInStatus, 1",
    "byId['task-d']!.positionInStatus, 0",
    "byId['task-a']!.positionInStatus, 1",
    "PRAGMA table_info(tasks)",
    "isNot(contains('is_done'))",
    "isNot(contains('sort_order'))",
    'final reopened = AppDatabase(NativeDatabase(file));',
)
missing = [token for token in required_migration_test if token not in migration_test]
if missing:
    print(f'ERROR: schema-v2 migration test coverage incomplete: {missing}')
    sys.exit(1)

required_notification_test = (
    'version one migrates notifications and tasks through schema three',
    'PRAGMA user_version = 1',
    'expect(migrated.schemaVersion, 3)',
    "name = 'notification_schedules'",
    'tasks.single.displayNumber, 1',
    'TaskStatus.planned.storageValue',
)
missing = [token for token in required_notification_test if token not in notification_test]
if missing:
    print(f'ERROR: version-one combined migration coverage incomplete: {missing}')
    sys.exit(1)

for label, text in (
    ('app database test', app_database_test),
    ('restart test', restart_test),
):
    if 'schemaVersion, 2' in text or "user_version'), 2" in text:
        print(f'ERROR: {label} still expects schema version 2.')
        sys.exit(1)

if 'schema version three creates all persistence tables' not in app_database_test:
    print('ERROR: app database test was not updated to schema version three.')
    sys.exit(1)
if 'file-backed database keeps schema version three' not in restart_test:
    print('ERROR: restart test was not updated to schema version three.')
    sys.exit(1)
if "'task-a',\n          'task-b'" not in restart_test:
    print('ERROR: restart test does not assert planned-before-completed ordering.')
    sys.exit(1)

# Drift migrations run inside the migration transaction. Forbid destructive
# fallback APIs that would erase user data instead of migrating it.
for forbidden in (
    'deleteAllTables',
    'recreateAllViews',
    'DROP TABLE tasks;',
    'DROP TABLE IF EXISTS tasks;',
):
    if forbidden in source:
        print(f'ERROR: destructive migration fallback detected: {forbidden}')
        sys.exit(1)

result = subprocess.run(
    ('git', 'diff', '--check'),
    check=False,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)
if result.returncode != 0:
    print(f'ERROR: git diff --check failed:\n{result.stdout.rstrip()}')
    sys.exit(1)

print(
    'OK: Gate 2.1.3 GREEN defines schema version 3, removes boolean/global '
    'task columns, enforces canonical status and timestamp constraints, '
    'migrates real version-2 rows with deterministic display numbers and '
    'independent status positions, repairs missing completion timestamps, '
    'preserves version-1 notification migration, survives file restart, '
    'regenerates Drift code, and provides a temporary schema-v3 repository '
    'bridge without destructive fallback.'
)
