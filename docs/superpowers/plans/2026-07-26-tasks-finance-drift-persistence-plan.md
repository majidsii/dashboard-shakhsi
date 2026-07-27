# Tasks and Finance Drift Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the in-memory task and finance preview state with a local Drift database so tasks, transactions, debts, debt payments, installment plans, and installment payments survive a full application restart without changing the current Liquid Glass interface.

**Architecture:** A single `AppDatabase` owns six normalized SQLite tables and exposes transactional persistence primitives. Domain repositories hide Drift-generated row classes from the UI, Riverpod providers supply live streams and commands, and the existing task/finance panels keep only transient form, filter, search, and animation state. Exact monetary values remain `Money(minorUnits, currencyCode: 'IRT', scale: 8)` throughout the domain; conversion to `double` is restricted to chart coordinates and progress rendering.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Riverpod 2.6.1, Drift 2.34.2, drift_flutter 0.3.1, drift_dev 2.34.2, build_runner, uuid 4.6.0, flutter_test.

## Global Constraints

- Preserve the current original-style Liquid Glass visuals, Persian copy, RTL layout, spacing, keys, semantics labels, and chart composition.
- Database file name must be `dashboard_shakhsi.sqlite`; pass `name: 'dashboard_shakhsi'` to `driftDatabase` because drift_flutter adds the `.sqlite` suffix on native platforms.
- `schemaVersion` is exactly `1`; destructive migration is forbidden.
- All stored dates are UTC. Convert to local time only for Jalali labels and local-day/month reporting.
- All finance values use currency `IRT`, scale `8`, and signed 64-bit integer `minorUnits`; repository calculations must never use `double`.
- `double` is allowed only in chart coordinates and progress percentages.
- UUID text identifiers are generated through the existing `IdGenerator` abstraction.
- Database writes are not optimistic: update the UI only after the Drift write commits and the watched query emits.
- Foreign keys must be enabled and payment rows must cascade-delete with their parent.
- Existing task search/filter/sort controls and finance form controls stay local to their panels.
- Every task follows Red → Green → Refactor and ends with a commit.

---

## File Structure

### Create

```text
app/lib/core/database/database_connection.dart
app/lib/core/database/app_database.dart
app/lib/core/database/app_database.g.dart                 # generated; never hand-edit
app/lib/core/database/database_providers.dart
app/lib/features/tasks/domain/task_item.dart
app/lib/features/tasks/domain/task_repository.dart
app/lib/features/tasks/data/drift_task_repository.dart
app/lib/features/tasks/application/task_providers.dart
app/lib/features/finance/domain/finance_transaction.dart
app/lib/features/finance/domain/debt.dart
app/lib/features/finance/domain/installment_plan.dart
app/lib/features/finance/domain/finance_repository.dart
app/lib/features/finance/data/drift_finance_repository.dart
app/lib/features/finance/application/finance_summary.dart
app/lib/features/finance/application/finance_report_service.dart
app/lib/features/finance/application/finance_providers.dart
app/test/core/database/app_database_test.dart
app/test/core/database/database_restart_test.dart
app/test/features/tasks/data/drift_task_repository_test.dart
app/test/features/finance/data/drift_finance_repository_test.dart
app/test/features/finance/application/finance_report_service_test.dart
app/test/support/test_database.dart
```

### Modify

```text
app/lib/app/bootstrap/app_bootstrap.dart
app/lib/features/dashboard/presentation/widgets/tasks_panel.dart
app/lib/features/dashboard/presentation/widgets/finance_panel.dart
app/lib/features/dashboard/presentation/widgets/finance_charts.dart
app/lib/features/dashboard/presentation/widgets/finance_preview_models.dart
app/test/features/dashboard/tasks_panel_test.dart
app/test/features/dashboard/finance_panel_test.dart
app/test/features/dashboard/original_dashboard_screen_test.dart
app/test/app/bootstrap/app_bootstrap_test.dart
app/pubspec.yaml
```

### Remove after all consumers migrate

```text
Private _TaskPreview model from tasks_panel.dart
FinancePreviewTransaction
FinancePreviewDebt
FinancePreviewInstallment
FinancePreviewTotals
FinancePreviewMath
```

Keep chart-only point classes (`FinanceMonthPoint`, `FinanceCategoryPoint`, `FinanceDayPoint`) but move them to `finance_summary.dart`.

---

## Task 1: Define and Open Schema Version 1

**Files:**
- Create: `app/lib/core/database/database_connection.dart`
- Create: `app/lib/core/database/app_database.dart`
- Generate: `app/lib/core/database/app_database.g.dart`
- Create: `app/test/core/database/app_database_test.dart`
- Create: `app/test/support/test_database.dart`
- Modify: `app/pubspec.yaml`

**Interfaces:**
- Produces: `DatabaseConnection openDashboardDatabase()`
- Produces: `AppDatabase([QueryExecutor? executor])`
- Produces six tables: `TaskRows`, `FinanceTransactionRows`, `DebtRows`, `DebtPaymentRows`, `InstallmentPlanRows`, `InstallmentPaymentRows`
- Produces test helper: `AppDatabase openTestDatabase()`

- [ ] **Step 1: Add the database test helper**

Create `app/test/support/test_database.dart`:

```dart
import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:drift/native.dart';

AppDatabase openTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
```

