import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';

abstract interface class TaskRepository {
  Stream<List<TaskItem>> watchAll();

  Future<void> create(TaskItem task);

  Future<void> update(TaskItem task);

  Future<void> setDone(String id, bool isDone, DateTime changedAt);

  Future<void> delete(String id);

  Future<void> deleteCompleted();

  Future<void> reorder(List<String> orderedIds);
}
