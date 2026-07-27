import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 26, 10);
  final updatedAt = DateTime.utc(2026, 7, 26, 11);

  test('task trims its title and keeps exact persistence fields', () {
    final task = TaskItem(
      id: 'task-1',
      title: '  خرید روزانه  ',
      priority: 2,
      isDone: false,
      sortOrder: 4,
      createdAtUtc: createdAt,
      updatedAtUtc: updatedAt,
    );

    expect(task.title, 'خرید روزانه');
    expect(task.priority, 2);
    expect(task.sortOrder, 4);
    expect(task.createdAtUtc, createdAt);
    expect(task.completedAtUtc, isNull);
  });

  test('task rejects an empty title', () {
    expect(
      () => TaskItem(
        id: 'task-1',
        title: '   ',
        priority: 1,
        isDone: false,
        sortOrder: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('task rejects a priority outside zero to three', () {
    expect(
      () => TaskItem(
        id: 'task-1',
        title: 'کار',
        priority: 4,
        isDone: false,
        sortOrder: 0,
        createdAtUtc: createdAt,
        updatedAtUtc: updatedAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('task rejects local persistence timestamps', () {
    expect(
      () => TaskItem(
        id: 'task-1',
        title: 'کار',
        priority: 1,
        isDone: false,
        sortOrder: 0,
        createdAtUtc: DateTime(2026, 7, 26),
        updatedAtUtc: updatedAt,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('copyWith can complete and reopen a task', () {
    final task = TaskItem(
      id: 'task-1',
      title: 'کار',
      priority: 1,
      isDone: false,
      sortOrder: 0,
      createdAtUtc: createdAt,
      updatedAtUtc: updatedAt,
    );
    final completedAt = DateTime.utc(2026, 7, 26, 12);

    final completed = task.copyWith(
      isDone: true,
      updatedAtUtc: completedAt,
      completedAtUtc: completedAt,
    );
    final reopened = completed.copyWith(
      isDone: false,
      updatedAtUtc: DateTime.utc(2026, 7, 26, 13),
      clearCompletedAt: true,
    );

    expect(completed.isDone, isTrue);
    expect(completed.completedAtUtc, completedAt);
    expect(reopened.isDone, isFalse);
    expect(reopened.completedAtUtc, isNull);
  });
}
