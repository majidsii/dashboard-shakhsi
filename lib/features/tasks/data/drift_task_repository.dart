import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:drift/drift.dart';

final class DriftTaskRepository implements TaskRepository {
  const DriftTaskRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<TaskItem>> watchAll() {
    return _database.select(_database.taskRows).watch().map((rows) {
      final items = rows.map(_taskFromRow).toList(growable: false)
        ..sort(_compareTasks);
      return items;
    });
  }

  @override
  Stream<List<TaskItem>> watchByStatus(TaskStatus status) {
    final query = _database.select(_database.taskRows)
      ..where((row) => row.status.equals(status.storageValue))
      ..orderBy(<OrderingTerm Function(TaskRows)>[
        (row) => OrderingTerm.asc(row.positionInStatus),
        (row) => OrderingTerm.asc(row.createdAtUtc),
        (row) => OrderingTerm.asc(row.id),
      ]);

    return query.watch().map(
      (rows) => rows.map(_taskFromRow).toList(growable: false),
    );
  }

  @override
  Future<TaskItem?> getById(String id) async {
    final row = await (_database.select(
      _database.taskRows,
    )..where((candidate) => candidate.id.equals(id))).getSingleOrNull();

    return row == null ? null : _taskFromRow(row);
  }

  @override
  Future<void> create(TaskItem task) {
    return _database.transaction(() async {
      final allocation = await _database
          .customSelect(
            '''
          SELECT
            COALESCE(MAX(display_number), 0) + 1 AS next_display_number,
            (
              SELECT COUNT(*)
              FROM tasks
              WHERE status = ?
            ) AS next_position
          FROM tasks
        ''',
            variables: <Variable<Object>>[
              Variable<String>(task.status.storageValue),
            ],
            readsFrom: {_database.taskRows},
          )
          .getSingle();

      final nextDisplayNumber = allocation.read<int>('next_display_number');
      final nextPosition = allocation.read<int>('next_position');

      await _database
          .into(_database.taskRows)
          .insert(
            _companionFromTask(
              task,
              displayNumber: nextDisplayNumber,
              positionInStatus: nextPosition,
            ),
          );
    });
  }

  @override
  Future<void> update(TaskItem task) async {
    await (_database.update(
      _database.taskRows,
    )..where((row) => row.id.equals(task.id))).write(
      TaskRowsCompanion(
        title: Value<String>(task.title),
        priority: Value<int>(task.priority),
        status: Value<String>(task.status.storageValue),
        positionInStatus: Value<int>(task.positionInStatus),
        updatedAtUtc: Value<DateTime>(task.updatedAtUtc),
        completedAtUtc: Value<DateTime?>(task.completedAtUtc),
        canceledAtUtc: Value<DateTime?>(task.canceledAtUtc),
      ),
    );
  }

  @override
  Future<void> setDone(String id, bool isDone, DateTime changedAt) async {
    final changedAtUtc = changedAt.toUtc();

    await (_database.update(
      _database.taskRows,
    )..where((row) => row.id.equals(id))).write(
      TaskRowsCompanion(
        status: Value<String>(
          isDone
              ? TaskStatus.completed.storageValue
              : TaskStatus.planned.storageValue,
        ),
        updatedAtUtc: Value<DateTime>(changedAtUtc),
        completedAtUtc: Value<DateTime?>(isDone ? changedAtUtc : null),
        canceledAtUtc: const Value<DateTime?>(null),
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
        )..where((row) => row.status.equals(TaskStatus.completed.storageValue)))
        .go();
  }

  @override
  Future<void> reorder(List<String> orderedIds) {
    return _database.transaction(() async {
      final rows = await (_database.select(
        _database.taskRows,
      )..where((row) => row.id.isIn(orderedIds))).get();
      final byId = <String, TaskRow>{for (final row in rows) row.id: row};
      final nextPositionByStatus = <String, int>{};

      for (final id in orderedIds) {
        final row = byId[id];
        if (row == null) {
          continue;
        }
        final nextPosition = nextPositionByStatus[row.status] ?? 0;
        nextPositionByStatus[row.status] = nextPosition + 1;

        await (_database.update(
          _database.taskRows,
        )..where((candidate) => candidate.id.equals(id))).write(
          TaskRowsCompanion(positionInStatus: Value<int>(nextPosition)),
        );
      }
    });
  }
}

TaskItem _taskFromRow(TaskRow row) {
  return TaskItem(
    id: row.id,
    displayNumber: row.displayNumber,
    title: row.title,
    priority: row.priority,
    status: TaskStatus.parseStorage(row.status),
    positionInStatus: row.positionInStatus,
    createdAtUtc: row.createdAtUtc.toUtc(),
    updatedAtUtc: row.updatedAtUtc.toUtc(),
    completedAtUtc: row.completedAtUtc?.toUtc(),
    canceledAtUtc: row.canceledAtUtc?.toUtc(),
  );
}

TaskRowsCompanion _companionFromTask(
  TaskItem task, {
  int? displayNumber,
  int? positionInStatus,
}) {
  return TaskRowsCompanion(
    id: Value<String>(task.id),
    displayNumber: Value<int>(displayNumber ?? task.displayNumber),
    title: Value<String>(task.title),
    priority: Value<int>(task.priority),
    status: Value<String>(task.status.storageValue),
    positionInStatus: Value<int>(positionInStatus ?? task.positionInStatus),
    createdAtUtc: Value<DateTime>(task.createdAtUtc),
    updatedAtUtc: Value<DateTime>(task.updatedAtUtc),
    completedAtUtc: Value<DateTime?>(task.completedAtUtc),
    canceledAtUtc: Value<DateTime?>(task.canceledAtUtc),
  );
}

int _compareTasks(TaskItem left, TaskItem right) {
  final statusOrder = left.status.index.compareTo(right.status.index);
  if (statusOrder != 0) {
    return statusOrder;
  }

  final positionOrder = left.positionInStatus.compareTo(right.positionInStatus);
  if (positionOrder != 0) {
    return positionOrder;
  }

  final createdAtOrder = left.createdAtUtc.compareTo(right.createdAtUtc);
  if (createdAtOrder != 0) {
    return createdAtOrder;
  }

  return left.id.compareTo(right.id);
}