- [ ] **Step 2: Write failing schema tests**

Create `app/test/core/database/app_database_test.dart`:

```dart
import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = openTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test('schema version one creates all persistence tables', () async {
    expect(database.schemaVersion, 1);

    final rows = await database.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(
      names,
      containsAll(<String>{
        'tasks',
        'finance_transactions',
        'debts',
        'debt_payments',
        'installment_plans',
        'installment_payments',
      }),
    );
  });

  test('installment number is unique inside a plan', () async {
    final now = DateTime.utc(2026, 7, 26);
    await database.into(database.installmentPlanRows).insert(
      InstallmentPlanRowsCompanion.insert(
        id: 'plan-1',
        title: 'قسط خودرو',
        perInstallmentMinorUnits: 100000000000000,
        installmentCount: 12,
        currencyCode: 'IRT',
        scale: 8,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

    Future<void> insertPayment() {
      return database.into(database.installmentPaymentRows).insert(
        InstallmentPaymentRowsCompanion.insert(
          id: 'payment-1',
          planId: 'plan-1',
          installmentNumber: 1,
          amountMinorUnits: 100000000000000,
          paidAtUtc: now,
          createdAtUtc: now,
        ),
      );
    }

    await insertPayment();
    await expectLater(insertPayment(), throwsA(isA<Exception>()));
  });

  test('deleting a debt cascades to its payments', () async {
    final now = DateTime.utc(2026, 7, 26);
    await database.into(database.debtRows).insert(
      DebtRowsCompanion.insert(
        id: 'debt-1',
        title: 'قرض',
        totalMinorUnits: 500000000000000,
        currencyCode: 'IRT',
        scale: 8,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
    await database.into(database.debtPaymentRows).insert(
      DebtPaymentRowsCompanion.insert(
        id: 'debt-payment-1',
        debtId: 'debt-1',
        amountMinorUnits: 100000000000000,
        paidAtUtc: now,
        createdAtUtc: now,
      ),
    );

    await (database.delete(database.debtRows)
          ..where((row) => row.id.equals('debt-1')))
        .go();

    expect(await database.select(database.debtPaymentRows).get(), isEmpty);
  });
}
```

- [ ] **Step 3: Run the schema tests and verify RED**

Run:

```bash
cd app
flutter test test/core/database/app_database_test.dart
```

Expected: compilation fails because `AppDatabase` and table companions do not exist.

- [ ] **Step 4: Add native test dependency without upgrading pinned packages**

In `app/pubspec.yaml`, ensure the existing versions remain unchanged and add only:

```yaml
dev_dependencies:
  sqlite3: ^3.1.6
```

`drift`, `drift_flutter`, `drift_dev`, and `build_runner` already exist and must not be upgraded in this task.

- [ ] **Step 5: Implement the platform connection**

Create `app/lib/core/database/database_connection.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

DatabaseConnection openDashboardDatabase() {
  return driftDatabase(name: 'dashboard_shakhsi');
}
```

- [ ] **Step 6: Implement all six tables and database migration**

Create `app/lib/core/database/app_database.dart`:

```dart
import 'package:dashboard_shakhsi/core/database/database_connection.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

class TaskRows extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get priority => integer().check(priority.isBetweenValues(0, 3))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get completedAtUtc => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class FinanceTransactionRows extends Table {
  @override
  String get tableName => 'finance_transactions';

  TextColumn get id => text()();
  TextColumn get type => text().check(type.isIn(<String>['income', 'expense']))();
  TextColumn get title => text()();
  TextColumn get category => text()();
  IntColumn get amountMinorUnits => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('IRT'))();
  IntColumn get scale => integer().withDefault(const Constant(8))();
  DateTimeColumn get occurredAtUtc => dateTime()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

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
  TextColumn get debtId => text().references(
        DebtRows,
        #id,
        onDelete: KeyAction.cascade,
      )();
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
  IntColumn get installmentCount => integer().check(installmentCount.isBiggerThanValue(0))();
  TextColumn get currencyCode => text().withDefault(const Constant('IRT'))();
  IntColumn get scale => integer().withDefault(const Constant(8))();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();
  DateTimeColumn get archivedAtUtc => dateTime().nullable()();

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
```

- [ ] **Step 7: Generate Drift code**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app/lib/core/database/app_database.g.dart` is generated without errors.

- [ ] **Step 8: Run schema tests and verify GREEN**

Run:

```bash
flutter test test/core/database/app_database_test.dart
flutter analyze
```

Expected: schema tests pass and analyzer reports no issue in Task 1 files.

- [ ] **Step 9: Commit Task 1**

```bash
git add app/pubspec.yaml app/pubspec.lock \
  app/lib/core/database \
  app/test/core/database/app_database_test.dart \
  app/test/support/test_database.dart
