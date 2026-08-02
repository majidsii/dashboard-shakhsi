import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:drift/drift.dart';

final class DriftTaskRepository implements TaskRepository {
  const DriftTaskRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<TaskItem>> watchAll() {
    final query = _database.select(_database.taskRows)
      ..orderBy(<OrderingTerm Function(TaskRows)>[
        (row) => OrderingTerm.asc(row.sortOrder),
        (row) => OrderingTerm.asc(row.createdAtUtc),
        (row) => OrderingTerm.asc(row.id),
      ]);

    return query.watch().map((rows) {
      final displayRows = rows.toList(growable: false)
        ..sort((left, right) {
          final createdAtOrder = left.createdAtUtc.compareTo(
            right.createdAtUtc,
          );
          if (createdAtOrder != 0) {
            return createdAtOrder;
          }
          return left.id.compareTo(right.id);
        });
      final displayNumbers = <String, int>{
        for (final entry in displayRows.indexed) entry.$2.id: entry.$1 + 1,
      };

      return rows
          .map(
            (row) => TaskItem(
              id: row.id,
              displayNumber: displayNumbers[row.id]!,
              title: row.title,
              priority: row.priority,
              status: row.isDone ? TaskStatus.completed : TaskStatus.planned,
              positionInStatus: row.sortOrder,
              createdAtUtc: row.createdAtUtc.toUtc(),
              updatedAtUtc: row.updatedAtUtc.toUtc(),
              completedAtUtc: row.isDone
                  ? (row.completedAtUtc ?? row.updatedAtUtc).toUtc()
                  : null,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> create(TaskItem task) async {
    await _database.into(_database.taskRows).insert(_companionFromTask(task));
  }

  @override
  Future<void> update(TaskItem task) async {
    await (_database.update(
      _database.taskRows,
    )..where((row) => row.id.equals(task.id))).write(_companionFromTask(task));
  }

  @override
  Future<void> setDone(String id, bool isDone, DateTime changedAt) async {
    final changedAtUtc = changedAt.toUtc();

    await (_database.update(
      _database.taskRows,
    )..where((row) => row.id.equals(id))).write(
      TaskRowsCompanion(
        isDone: Value<bool>(isDone),
        updatedAtUtc: Value<DateTime>(changedAtUtc),
        completedAtUtc: Value<DateTime?>(isDone ? changedAtUtc : null),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (_database.delete(
      _database.taskRows,
    )..where((row) => row.id.equals(id))).go();
  }

  @override
  Future<void> deleteCompleted() async {
    await (_database.delete(
      _database.taskRows,
    )..where((row) => row.isDone.equals(true))).go();
  }

  @override
  Future<void> reorder(List<String> orderedIds) {
    return _database.transaction(() async {
      for (var index = 0; index < orderedIds.length; index++) {
        await (_database.update(_database.taskRows)
              ..where((row) => row.id.equals(orderedIds[index])))
            .write(TaskRowsCompanion(sortOrder: Value<int>(index)));
      }
    });
  }
}

TaskRowsCompanion _companionFromTask(TaskItem task) {
  if (task.status == TaskStatus.inProgress ||
      task.status == TaskStatus.canceled) {
    throw const ValidationFailure(
      'این وضعیت کار پس از مهاجرت پایگاه داده قابل ذخیره است.',
    );
  }

  final isDone = task.status == TaskStatus.completed;

  return TaskRowsCompanion(
    id: Value<String>(task.id),
    title: Value<String>(task.title),
    priority: Value<int>(task.priority),
    isDone: Value<bool>(isDone),
    sortOrder: Value<int>(task.positionInStatus),
    createdAtUtc: Value<DateTime>(task.createdAtUtc),
    updatedAtUtc: Value<DateTime>(task.updatedAtUtc),
    completedAtUtc: Value<DateTime?>(isDone ? task.completedAtUtc : null),
  );
}
