import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:dashboard_shakhsi/features/tasks/data/drift_task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository repository;

  var sharedDatabaseOpen = false;
  setUp(() {
    database = openTestDatabase();
    repository = DriftTaskRepository(database);
    sharedDatabaseOpen = true;
  });
  tearDown(() async {
    if (sharedDatabaseOpen) {
      await database.close();
    }
  });

  test('watchAll emits inserted tasks in stable sort order', () async {
    final now = DateTime.utc(2026, 7, 26, 10);

    expect(await repository.watchAll().first, isEmpty);

    final twoTasks = repository.watchAll().firstWhere(
      (items) => items.length == 2,
    );

    await repository.create(
      _task(
        id: 'task-a',
        displayNumber: 1,
        title: 'اول',
        priority: 0,
        sortOrder: 2,
        now: now,
      ),
    );
    await repository.create(
      _task(
        id: 'task-b',
        title: 'دوم',
        priority: 3,
        sortOrder: 1,
        now: now.add(const Duration(minutes: 1)),
      ),
    );

    final items = await twoTasks;

    expect(items.map((item) => item.id).toList(), <String>['task-b', 'task-a']);
  });

  test('update persists all editable task fields', () async {
    final now = DateTime.utc(2026, 7, 26, 11);
    final original = _task(
      id: 'task-1',
      displayNumber: 1,
      title: 'عنوان قدیمی',
      priority: 0,
      sortOrder: 3,
      now: now,
    );
    await repository.create(original);

    final updated = original.copyWith(
      title: 'عنوان جدید',
      priority: 2,
      positionInStatus: 1,
      updatedAtUtc: now.add(const Duration(hours: 1)),
    );

    final emission = repository.watchAll().firstWhere(
      (items) => items.length == 1 && items.single.title == 'عنوان جدید',
    );

    await repository.update(updated);

    expect((await emission).single, updated);
  });

  test('setDone stores UTC completion and clears it when reopened', () async {
    final now = DateTime.utc(2026, 7, 26, 12);
    await repository.create(
      _task(
        id: 'task-1',
        title: 'تکمیل کار',
        priority: 1,
        sortOrder: 0,
        now: now,
      ),
    );

    final changedAt = DateTime(2026, 7, 26, 16, 30);
    final completedEmission = repository.watchAll().firstWhere(
      (items) =>
          items.length == 1 &&
          items.single.isDone &&
          items.single.completedAtUtc != null,
    );

    await repository.setDone('task-1', true, changedAt);

    final completed = (await completedEmission).single;
    expect(completed.isDone, isTrue);
    expect(completed.completedAtUtc, changedAt.toUtc());
    expect(completed.updatedAtUtc, changedAt.toUtc());

    final reopenedEmission = repository.watchAll().firstWhere(
      (items) =>
          items.length == 1 &&
          !items.single.isDone &&
          items.single.completedAtUtc == null,
    );

    await repository.setDone(
      'task-1',
      false,
      changedAt.add(const Duration(minutes: 5)),
    );

    final reopened = (await reopenedEmission).single;
    expect(reopened.isDone, isFalse);
    expect(reopened.completedAtUtc, isNull);
  });

  test('deleteCompleted keeps only active tasks', () async {
    final now = DateTime.utc(2026, 7, 26, 13);
    await repository.create(
      _task(id: 'active', title: 'فعال', priority: 1, sortOrder: 0, now: now),
    );
    await repository.create(
      TaskItem(
        id: 'done',
        displayNumber: 2,
        title: 'انجام شده',
        priority: 2,
        status: TaskStatus.completed,
        positionInStatus: 1,
        createdAtUtc: now,
        updatedAtUtc: now,
        completedAtUtc: now,
      ),
    );

    final remainingEmission = repository.watchAll().firstWhere(
      (items) => items.length == 1 && items.single.id == 'active',
    );

    await repository.deleteCompleted();

    expect((await remainingEmission).single.id, 'active');
  });

  test('delete removes only the requested task', () async {
    final now = DateTime.utc(2026, 7, 26, 14);
    await repository.create(
      _task(id: 'keep', title: 'بماند', priority: 0, sortOrder: 0, now: now),
    );
    await repository.create(
      _task(
        id: 'remove',
        title: 'حذف شود',
        priority: 0,
        sortOrder: 1,
        now: now,
      ),
    );

    final remainingEmission = repository.watchAll().firstWhere(
      (items) => items.length == 1 && items.single.id == 'keep',
    );

    await repository.delete('remove');

    expect((await remainingEmission).single.id, 'keep');
  });

  test('reorder writes contiguous sort order atomically', () async {
    final now = DateTime.utc(2026, 7, 26, 15);
    for (var index = 0; index < 3; index++) {
      await repository.create(
        _task(
          id: 'task-$index',
          title: 'کار $index',
          priority: index,
          sortOrder: index,
          now: now.add(Duration(minutes: index)),
        ),
      );
    }

    final reorderedEmission = repository.watchAll().firstWhere(
      (items) =>
          items.length == 3 &&
          items.map((item) => item.id).join(',') == 'task-2,task-0,task-1',
    );

    await repository.reorder(const <String>['task-2', 'task-0', 'task-1']);

    final items = await reorderedEmission;
    expect(items.map((item) => item.sortOrder).toList(), <int>[0, 1, 2]);
  });

  test('task survives reopening the same file database', () async {
    await database.close();
    sharedDatabaseOpen = false;

    final directory = await Directory.systemTemp.createTemp(
      'dashboard-shakhsi-task-repository-',
    );
    final file = File('${directory.path}/tasks.sqlite');

    final firstDatabase = AppDatabase(NativeDatabase(file));
    final firstRepository = DriftTaskRepository(firstDatabase);
    final now = DateTime.utc(2026, 7, 26, 16);

    await firstRepository.create(
      _task(
        id: 'persistent-task',
        title: 'بعد از بازشدن دوباره',
        priority: 3,
        sortOrder: 0,
        now: now,
      ),
    );
    await firstDatabase.close();

    final reopenedDatabase = AppDatabase(NativeDatabase(file));
    final reopenedRepository = DriftTaskRepository(reopenedDatabase);

    try {
      final items = await reopenedRepository.watchAll().first;
      expect(items, hasLength(1));
      expect(items.single.id, 'persistent-task');
      expect(items.single.title, 'بعد از بازشدن دوباره');
    } finally {
      await reopenedDatabase.close();
      await directory.delete(recursive: true);
    }
  });
}

TaskItem _task({
  required String id,
  int? displayNumber,
  required String title,
  required int priority,
  required int sortOrder,
  required DateTime now,
}) {
  return TaskItem(
    id: id,
    displayNumber: displayNumber ?? sortOrder + 1,
    title: title,
    priority: priority,
    status: TaskStatus.planned,
    positionInStatus: sortOrder,
    createdAtUtc: now,
    updatedAtUtc: now,
  );
}