git commit -m "feat: add drift schema for tasks and finance"
```

---

## Task 2: Add Persistence Domain Models and Validation

**Files:**
- Create: `app/lib/features/tasks/domain/task_item.dart`
- Create: `app/lib/features/tasks/domain/task_repository.dart`
- Create: `app/lib/features/finance/domain/finance_transaction.dart`
- Create: `app/lib/features/finance/domain/debt.dart`
- Create: `app/lib/features/finance/domain/installment_plan.dart`
- Create: `app/lib/features/finance/domain/finance_repository.dart`
- Create: `app/test/features/finance/domain/finance_domain_test.dart`

**Interfaces:**
- Produces immutable domain models independent of Drift generated classes.
- Produces repository contracts consumed by UI and implementations.
- Consumes existing `Money`, `ValidationFailure`, and `IdGenerator`.

- [ ] **Step 1: Write failing domain validation tests**

Create `app/test/features/finance/domain/finance_domain_test.dart`:

```dart
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/finance/domain/debt.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:dashboard_shakhsi/features/finance/domain/installment_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const oneToman = Money(
    minorUnits: 100000000,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );

  test('transaction rejects a zero amount', () {
    expect(
      () => FinanceTransaction.create(
        id: 'tx-1',
        type: FinanceTransactionType.expense,
        title: 'خرید',
        category: 'خوراک',
        amount: Money.zeroIRT,
        occurredAtUtc: DateTime.utc(2026, 7, 26),
        createdAtUtc: DateTime.utc(2026, 7, 26),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('debt exposes an exact remaining amount', () {
    final debt = Debt(
      id: 'debt-1',
      title: 'قرض',
      total: oneToman * 10,
      paid: oneToman * 3,
      createdAtUtc: DateTime.utc(2026, 7, 26),
      updatedAtUtc: DateTime.utc(2026, 7, 26),
    );

    expect(debt.remaining, oneToman * 7);
  });

  test('installment plan rejects paid count over total count', () {
    expect(
      () => InstallmentPlan(
        id: 'plan-1',
        title: 'قسط',
        perInstallment: oneToman,
        installmentCount: 2,
        paidCount: 3,
        createdAtUtc: DateTime.utc(2026, 7, 26),
        updatedAtUtc: DateTime.utc(2026, 7, 26),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
```

- [ ] **Step 2: Run domain tests and verify RED**

```bash
flutter test test/features/finance/domain/finance_domain_test.dart
```

Expected: imports and domain classes do not exist.

- [ ] **Step 3: Implement task domain and repository contract**

Create `task_item.dart` with:

```dart
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';

final class TaskItem {
  TaskItem({
    required this.id,
    required String title,
    required this.priority,
    required this.isDone,
    required this.sortOrder,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.completedAtUtc,
  }) : title = title.trim() {
    if (this.title.isEmpty) {
      throw const ValidationFailure('عنوان کار نمی‌تواند خالی باشد.');
    }
    if (priority < 0 || priority > 3) {
      throw const ValidationFailure('اولویت کار نامعتبر است.');
    }
    if (createdAtUtc.isLocal || updatedAtUtc.isLocal) {
      throw const ValidationFailure('زمان کار باید به‌صورت UTC ذخیره شود.');
    }
  }

  final String id;
  final String title;
  final int priority;
  final bool isDone;
  final int sortOrder;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? completedAtUtc;

  TaskItem copyWith({
    String? title,
    int? priority,
    bool? isDone,
    int? sortOrder,
    DateTime? updatedAtUtc,
    DateTime? completedAtUtc,
    bool clearCompletedAt = false,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      completedAtUtc:
          clearCompletedAt ? null : completedAtUtc ?? this.completedAtUtc,
    );
  }
}
```

Create `task_repository.dart` with the exact interface from the approved spec.

- [ ] **Step 4: Implement finance domain models**

Use these public shapes:

```dart
enum FinanceTransactionType { income, expense }

final class FinanceTransaction {
  FinanceTransaction.create({
    required this.id,
    required this.type,
    required String title,
    required String category,
    required this.amount,
    required this.occurredAtUtc,
    required this.createdAtUtc,
    DateTime? updatedAtUtc,
  })  : title = title.trim(),
        category = category.trim(),
        updatedAtUtc = updatedAtUtc ?? createdAtUtc {
    _validateExactPositiveMoney(amount);
    if (this.title.isEmpty) {
      throw const ValidationFailure('عنوان تراکنش نمی‌تواند خالی باشد.');
    }
    if (this.category.isEmpty) {
      throw const ValidationFailure('دسته تراکنش نمی‌تواند خالی باشد.');
    }
  }

  final String id;
  final FinanceTransactionType type;
  final String title;
  final String category;
  final Money amount;
  final DateTime occurredAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
}
```

`Debt` must expose `total`, `paid`, `remaining`, `settled`, and `progressForChart`.

`InstallmentPlan` must expose `perInstallment`, `installmentCount`, `paidCount`, `remainingCount`, `remaining`, `settled`, and `progressForChart`.

Use one shared private validation function per file or one public helper in `finance_transaction.dart`:

```dart
void validateExactPositiveMoney(Money value) {
  if (value.currencyCode != Money.tomanCurrencyCode ||
      value.scale != Money.financeScale ||
      !value.isPositive) {
    throw const ValidationFailure(
      'مبلغ باید بیشتر از صفر و با واحد تومان ثبت شود.',
    );
  }
}
```

- [ ] **Step 5: Implement finance repository contract**

Create `finance_repository.dart` with the approved interface plus these exact delete semantics:

```dart
abstract interface class FinanceRepository {
  Stream<List<FinanceTransaction>> watchTransactions();
  Stream<List<Debt>> watchDebts();
  Stream<List<InstallmentPlan>> watchInstallmentPlans();

  Future<void> addTransaction(FinanceTransaction transaction);
  Future<void> deleteTransaction(String id);

  Future<void> addDebt(Debt debt);
  Future<void> recordDebtPayment({
    required String debtId,
    required Money amount,
    required DateTime paidAt,
  });
  Future<void> deleteDebt(String id);

  Future<void> addInstallmentPlan(InstallmentPlan plan);
  Future<void> payNextInstallment({
    required String planId,
    required DateTime paidAt,
  });
  Future<void> deleteInstallmentPlan(String id);
}
```

- [ ] **Step 6: Run domain tests and verify GREEN**

```bash
dart format lib/features/tasks/domain lib/features/finance/domain \
  test/features/finance/domain/finance_domain_test.dart
flutter test test/features/finance/domain/finance_domain_test.dart
flutter analyze
```

- [ ] **Step 7: Commit Task 2**

```bash
git add app/lib/features/tasks/domain \
  app/lib/features/finance/domain \
  app/test/features/finance/domain/finance_domain_test.dart
git commit -m "feat: add task and finance persistence domain"
```

---

## Task 3: Implement and Verify the Drift Task Repository

**Files:**
- Create: `app/lib/features/tasks/data/drift_task_repository.dart`
- Create: `app/test/features/tasks/data/drift_task_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, generated `TaskRow`, `TaskRepository`, `TaskItem`.
- Produces: `DriftTaskRepository implements TaskRepository`.

- [ ] **Step 1: Write failing repository tests**

The test must cover stream creation, update, completion, deletion of completed tasks, reorder, and reopening the same file-backed database. Use `SequenceIdGenerator` only in command/application layers; repositories accept complete domain objects.

Create tests with this setup:

```dart
late AppDatabase database;
late DriftTaskRepository repository;

setUp(() {
  database = openTestDatabase();
  repository = DriftTaskRepository(database);
});

tearDown(() async {
  await database.close();
});
```

First test:

```dart
test('watchAll emits inserted tasks in stable sort order', () async {
  final now = DateTime.utc(2026, 7, 26);
  final values = expectLater(
    repository.watchAll(),
    emitsInOrder(<Object>[
      isEmpty,
      predicate<List<TaskItem>>(
        (items) => items.map((item) => item.id).toList().join(',') ==
            'task-b,task-a',
      ),
    ]),
  );

  await repository.create(
    TaskItem(
      id: 'task-a',
      title: 'اول',
      priority: 0,
      isDone: false,
      sortOrder: 2,
      createdAtUtc: now,
      updatedAtUtc: now,
    ),
  );
  await repository.create(
    TaskItem(
      id: 'task-b',
      title: 'دوم',
      priority: 3,
      isDone: false,
      sortOrder: 1,
      createdAtUtc: now,
      updatedAtUtc: now,
    ),
  );

  await values;
});
```

Add separate tests for `setDone`, `deleteCompleted`, and `reorder`.

- [ ] **Step 2: Run repository tests and verify RED**

```bash
flutter test test/features/tasks/data/drift_task_repository_test.dart
```

Expected: `DriftTaskRepository` does not exist.

- [ ] **Step 3: Implement row mapping and repository methods**

`watchAll()` must order by `sortOrder ASC`, then `createdAtUtc ASC`.

Use Drift companions with explicit `Value` wrappers for updates. `setDone` must update `completedAtUtc` to `changedAt.toUtc()` when completing and `null` when reopening.

`reorder` must be atomic:

```dart
await database.transaction(() async {
  for (var index = 0; index < orderedIds.length; index++) {
    await (database.update(database.taskRows)
          ..where((row) => row.id.equals(orderedIds[index])))
        .write(
      TaskRowsCompanion(
        sortOrder: Value<int>(index),
        updatedAtUtc: Value<DateTime>(DateTime.now().toUtc()),
      ),
    );
  }
});
```

Catch `SqliteException` and unexpected storage errors, then throw:

```dart
PersistenceFailure(
  'ذخیره تغییرات کارها انجام نشد.',
  cause: error,
)
```

- [ ] **Step 4: Run task repository tests and verify GREEN**

```bash
dart format app/lib/features/tasks/data \
  app/test/features/tasks/data/drift_task_repository_test.dart
flutter test test/features/tasks/data/drift_task_repository_test.dart
flutter analyze
```

- [ ] **Step 5: Commit Task 3**

```bash
git add app/lib/features/tasks/data \
  app/test/features/tasks/data/drift_task_repository_test.dart
git commit -m "feat: persist tasks through drift repository"
```

---

## Task 4: Implement Transactional Finance Repository

**Files:**
- Create: `app/lib/features/finance/data/drift_finance_repository.dart`
- Create: `app/test/features/finance/data/drift_finance_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `FinanceRepository`, finance domain models, `Money`, `IdGenerator`.
- Produces: `DriftFinanceRepository` with atomic debt and installment payment methods.

- [ ] **Step 1: Write failing exact-money and payment tests**

Required tests:

1. Income and expense round-trip with `minorUnits = 123456712345678`.
2. `watchDebts()` joins payment sums and emits exact `paid`/`remaining`.
3. `recordDebtPayment()` rejects a payment larger than remaining.
4. `payNextInstallment()` inserts the next sequential number.
5. A fully paid plan rejects another payment.
6. Deleting a parent cascades to payment rows.

Use this overpayment expectation:

```dart
await expectLater(
  repository.recordDebtPayment(
    debtId: 'debt-1',
    amount: const Money(
      minorUnits: 900000000,
      currencyCode: 'IRT',
      scale: 8,
    ),
    paidAt: now,
  ),
  throwsA(
    isA<ValidationFailure>().having(
      (failure) => failure.userMessage,
      'userMessage',
      'مبلغ پرداخت از مانده بدهی بیشتر است.',
    ),
  ),
);
```

- [ ] **Step 2: Run finance repository tests and verify RED**

```bash
flutter test test/features/finance/data/drift_finance_repository_test.dart
```

- [ ] **Step 3: Implement transaction stream mapping**

Map `type` string strictly:

```dart
FinanceTransactionType _transactionType(String value) {
  return switch (value) {
    'income' => FinanceTransactionType.income,
    'expense' => FinanceTransactionType.expense,
    _ => throw PersistenceFailure('نوع تراکنش ذخیره‌شده نامعتبر است.'),
  };
}
```

Order transactions by `occurredAtUtc DESC`, then `createdAtUtc DESC`.

- [ ] **Step 4: Implement debt aggregate stream**

Use a left join between `DebtRows` and `DebtPaymentRows`, filter `archivedAtUtc.isNull()`, group rows in Dart by debt id, and sum payment `amountMinorUnits` as integers. Construct `Money` only after summing.

Do not use SQL `REAL`, Dart `double`, or `majorUnitsForChart` in repository calculations.

- [ ] **Step 5: Implement atomic debt payment**

Inside one `database.transaction`:

1. Load active debt by id.
2. Sum existing payment minor units.
3. Calculate integer remaining.
4. Reject non-positive amount.
5. Reject amount greater than remaining.
6. Insert `DebtPaymentRowsCompanion` with UUID from injected `IdGenerator`.

Constructor:

```dart
DriftFinanceRepository(
  this.database, {
  IdGenerator idGenerator = const UuidV7IdGenerator(),
}) : _idGenerator = idGenerator;
```

- [ ] **Step 6: Implement installment aggregate and atomic next payment**

Inside one transaction:

1. Load active plan.
2. Read paid installment numbers ordered ascending.
3. Set `nextNumber = paidNumbers.length + 1`.
4. Reject when `nextNumber > installmentCount`.
5. Insert payment with `amountMinorUnits = perInstallmentMinorUnits`.

The unique database constraint is the final defense against duplicate concurrent payment requests.

- [ ] **Step 7: Run finance repository tests and verify GREEN**

```bash
dart format app/lib/features/finance/data \
  app/test/features/finance/data/drift_finance_repository_test.dart
flutter test test/features/finance/data/drift_finance_repository_test.dart
flutter analyze
```

- [ ] **Step 8: Commit Task 4**

```bash
git add app/lib/features/finance/data \
  app/test/features/finance/data/drift_finance_repository_test.dart
git commit -m "feat: persist finance data and payments atomically"
```

---

## Task 5: Move Finance Calculations to Domain Services

**Files:**
- Create: `app/lib/features/finance/application/finance_summary.dart`
- Create: `app/lib/features/finance/application/finance_report_service.dart`
- Create: `app/test/features/finance/application/finance_report_service_test.dart`
- Modify: `app/lib/features/dashboard/presentation/widgets/finance_charts.dart`
- Modify: `app/lib/features/dashboard/presentation/widgets/finance_preview_models.dart`

**Interfaces:**
- Consumes: domain transactions, debts, installment plans.
- Produces: `FinanceSummary`, `FinanceMonthPoint`, `FinanceCategoryPoint`, `FinanceDayPoint`, and `FinanceReportService`.

- [ ] **Step 1: Copy current finance math behavior into failing domain-service tests**

Port the existing `finance_preview_math_test.dart` scenarios to domain objects and add an eight-decimal exact-sum case:

```dart
test('summary preserves exact eight-decimal values', () {
  final summary = service.summary(
    transactions: <FinanceTransaction>[
      transaction('a', FinanceTransactionType.income, '0.10000001'),
      transaction('b', FinanceTransactionType.income, '0.20000002'),
      transaction('c', FinanceTransactionType.expense, '0.00000003'),
    ],
    debts: const <Debt>[],
    installments: const <InstallmentPlan>[],
    now: DateTime(2026, 7, 26),
  );

  expect(summary.balance.formatMajorUnits(usePersianDigits: false), '0.3');
});
```

- [ ] **Step 2: Run service tests and verify RED**

```bash
flutter test test/features/finance/application/finance_report_service_test.dart
```

- [ ] **Step 3: Implement service by moving existing algorithms unchanged**

Move the logic for:

- Current Jalali month totals.
- Six-month trend.
- Expense category aggregation.
- Seven-day expense series.
- Jalali month labels and weekday labels.

All sums remain `Money`. Only chart widgets read `majorUnitsForChart`.

- [ ] **Step 4: Change chart imports to domain application points**

`finance_charts.dart` must import `finance_summary.dart` instead of `finance_preview_models.dart`.

Keep dimensions, keys, colors, painters, and tooltips unchanged.

- [ ] **Step 5: Run service and chart tests**

```bash
dart format app/lib/features/finance/application \
  app/lib/features/dashboard/presentation/widgets/finance_charts.dart
flutter test test/features/finance/application/finance_report_service_test.dart
flutter test test/features/dashboard/finance_preview_math_test.dart
flutter analyze
```

Keep `finance_preview_models.dart` temporarily as a re-export or compatibility adapter until Task 8 removes all UI references.

- [ ] **Step 6: Commit Task 5**

```bash
git add app/lib/features/finance/application \
  app/lib/features/dashboard/presentation/widgets/finance_charts.dart \
  app/lib/features/dashboard/presentation/widgets/finance_preview_models.dart \
  app/test/features/finance/application/finance_report_service_test.dart
git commit -m "refactor: move finance reports to domain service"
```

---

## Task 6: Add Riverpod Database and Repository Providers

**Files:**
- Create: `app/lib/core/database/database_providers.dart`
- Create: `app/lib/features/tasks/application/task_providers.dart`
- Create: `app/lib/features/finance/application/finance_providers.dart`
- Modify: `app/lib/app/bootstrap/app_bootstrap.dart`
- Create: `app/test/core/database/database_providers_test.dart`

**Interfaces:**
- Produces: `appDatabaseProvider`, `taskRepositoryProvider`, `financeRepositoryProvider`.
- Produces: `watchTasksProvider`, `watchTransactionsProvider`, `watchDebtsProvider`, `watchInstallmentPlansProvider`.
- Supports provider overrides in widget tests.

- [ ] **Step 1: Write failing provider lifecycle test**

The test must override `appDatabaseProvider`, read repository providers, insert one record, dispose the container, and confirm the overridden database can be closed exactly once.

- [ ] **Step 2: Run provider test and verify RED**

```bash
flutter test test/core/database/database_providers_test.dart
```

- [ ] **Step 3: Implement providers**

Use:

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DriftTaskRepository(ref.watch(appDatabaseProvider));
});

final watchTasksProvider = StreamProvider<List<TaskItem>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});
```

Implement corresponding finance providers.

- [ ] **Step 4: Keep bootstrap ProviderScope and make no visual changes**

`bootstrapApp()` already wraps the app in `ProviderScope`; retain that. Do not eagerly open the database in `bootstrapApp`. Drift opens on first query, and `ref.onDispose` owns closure in tests and application teardown.

- [ ] **Step 5: Run provider tests and verify GREEN**

```bash
dart format app/lib/core/database/database_providers.dart \
  app/lib/features/tasks/application/task_providers.dart \
  app/lib/features/finance/application/finance_providers.dart \
  app/test/core/database/database_providers_test.dart
flutter test test/core/database/database_providers_test.dart
flutter analyze
```

- [ ] **Step 6: Commit Task 6**

```bash
git add app/lib/core/database/database_providers.dart \
  app/lib/features/tasks/application \
  app/lib/features/finance/application/finance_providers.dart \
  app/lib/app/bootstrap/app_bootstrap.dart \
  app/test/core/database/database_providers_test.dart
git commit -m "feat: expose persistent repositories through riverpod"
```

---

## Task 7: Connect the Tasks Panel Without Visual Changes

**Files:**
- Modify: `app/lib/features/dashboard/presentation/widgets/tasks_panel.dart`
- Modify: `app/test/features/dashboard/tasks_panel_test.dart`

**Interfaces:**
- Consumes: `watchTasksProvider`, `taskRepositoryProvider`, `TaskItem`, `UuidV7IdGenerator`.
- Preserves all existing keys, labels, icons, animations, and filter/search state.

- [ ] **Step 1: Update widget test subject with in-memory persistence overrides**

Create one test harness per file:

```dart
Widget subject(AppDatabase database) {
  return ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
    ],
    child: MaterialApp(
      theme: OriginalTheme.light(),
      home: const Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(width: 780, child: TasksPanel()),
        ),
      ),
    ),
  );
}
```

Create and close a fresh `AppDatabase(NativeDatabase.memory())` for every test.

Add a test that pumps the panel, inserts a task through the repository, pumps again, and verifies the task appears without rebuilding the entire app.

- [ ] **Step 2: Run task widget tests and verify RED**

```bash
flutter test test/features/dashboard/tasks_panel_test.dart
```

Expected: current panel ignores provider data.

- [ ] **Step 3: Convert panel to ConsumerStatefulWidget**

Change only state ownership:

```dart
final class TasksPanel extends ConsumerStatefulWidget { ... }
final class _TasksPanelState extends ConsumerState<TasksPanel> { ... }
```

Remove `_tasks` and `_nextTaskId`. Keep controllers, `_priority`, `_filter`, `_sort`, and `_removingTaskIds`.

Change `_removingTaskIds` to `Set<String>`.

- [ ] **Step 4: Render provider states inside the existing panel shell**

Use:

```dart
final tasksAsync = ref.watch(watchTasksProvider);
return tasksAsync.when(
  loading: _buildLoadingState,
  error: (error, stackTrace) => _buildPersistenceError(error),
  data: (tasks) => _buildTaskContent(tasks),
);
```

`_buildTaskContent` must reuse the existing layout and animations. Loading uses the existing empty-space dimensions without a new Material spinner. Error copy:

```text
ذخیره‌سازی کارها در دسترس نیست
```

Retry button invalidates `watchTasksProvider`.

- [ ] **Step 5: Replace UI mutations with repository calls**

- Add: create `TaskItem` with UUID, UTC timestamps, and `sortOrder = current maximum + 1`.
- Edit: `repository.update(task.copyWith(...))`.
- Complete/reopen: `repository.setDone`.
- Delete: keep current removal animation, then await `repository.delete(id)`.
- Clear completed: `repository.deleteCompleted()`.
- Priority click on an existing row: update the item through the repository.

Catch `AppFailure`, show its Persian `userMessage` in the existing toast/snackbar style, and leave provider data unchanged.

- [ ] **Step 6: Run task tests and full analyzer**

```bash
dart format app/lib/features/dashboard/presentation/widgets/tasks_panel.dart \
  app/test/features/dashboard/tasks_panel_test.dart
flutter test test/features/dashboard/tasks_panel_test.dart
flutter analyze
```

- [ ] **Step 7: Manually verify task restart behavior**

```bash
flutter run -d linux
```

Add two tasks, complete one, quit with `q`, run again, and verify both tasks and status counts persist.

- [ ] **Step 8: Commit Task 7**

```bash
git add app/lib/features/dashboard/presentation/widgets/tasks_panel.dart \
  app/test/features/dashboard/tasks_panel_test.dart
git commit -m "feat: connect tasks panel to persistent stream"
```

---

## Task 8: Connect the Finance Panel Without Visual Changes

**Files:**
- Modify: `app/lib/features/dashboard/presentation/widgets/finance_panel.dart`
- Modify: `app/lib/features/dashboard/presentation/widgets/finance_preview_models.dart`
- Modify: `app/test/features/dashboard/finance_panel_test.dart`
- Modify: `app/test/features/dashboard/finance_preview_math_test.dart`

**Interfaces:**
- Consumes finance stream providers, `FinanceReportService`, and `FinanceRepository`.
- Preserves all form keys, transaction labels, charts, cards, and exact-money input behavior.

- [ ] **Step 1: Update finance widget tests with database override**

Use the same `ProviderScope` pattern as Task 7. Add a test that inserts an exact eight-decimal transaction through `financeRepositoryProvider` and observes card/recent-list updates through the stream.

- [ ] **Step 2: Run finance widget tests and verify RED**

```bash
flutter test test/features/dashboard/finance_panel_test.dart
```

- [ ] **Step 3: Convert FinancePanel to ConsumerStatefulWidget**

Remove local lists and integer ids. Keep controllers, selected entry type, selected category, chart filters, and transaction list filters.

Read:

```dart
final transactions = ref.watch(watchTransactionsProvider);
final debts = ref.watch(watchDebtsProvider);
final installments = ref.watch(watchInstallmentPlansProvider);
```

Combine the three AsyncValues into one existing panel body. Do not add nested Scaffolds or Material progress indicators.

- [ ] **Step 4: Replace form submissions with repository commands**

- Expense/income: construct `FinanceTransaction.create` and call `addTransaction`.
- Debt: construct `Debt` with zero paid, call `addDebt`, then call `recordDebtPayment` when the initial paid field is positive. Both operations must be represented as one application action; add `addDebtWithInitialPayment` to repository only if the two operations cannot be atomic through an explicit `AppDatabase.transaction` method in the implementation.
- Installment: construct `InstallmentPlan` with zero paid, call `addInstallmentPlan`, then register initial paid installments sequentially in one transaction. Prefer adding:

```dart
Future<void> addInstallmentPlanWithPaidCount({
  required InstallmentPlan plan,
  required int paidCount,
  required DateTime paidAt,
});
```

If this method is added, update the interface, Drift implementation, and repository tests in the same commit before wiring the UI.

- [ ] **Step 5: Replace payment/delete controls**

- Debt payment button calls `recordDebtPayment` with the user-entered exact amount.
- Installment button calls `payNextInstallment`.
- Delete controls call repository deletes.
- Recent transaction delete calls `deleteTransaction`.

The screen must wait for the repository Future before clearing the form. A failed write leaves entered values intact and shows the Persian failure.

- [ ] **Step 6: Feed domain service results to existing cards and charts**

Calculate `FinanceSummary`, trend, categories, and week points from provider data. Continue using `Money.formatMajorUnits` for labels and `majorUnitsForChart` only inside chart painters.

Remove the obsolete preview classes after the final import is gone. Keep the compatibility file only as a re-export when a staged commit requires it, then delete it before Task 8 ends.

- [ ] **Step 7: Run finance and dashboard tests**

```bash
dart format app/lib/features/dashboard/presentation/widgets/finance_panel.dart \
  app/lib/features/dashboard/presentation/widgets/finance_preview_models.dart \
  app/test/features/dashboard/finance_panel_test.dart \
  app/test/features/dashboard/finance_preview_math_test.dart
flutter test test/features/dashboard/finance_panel_test.dart
flutter test test/features/dashboard/finance_preview_math_test.dart
flutter test test/features/dashboard/original_dashboard_screen_test.dart
flutter analyze
```

- [ ] **Step 8: Manually verify finance restart behavior**

Add one exact-decimal income, one expense, one partially paid debt, and one installment plan. Quit and relaunch. Verify cards, recent transactions, debt progress, installment progress, and all three charts reproduce the same values.

- [ ] **Step 9: Commit Task 8**

```bash
git add app/lib/features/dashboard/presentation/widgets/finance_panel.dart \
  app/lib/features/dashboard/presentation/widgets/finance_charts.dart \
  app/lib/features/dashboard/presentation/widgets/finance_preview_models.dart \
  app/lib/features/finance \
  app/test/features/dashboard/finance_panel_test.dart \
  app/test/features/dashboard/finance_preview_math_test.dart \
  app/test/features/dashboard/original_dashboard_screen_test.dart
git commit -m "feat: connect finance panel to persistent streams"
```

---

## Task 9: Verify File-Backed Restart, Bootstrap, and Regression Safety

**Files:**
- Create: `app/test/core/database/database_restart_test.dart`
- Modify: `app/test/app/bootstrap/app_bootstrap_test.dart`
- Modify: `app/test/features/dashboard/original_dashboard_screen_test.dart`

**Interfaces:**
- Verifies the entire persistence boundary independently from UI process lifetime.

- [ ] **Step 1: Write a file-backed restart test**

Use `Directory.systemTemp.createTemp`, `NativeDatabase(File(path))`, and two separate `AppDatabase` instances:

```dart
test('tasks and exact finance data survive closing and reopening', () async {
  final directory = await Directory.systemTemp.createTemp('dashboard-db-');
  final file = File('${directory.path}/restart.sqlite');

  final first = AppDatabase(NativeDatabase(file));
  final taskRepository = DriftTaskRepository(first);
  final financeRepository = DriftFinanceRepository(
    first,
    idGenerator: SequenceIdGenerator(prefix: 'restart'),
  );

  // Insert one task, one 8-decimal transaction, one debt payment,
  // and one installment payment using public repository APIs.
  await first.close();

  final second = AppDatabase(NativeDatabase(file));
  final reopenedTasks = await DriftTaskRepository(second).watchAll().first;
  final reopenedTransactions =
      await DriftFinanceRepository(second).watchTransactions().first;

  expect(reopenedTasks.single.title, 'کار ماندگار');
  expect(reopenedTransactions.single.amount.minorUnits, 123456712345678);

  await second.close();
  await directory.delete(recursive: true);
});
```

Fill the omitted insert calls with the public repository methods created in Tasks 3 and 4; do not insert table companions directly in this test.

- [ ] **Step 2: Run restart test and verify RED/GREEN behavior**

Before persistence UI integration, this test should pass at repository level. Run:

```bash
flutter test test/core/database/database_restart_test.dart
```

- [ ] **Step 3: Update bootstrap tests with database override**

All app-level tests must override `appDatabaseProvider` with `AppDatabase(NativeDatabase.memory())`, close it in teardown, and keep existing Persian/RTL assertions.

- [ ] **Step 4: Run generated-code freshness check**

```bash
dart run build_runner build --delete-conflicting-outputs

git diff --exit-code -- app/lib/core/database/app_database.g.dart
```

Expected: build runner succeeds and generated file has no uncommitted difference.

- [ ] **Step 5: Run full verification**

```bash
flutter analyze
flutter test
flutter build linux --debug
```

Expected:

```text
No issues found!
All tests passed!
```

and Linux debug build exits with status `0`.

- [ ] **Step 6: Run visual regression smoke test**

```bash
flutter run -d linux
```

Check all four approved reference states:

- Tasks, dark.
- Finance, dark.
- Tasks, light.
- Finance, light.

There must be no visible change in Glass opacity, background blur, input sizes, task row appearance, finance card geometry, or chart surfaces.

- [ ] **Step 7: Commit final verification artifacts**

```bash
git add app/lib app/test app/pubspec.yaml app/pubspec.lock
git commit -m "test: verify persistent dashboard restart behavior"
```

---

## Final Acceptance Checklist

- [ ] `dashboard_shakhsi.sqlite` is created on native platforms.
- [ ] Schema version is `1` and all six tables exist.
- [ ] Foreign keys are enabled on every connection.
- [ ] Parent deletion cascades to debt/installment payments.
- [ ] Duplicate installment numbers are rejected.
- [ ] Task create/edit/complete/delete/reorder survive restart.
- [ ] Income and expense round-trip with all eight decimal digits.
- [ ] Debt overpayment is rejected atomically.
- [ ] Installment overpayment is rejected atomically.
- [ ] Finance summaries and reports use integer-backed `Money` calculations.
- [ ] UI updates only after database commit and stream emission.
- [ ] Error states show Persian copy and retry without Material redesign.
- [ ] Existing task and finance widget tests remain behaviorally equivalent.
- [ ] `flutter analyze` reports zero issues.
- [ ] `flutter test` reports zero failures.
- [ ] `flutter build linux --debug` succeeds.
- [ ] Manual close/relaunch preserves tasks and all finance data.
- [ ] Approved original-style screenshots have no material visual regression.

## Self-Review Result

- Spec coverage: All approved tables, repository operations, streams, UTC storage, exact money, validation, migration version, restart testing, and visual-preservation requirements are mapped to tasks.
- Placeholder scan: No incomplete implementation markers are present; generated Drift code is explicitly produced by build_runner.
- Type consistency: Repository signatures, provider names, domain model fields, table columns, and test helpers are consistent across tasks.
- Scope: Cloud sync, authentication, SQLCipher, local notifications, advanced monthly budgeting, and import/export remain outside this plan.
