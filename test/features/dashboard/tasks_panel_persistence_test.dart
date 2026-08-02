import 'dart:async';

import 'package:dashboard_shakhsi/app/theme/original_theme.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/widgets/tasks_panel.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_repository.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemoryTaskRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MemoryTaskRepository();
    container = ProviderContainer(
      overrides: <Override>[
        taskRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.close();
  });

  Widget subject() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: OriginalTheme.light(),
        home: const Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(width: 780, height: 900, child: TasksPanel()),
          ),
        ),
      ),
    );
  }

  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> flushUiAction(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }

  Finder textFieldWithHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  testWidgets('renders tasks streamed from the repository', (tester) async {
    final now = DateTime.utc(2026, 7, 26, 10);
    repository.seed(<TaskItem>[
      TaskItem(
        id: 'persisted-task',
        displayNumber: 1,
        title: 'تسک ذخیره‌شده',
        priority: 3,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    ]);

    await pumpSubject(tester);

    expect(find.text('تسک ذخیره‌شده'), findsOneWidget);
    expect(find.text('۱ کار باقی مانده · ۱ با اولویت بالا'), findsOneWidget);
    expect(find.text('۱ فعال · ۰ انجام‌شده'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('task-number-0')), findsOneWidget);
  });

  testWidgets('adding a task calls the repository', (tester) async {
    await pumpSubject(tester);

    await tester.enterText(
      textFieldWithHint('یک کار جدید بنویسید…'),
      'تسک دائمی از رابط کاربری',
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await flushUiAction(tester);

    expect(repository.items, hasLength(1));
    expect(repository.items.single.title, 'تسک دائمی از رابط کاربری');
    expect(repository.items.single.sortOrder, 0);
  });

  testWidgets('edit completion and delete actions call the repository', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 7, 26, 11);
    repository.seed(<TaskItem>[
      TaskItem(
        id: 'editable-task',
        displayNumber: 1,
        title: 'عنوان قبلی',
        priority: 1,
        status: TaskStatus.planned,
        positionInStatus: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    ]);

    await pumpSubject(tester);

    await tester.tap(find.bySemanticsLabel('ویرایش کار'));
    await flushUiAction(tester);
    await tester.enterText(textFieldWithHint('ویرایش کار'), 'عنوان جدید');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await flushUiAction(tester);

    expect(repository.items.single.title, 'عنوان جدید');

    await tester.tap(find.bySemanticsLabel('علامت به عنوان انجام‌شده'));
    await flushUiAction(tester);

    expect(repository.items.single.isDone, isTrue);
    expect(repository.items.single.completedAtUtc, isNot(equals(null)));

    await tester.tap(find.bySemanticsLabel('حذف کار'));
    await tester.pump(const Duration(milliseconds: 300));
    await flushUiAction(tester);

    expect(repository.items, isEmpty);
  });

  testWidgets('remount reads the current repository state', (tester) async {
    await pumpSubject(tester);

    await tester.enterText(
      textFieldWithHint('یک کار جدید بنویسید…'),
      'بعد از ساخت دوباره ویجت',
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await flushUiAction(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpSubject(tester);

    expect(find.text('بعد از ساخت دوباره ویجت'), findsOneWidget);
  });
}

final class _MemoryTaskRepository implements TaskRepository {
  final StreamController<List<TaskItem>> _controller =
      StreamController<List<TaskItem>>.broadcast(sync: true);

  List<TaskItem> _items = <TaskItem>[];

  List<TaskItem> get items => List<TaskItem>.unmodifiable(_items);

  void seed(List<TaskItem> items) {
    _items = List<TaskItem>.from(items);
  }

  void _emit() {
    _items.sort((left, right) {
      final order = left.sortOrder.compareTo(right.sortOrder);
      if (order != 0) return order;
      return left.id.compareTo(right.id);
    });
    _controller.add(items);
  }

  @override
  Stream<List<TaskItem>> watchAll() async* {
    yield items;
    yield* _controller.stream;
  }

  @override
  Future<void> create(TaskItem task) async {
    _items.add(task);
    _emit();
  }

  @override
  Future<void> update(TaskItem task) async {
    final index = _items.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _items[index] = task;
    _emit();
  }

  @override
  Future<void> setDone(String id, bool isDone, DateTime changedAt) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = _items[index];
    final changedAtUtc = changedAt.toUtc();
    _items[index] = TaskItem(
      id: current.id,
      displayNumber: current.displayNumber,
      title: current.title,
      priority: current.priority,
      status: isDone ? TaskStatus.completed : TaskStatus.planned,
      positionInStatus: current.positionInStatus,
      createdAtUtc: current.createdAtUtc,
      updatedAtUtc: changedAtUtc,
      completedAtUtc: isDone ? changedAtUtc : null,
    );
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
    _emit();
  }

  @override
  Future<void> deleteCompleted() async {
    _items.removeWhere((item) => item.isDone);
    _emit();
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    final byId = <String, TaskItem>{for (final item in _items) item.id: item};
    final reordered = <TaskItem>[];

    for (var index = 0; index < orderedIds.length; index++) {
      final current = byId.remove(orderedIds[index]);
      if (current == null) continue;
      reordered.add(
        TaskItem(
          id: current.id,
          displayNumber: current.displayNumber,
          title: current.title,
          priority: current.priority,
          status: current.status,
          positionInStatus: index,
          createdAtUtc: current.createdAtUtc,
          updatedAtUtc: current.updatedAtUtc,
          completedAtUtc: current.completedAtUtc,
          canceledAtUtc: current.canceledAtUtc,
        ),
      );
    }

    reordered.addAll(byId.values);
    _items = reordered;
    _emit();
  }

  Future<void> close() => _controller.close();
}
