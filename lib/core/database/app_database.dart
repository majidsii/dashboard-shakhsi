import 'package:dashboard_shakhsi/core/database/database_connection.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

class TaskRows extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  IntColumn get displayNumber => integer().unique()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get priority => integer()();
  TextColumn get status => text()();
  IntColumn get positionInStatus => integer()();
  DateTimeColumn get startAtUtc => dateTime().nullable()();
  DateTimeColumn get dueAtUtc => dateTime().nullable()();
  IntColumn get estimatedDurationMinutes => integer().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get completedAtUtc => dateTime().nullable()();
  DateTimeColumn get canceledAtUtc => dateTime().nullable()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (display_number > 0)',
    'CHECK (priority BETWEEN 0 AND 3)',
    "CHECK (status IN ('planned', 'inProgress', 'completed', 'canceled'))",
    'CHECK (position_in_status >= 0)',
    'CHECK (estimated_duration_minutes IS NULL '
        'OR estimated_duration_minutes > 0)',
    'CHECK (start_at_utc IS NULL OR due_at_utc IS NULL '
        'OR due_at_utc >= start_at_utc)',
    "CHECK ((status = 'completed' AND completed_at_utc IS NOT NULL "
        "AND canceled_at_utc IS NULL) OR "
        "(status = 'canceled' AND canceled_at_utc IS NOT NULL "
        "AND completed_at_utc IS NULL) OR "
        "(status IN ('planned', 'inProgress') "
        "AND completed_at_utc IS NULL AND canceled_at_utc IS NULL))",
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class FinanceTransactionRows extends Table {
  @override
  String get tableName => 'finance_transactions';

  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  IntColumn get amountMinorUnits => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('IRT'))();
  IntColumn get scale => integer().withDefault(const Constant(8))();
  DateTimeColumn get occurredAtUtc => dateTime()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (type IN ('income', 'expense'))",
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class DebtRows extends Table {
  @override
  String get tableName => 'debts';

  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get totalMinorUnits => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('IRT'))();
  IntColumn get scale => integer().withDefault(const Constant(8))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get archivedAtUtc => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class DebtPaymentRows extends Table {
  @override
  String get tableName => 'debt_payments';

  TextColumn get id => text()();
  TextColumn get debtId =>
      text().references(DebtRows, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountMinorUnits => integer()();
  DateTimeColumn get paidAtUtc => dateTime()();
  DateTimeColumn get createdAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class InstallmentPlanRows extends Table {
  @override
  String get tableName => 'installment_plans';

  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get perInstallmentMinorUnits => integer()();
  IntColumn get installmentCount => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('IRT'))();
  IntColumn get scale => integer().withDefault(const Constant(8))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get archivedAtUtc => dateTime().nullable()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (installment_count > 0)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class InstallmentPaymentRows extends Table {
  @override
  String get tableName => 'installment_payments';

  TextColumn get id => text()();
  TextColumn get planId => text().references(
    InstallmentPlanRows,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get installmentNumber => integer()();
  IntColumn get amountMinorUnits => integer()();
  DateTimeColumn get paidAtUtc => dateTime()();
  DateTimeColumn get createdAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{planId, installmentNumber},
  ];
}

class TaskReminderRuleRows extends Table {
  @override
  String get tableName => 'task_reminder_rules';

  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get trigger => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get privacyMode => text().withDefault(const Constant('full'))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (trigger IN ('atDue', 'fifteenMinutesBefore', 'oneHourBefore', 'oneDayBefore'))",
    "CHECK (privacy_mode IN ('full', 'private'))",
    'CHECK (updated_at_utc >= created_at_utc)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{taskId, trigger},
  ];
}

class TaskRecurrenceRuleRows extends Table {
  @override
  String get tableName => 'task_recurrence_rules';

  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade).unique()();
  TextColumn get ruleJson => text()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (length(rule_json) > 2)',
    'CHECK (updated_at_utc >= created_at_utc)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class TaskRecurrenceExceptionRows extends Table {
  @override
  String get tableName => 'task_recurrence_exceptions';

  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get originalLocalKey => text()();
  TextColumn get exceptionJson => text()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (length(original_local_key) >= 16)',
    'CHECK (length(exception_json) > 2)',
    'CHECK (updated_at_utc >= created_at_utc)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{taskId, originalLocalKey},
  ];
}

class TaskOccurrenceCompletionRows extends Table {
  @override
  String get tableName => 'task_occurrence_completions';

  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get originalLocalKey => text()();
  DateTimeColumn get completedAtUtc => dateTime()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (length(original_local_key) >= 16)',
    'CHECK (updated_at_utc >= created_at_utc)',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    taskId,
    originalLocalKey,
  };
}

