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
    if (id.trim().isEmpty) {
      throw const ValidationFailure('شناسه کار نمی‌تواند خالی باشد.');
    }
    if (this.title.isEmpty) {
      throw const ValidationFailure('عنوان کار نمی‌تواند خالی باشد.');
    }
    if (priority < 0 || priority > 3) {
      throw const ValidationFailure('اولویت کار نامعتبر است.');
    }
    if (sortOrder < 0) {
      throw const ValidationFailure('ترتیب کار نامعتبر است.');
    }
    _validateUtc(createdAtUtc);
    _validateUtc(updatedAtUtc);
    final completedAt = completedAtUtc;
    if (completedAt != null) {
      _validateUtc(completedAt);
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
      completedAtUtc: clearCompletedAt
          ? null
          : completedAtUtc ?? this.completedAtUtc,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskItem &&
            other.id == id &&
            other.title == title &&
            other.priority == priority &&
            other.isDone == isDone &&
            other.sortOrder == sortOrder &&
            other.createdAtUtc == createdAtUtc &&
            other.updatedAtUtc == updatedAtUtc &&
            other.completedAtUtc == completedAtUtc;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    priority,
    isDone,
    sortOrder,
    createdAtUtc,
    updatedAtUtc,
    completedAtUtc,
  );

  @override
  String toString() {
    return 'TaskItem(id: $id, title: $title, priority: $priority, '
        'isDone: $isDone, sortOrder: $sortOrder)';
  }
}

void _validateUtc(DateTime value) {
  if (!value.isUtc) {
    throw const ValidationFailure('زمان کار باید به‌صورت UTC ذخیره شود.');
  }
}
