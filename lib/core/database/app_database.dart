import 'package:dashboard_shakhsi/core/database/database_connection.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

class TaskRows extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get priority => integer()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get completedAtUtc => dateTime().nullable()();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (priority BETWEEN 0 AND 3)',
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

@DriftDatabase(
  tables: <Type>[
    TaskRows,
    FinanceTransactionRows,
    DebtRows,
    DebtPaymentRows,
    InstallmentPlanRows,
    InstallmentPaymentRows,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openDashboardDatabase());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