class TaskTimeEntryRows extends Table {
  @override
  String get tableName => 'task_time_entries';

  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(TaskRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get source => text()();
  TextColumn get state => text()();
  DateTimeColumn get startedAtUtc => dateTime()();
  DateTimeColumn get lastResumedAtUtc => dateTime().nullable()();
  DateTimeColumn get endedAtUtc => dateTime().nullable()();
  IntColumn get accumulatedSeconds => integer()();
  IntColumn get activeSlot => integer().nullable().unique()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (source IN ('timer', 'manual'))",
    "CHECK (state IN ('running', 'paused', 'stopped'))",
    'CHECK (accumulated_seconds >= 0)',
    'CHECK (active_slot IS NULL OR active_slot = 1)',
    'CHECK (ended_at_utc IS NULL OR ended_at_utc > started_at_utc)',
    'CHECK (updated_at_utc >= created_at_utc)',
    "CHECK ((state = 'running' AND source = 'timer' "
        'AND last_resumed_at_utc IS NOT NULL AND ended_at_utc IS NULL '
        'AND active_slot = 1) OR '
        "(state = 'paused' AND source = 'timer' "
        'AND last_resumed_at_utc IS NULL AND ended_at_utc IS NULL '
        'AND active_slot = 1) OR '
        "(state = 'stopped' AND last_resumed_at_utc IS NULL "
        'AND ended_at_utc IS NOT NULL AND active_slot IS NULL '
        'AND accumulated_seconds > 0))',
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class NotificationScheduleRows extends Table {
  @override
  String get tableName => 'notification_schedules';

  TextColumn get scheduleId => text()();
  TextColumn get ownerType => text()();
  TextColumn get ownerId => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get scheduledAtUtc => dateTime()();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  TextColumn get privacyMode => text().withDefault(const Constant('full'))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  List<String> get customConstraints => <String>[
    "CHECK (owner_type IN ("
        "'task', 'habit', 'routine', 'challenge', "
        "'installment', 'debt', 'recurringTransaction', 'dailySummary'"
        "))",
    "CHECK (privacy_mode IN ('full', 'private'))",
  ];

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{scheduleId};
}

@DriftDatabase(
  tables: <Type>[
    TaskRows,
    FinanceTransactionRows,
    DebtRows,
    DebtPaymentRows,
    InstallmentPlanRows,
    InstallmentPaymentRows,
    TaskReminderRuleRows,
    TaskRecurrenceRuleRows,
    TaskRecurrenceExceptionRows,
    TaskOccurrenceCompletionRows,
    TaskTimeEntryRows,
    NotificationScheduleRows,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openDashboardDatabase());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(notificationScheduleRows);
      }
      if (from < 3) {
        await customStatement('ALTER TABLE tasks RENAME TO tasks_v2_legacy');
        await migrator.createTable(taskRows);
        await customStatement('''
          INSERT INTO tasks (
            id,
            display_number,
            title,
            priority,
            status,
            position_in_status,
            created_at_utc,
            updated_at_utc,
            completed_at_utc,
            canceled_at_utc
          )
          SELECT
            id,
            ROW_NUMBER() OVER (
              ORDER BY created_at_utc ASC, id ASC
            ) AS display_number,
            title,
            priority,
            CASE
              WHEN is_done = 1 THEN 'completed'
              ELSE 'planned'
            END AS status,
            ROW_NUMBER() OVER (
              PARTITION BY is_done
              ORDER BY sort_order ASC, created_at_utc ASC, id ASC
            ) - 1 AS position_in_status,
            created_at_utc,
            updated_at_utc,
            CASE
              WHEN is_done = 1
                THEN COALESCE(completed_at_utc, updated_at_utc)
              ELSE NULL
            END AS completed_at_utc,
            NULL AS canceled_at_utc
          FROM tasks_v2_legacy
        ''');
        await customStatement('DROP TABLE tasks_v2_legacy');
      }
      if (from >= 3 && from < 4) {
        await customStatement('ALTER TABLE tasks RENAME TO tasks_v3_legacy');
        await migrator.createTable(taskRows);
        await customStatement('''
          INSERT INTO tasks (
            id,
            display_number,
            title,
            description,
            priority,
            status,
            position_in_status,
            start_at_utc,
            due_at_utc,
            estimated_duration_minutes,
            created_at_utc,
            updated_at_utc,
            completed_at_utc,
            canceled_at_utc
          )
          SELECT
            id,
            display_number,
            title,
            NULL AS description,
            priority,
            status,
            position_in_status,
            NULL AS start_at_utc,
            NULL AS due_at_utc,
            NULL AS estimated_duration_minutes,
            created_at_utc,
            updated_at_utc,
            completed_at_utc,
            canceled_at_utc
          FROM tasks_v3_legacy
        ''');
        await customStatement('DROP TABLE tasks_v3_legacy');
      }
      if (from < 5) {
        await migrator.createTable(taskReminderRuleRows);
      }
      if (from < 6) {
        await migrator.createTable(taskRecurrenceRuleRows);
        await migrator.createTable(taskRecurrenceExceptionRows);
        await migrator.createTable(taskOccurrenceCompletionRows);
      }
      if (from < 7) {
        await migrator.createTable(taskTimeEntryRows);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
