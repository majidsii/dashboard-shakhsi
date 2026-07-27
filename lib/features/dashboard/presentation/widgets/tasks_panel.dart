import 'dart:async';
import 'dart:math' as math;

import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/widgets/original_controls.dart';
import 'package:dashboard_shakhsi/app/widgets/original_glass.dart';
import 'package:dashboard_shakhsi/core/date_time/persian_date_label.dart';
import 'package:dashboard_shakhsi/core/ids/id_generator.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class TasksPanel extends ConsumerStatefulWidget {
  const TasksPanel({super.key});

  @override
  ConsumerState<TasksPanel> createState() => _TasksPanelState();
}

final class _TasksPanelState extends ConsumerState<TasksPanel> {
  final TextEditingController _newTaskController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  static const IdGenerator _idGenerator = UuidV7IdGenerator();
  final Set<String> _removingTaskIds = <String>{};

  int _priority = 0;
  int _filter = 0;
  String _sort = 'new';

  @override
  void dispose() {
    _newTaskController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final tasksAsync = ref.watch(taskItemsProvider);
    final tasks = tasksAsync.asData?.value ?? const <TaskItem>[];
    final doneCount = tasks.where((task) => task.done).length;
    final activeCount = tasks.length - doneCount;
    final highActiveCount = tasks
        .where((task) => !task.done && task.priority == 3)
        .length;
    final visibleTasks = _filteredTasks(tasks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 18,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 230),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'کارهای من',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 30,
                        height: 1.25,
                        letterSpacing: -.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      PersianDateLabel.full(DateTime.now()),
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _statusText(
                        total: tasks.length,
                        done: doneCount,
                        highActive: highActiveCount,
                      ),
                      style: TextStyle(
                        color: tasks.isNotEmpty && activeCount == 0
                            ? palette.amber
                            : palette.accent,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _ProgressRing(done: doneCount, total: tasks.length),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Toolbar(
          searchController: _searchController,
          sort: _sort,
          onSortChanged: (value) => setState(() => _sort = value),
          onSearchChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 480;
            return SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: OriginalTextField(
                      controller: _newTaskController,
                      hintText: 'یک کار جدید بنویسید…',
                      pill: true,
                      onSubmitted: (_) => unawaited(_addTask(tasks)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PriorityButton(
                    priority: _priority,
                    hideLabel: narrow,
                    onTap: () =>
                        setState(() => _priority = (_priority + 1) % 4),
                  ),
                  const SizedBox(width: 8),
                  OriginalPrimaryButton(
                    square: true,
                    icon: Icons.add_rounded,
                    onPressed: () => unawaited(_addTask(tasks)),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _TaskFilterPills(
          selected: _filter,
          total: tasks.length,
          active: activeCount,
          high: tasks.where((task) => task.priority == 3).length,
          done: doneCount,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 14),
        if (visibleTasks.isEmpty)
          _EmptyTasks(
            hasTasks: tasks.isNotEmpty,
            hasQuery: _searchController.text.trim().isNotEmpty,
            filter: _filter,
          )
        else
          ...visibleTasks.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _TaskRow(
                key: ValueKey<String>(entry.$2.id),
                index: entry.$1,
                task: entry.$2,
                removing: _removingTaskIds.contains(entry.$2.id),
                onToggle: () => unawaited(_toggleTask(entry.$2)),
                onPriority: () => unawaited(_changePriority(entry.$2)),
                onEdit: (value) => unawaited(_editTask(entry.$2, value)),
                onDelete: () => unawaited(_removeTask(entry.$2)),
              ),
            ),
          ),
        if (tasks.isNotEmpty) ...<Widget>[
          const SizedBox(height: 9),
          Container(height: 1, color: palette.line),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${_fa(activeCount)} فعال · ${_fa(doneCount)} انجام‌شده',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Visibility(
                visible: doneCount > 0,
                maintainAnimation: true,
                maintainSize: true,
                maintainState: true,
                child: OriginalPressable(
                  onPressed: doneCount == 0
                      ? null
                      : () => unawaited(
                          ref.read(taskRepositoryProvider).deleteCompleted(),
                        ),
                  pressedScale: .96,
                  borderRadius: BorderRadius.circular(
                    OriginalDesignTokens.pillRadius,
                  ),
                  semanticLabel: 'پاک کردن انجام‌شده‌ها',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Text(
                      'پاک کردن انجام‌شده‌ها',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _statusText({
    required int total,
    required int done,
    required int highActive,
  }) {
    if (total == 0) return 'برای شروع، یک کار اضافه کنید';
    final remaining = total - done;
    if (remaining == 0) return 'همه کارها انجام شد 🎉';
    return '${_fa(remaining)} کار باقی مانده'
        '${highActive == 0 ? '' : ' · ${_fa(highActive)} با اولویت بالا'}';
  }

  Future<void> _addTask(List<TaskItem> tasks) async {
    final title = _newTaskController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now().toUtc();
    final id = _idGenerator.next();
    final repository = ref.read(taskRepositoryProvider);

    await repository.create(
      TaskItem(
        id: id,
        title: title,
        priority: _priority,
        isDone: false,
        sortOrder: 0,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
    await repository.reorder(<String>[
      id,
      ...tasks.where((task) => task.id != id).map((task) => task.id),
    ]);

    if (mounted) {
      _newTaskController.clear();
    }
  }

  Future<void> _toggleTask(TaskItem task) {
    return ref
        .read(taskRepositoryProvider)
        .setDone(task.id, !task.isDone, DateTime.now().toUtc());
  }

  Future<void> _changePriority(TaskItem task) {
    return ref
        .read(taskRepositoryProvider)
        .update(
          task.copyWith(
            priority: (task.priority + 1) % 4,
            updatedAtUtc: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> _editTask(TaskItem task, String value) async {
    final title = value.trim();
    if (title.isEmpty || title == task.title) return;

    await ref
        .read(taskRepositoryProvider)
        .update(
          task.copyWith(title: title, updatedAtUtc: DateTime.now().toUtc()),
        );
  }

  Future<void> _removeTask(TaskItem task) async {
    if (_removingTaskIds.contains(task.id)) return;
    setState(() => _removingTaskIds.add(task.id));

    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await ref.read(taskRepositoryProvider).delete(task.id);
    } finally {
      if (mounted) {
        setState(() => _removingTaskIds.remove(task.id));
      }
    }
  }

  List<TaskItem> _filteredTasks(List<TaskItem> tasks) {
    final query = _normalize(_searchController.text.trim());
    final result = tasks.where((task) {
      final queryMatches =
          query.isEmpty || _normalize(task.title).contains(query);
      if (!queryMatches) return false;
      return switch (_filter) {
        1 => !task.done,
        2 => task.priority == 3,
        3 => task.done,
        _ => true,
      };
    }).toList();

    result.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      if (_sort == 'pri') {
        final priority = b.priority.compareTo(a.priority);
        if (priority != 0) return priority;
      } else if (_sort == 'abc') {
        return _normalize(a.title).compareTo(_normalize(b.title));
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }
}

final class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchController,
    required this.sort,
    required this.onSortChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final String sort;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return _DesktopToolbar(
            searchController: searchController,
            sort: sort,
            onSortChanged: onSortChanged,
            onSearchChanged: onSearchChanged,
          );
        }

        return Wrap(
          textDirection: TextDirection.rtl,
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              width: math.max(170.0, constraints.maxWidth - 150).toDouble(),
              child: OriginalTextField(
                controller: searchController,
                hintText: 'جست‌وجو در کارها…',
                prefixIcon: Icons.search_rounded,
                pill: true,
                onChanged: onSearchChanged,
              ),
            ),
            _SortControl(value: sort, onChanged: onSortChanged),
            OriginalPrimaryButton(
              compact: true,
              icon: Icons.file_download_outlined,
              label: 'خروجی',
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }
}

final class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.searchController,
    required this.sort,
    required this.onSortChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final String sort;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 40,
            child: OriginalTextField(
              controller: searchController,
              hintText: 'جست‌وجو در کارها…',
              prefixIcon: Icons.search_rounded,
              pill: true,
              onChanged: onSearchChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 148,
          height: 40,
          child: _SortControl(value: sort, onChanged: onSortChanged),
        ),
        const SizedBox(width: 8),
        OriginalPrimaryButton(
          compact: true,
          icon: Icons.file_download_outlined,
          label: 'خروجی',
          onPressed: () {},
        ),
      ],
    );
  }
}

final class _SortControl extends StatelessWidget {
  const _SortControl({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return OriginalFieldSurface(
      radius: OriginalDesignTokens.pillRadius,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            isExpanded: true,
            dropdownColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1C2C)
                : const Color(0xFFFCFDFF),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: palette.muted),
            borderRadius: BorderRadius.circular(18),
            style: TextStyle(
              color: palette.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Vazirmatn',
            ),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'new', child: Text('جدیدترین')),
              DropdownMenuItem(value: 'pri', child: Text('بر اساس اولویت')),
              DropdownMenuItem(value: 'abc', child: Text('الفبا')),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}

final class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final progress = total == 0 ? 0.0 : done / total;
    return SizedBox.square(
      dimension: 84,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress),
            duration: const Duration(milliseconds: 600),
            curve: const Cubic(.65, 0, .35, 1),
            builder: (context, animatedProgress, _) {
              return CustomPaint(
                size: const Size.square(84),
                painter: _RingPainter(
                  progress: animatedProgress,
                  track: palette.track,
                  color: total > 0 && done == total
                      ? palette.amber
                      : palette.accent,
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _fa(done),
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'از ${_fa(total)}',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = track;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.track != track;
  }
}

final class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.priority,
    required this.hideLabel,
    required this.onTap,
  });

  final int priority;
  final bool hideLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final (label, color, soft) = switch (priority) {
      1 => (
        'پایین',
        Theme.of(context).brightness == Brightness.dark
            ? OriginalDesignTokens.darkPriorityLow
            : OriginalDesignTokens.lightPriorityLow,
        palette.accentSoft,
      ),
      2 => ('متوسط', palette.amber, palette.amberSoft),
      3 => ('بالا', palette.expense, palette.expenseSoft),
      _ => ('اولویت', palette.muted, palette.field),
    };
    return OriginalFieldSurface(
      radius: OriginalDesignTokens.pillRadius,
      fill: soft,
      child: OriginalPressable(
        onPressed: onTap,
        pressedScale: .96,
        borderRadius: BorderRadius.circular(OriginalDesignTokens.pillRadius),
        semanticLabel: label,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hideLabel ? 13 : 16),
          child: Row(
            children: <Widget>[
              Icon(Icons.outlined_flag_rounded, color: color, size: 16),
              if (!hideLabel) ...<Widget>[
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _TaskFilterPills extends StatelessWidget {
  const _TaskFilterPills({
    required this.selected,
    required this.total,
    required this.active,
    required this.high,
    required this.done,
    required this.onSelected,
  });

  final int selected;
  final int total;
  final int active;
  final int high;
  final int done;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final items = <(String, int)>[
      ('همه', total),
      ('فعال', active),
      ('اولویت بالا', high),
      ('انجام‌شده', done),
    ];

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List<Widget>.generate(items.length, (index) {
        final activeItem = selected == index;
        final item = items[index];
        final radius = BorderRadius.circular(OriginalDesignTokens.pillRadius);
        return OriginalPressable(
          onPressed: () => onSelected(index),
          pressedScale: .96,
          borderRadius: radius,
          semanticLabel: item.$1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: activeItem ? palette.thumb : Colors.transparent,
              boxShadow: activeItem
                  ? <BoxShadow>[
                      BoxShadow(
                        color: palette.shadowSecondary,
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: palette.hairTop,
                        offset: const Offset(0, -1),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  item.$1,
                  style: TextStyle(
                    color: activeItem ? palette.ink : palette.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.$2 > 0) ...<Widget>[
                  const SizedBox(width: 3),
                  Text(
                    _fa(item.$2),
                    style:
                        TextStyle(
                          color: activeItem ? palette.ink : palette.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ).copyWith(
                          color: (activeItem ? palette.ink : palette.muted)
                              .withValues(alpha: .55),
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

final class _TaskRow extends StatefulWidget {
  const _TaskRow({
    required this.index,
    required this.task,
    required this.removing,
    required this.onToggle,
    required this.onPriority,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final int index;
  final TaskItem task;
  final bool removing;
  final VoidCallback onToggle;
  final VoidCallback onPriority;
  final ValueChanged<String> onEdit;
  final VoidCallback onDelete;

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

final class _TaskRowState extends State<_TaskRow> {
  late final TextEditingController _editController;
  late final FocusNode _editFocusNode;
  bool _editing = false;
  bool _finishingEdit = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.task.title);
    _editFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _TaskRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.task.title != widget.task.title) {
      _editController.text = widget.task.title;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (_editing) return;
    _editController.text = widget.task.title;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _editFocusNode.requestFocus();
      _editController.selection = TextSelection.collapsed(
        offset: _editController.text.length,
      );
    });
  }

  void _finishEditing({required bool save}) {
    if (!_editing || _finishingEdit) return;
    _finishingEdit = true;
    if (save) widget.onEdit(_editController.text);
    _editFocusNode.unfocus();
    if (mounted) setState(() => _editing = false);
    _finishingEdit = false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final task = widget.task;
    final priority = _priorityVisual(context, task.priority);

    final row = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OriginalDesignTokens.rowRadius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadowSecondary,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: OriginalFieldSurface(
        radius: OriginalDesignTokens.rowRadius,
        blurSigma: OriginalDesignTokens.rowBlurSigma,
        saturation: OriginalDesignTokens.rowSaturation,
        fill: palette.row,
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              start: 0,
              top: 11,
              bottom: 11,
              child: AnimatedOpacity(
                opacity: task.done ? .35 : 1,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: priority.color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 12, 12),
              child: Row(
                children: <Widget>[
                  _TaskCheck(done: task.done, onPressed: widget.onToggle),
                  const SizedBox(width: 11),
                  _TaskNumber(index: widget.index),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _editing
                        ? TextField(
                            controller: _editController,
                            focusNode: _editFocusNode,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _finishEditing(save: true),
                            onTapOutside: (_) => _finishEditing(save: true),
                            cursorColor: palette.accent,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ویرایش کار',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 1,
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: palette.accent,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: palette.accent,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: palette.accent,
                                  width: 2,
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onDoubleTap: _startEditing,
                            child: Text(
                              task.title,
                              style: TextStyle(
                                color: task.done ? palette.faint : palette.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                decoration: task.done
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationThickness: 1.5,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 7),
                  _PriorityChip(
                    priority: task.priority,
                    done: task.done,
                    onPressed: widget.onPriority,
                  ),
                  const SizedBox(width: 2),
                  _TaskActionButton(
                    semanticLabel: 'ویرایش کار',
                    icon: Icons.edit_outlined,
                    hoverColor: palette.accentSoft,
                    hoverIconColor: palette.accent,
                    onPressed: _startEditing,
                  ),
                  _TaskActionButton(
                    semanticLabel: 'حذف کار',
                    icon: Icons.delete_outline_rounded,
                    hoverColor: palette.expenseSoft,
                    hoverIconColor: palette.expense,
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(.32, 1.35, .4, 1),
      builder: (context, value, child) {
        final opacity = value.clamp(0.0, 1.0).toDouble();
        final removalProgress = widget.removing ? 1.0 : 0.0;
        return AnimatedOpacity(
          opacity: widget.removing ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.ease,
          child: AnimatedSlide(
            offset: Offset(removalProgress * .08, 0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
            child: Transform.translate(
              offset: Offset(0, -6 * (1 - value)),
              child: Transform.scale(
                scale: .98 + (.02 * value),
                child: Opacity(opacity: opacity, child: child),
              ),
            ),
          ),
        );
      },
      child: row,
    );
  }
}

final class _TaskCheck extends StatelessWidget {
  const _TaskCheck({required this.done, required this.onPressed});

  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final radius = BorderRadius.circular(99);
    return Semantics(
      button: true,
      checked: done,
      label: done ? 'علامت به عنوان انجام‌نشده' : 'علامت به عنوان انجام‌شده',
      child: OriginalPressable(
        onPressed: onPressed,
        pressedScale: .88,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? palette.accent : Colors.transparent,
            border: Border.all(
              color: done ? palette.accent : palette.faint,
              width: 2,
            ),
          ),
          child: AnimatedScale(
            scale: done ? 1 : .4,
            duration: const Duration(milliseconds: 200),
            child: AnimatedOpacity(
              opacity: done ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _TaskNumber extends StatelessWidget {
  const _TaskNumber({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Container(
      key: ValueKey<String>('task-number-$index'),
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.field,
        border: Border.all(color: palette.hair),
      ),
      child: Text(
        _fa(index + 1),
        style: TextStyle(
          color: palette.muted,
          fontSize: 11.5,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
    required this.done,
    required this.onPressed,
  });

  final int priority;
  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final visual = _priorityVisual(context, priority);
    final radius = BorderRadius.circular(OriginalDesignTokens.pillRadius);
    return Opacity(
      opacity: done ? .45 : 1,
      child: OriginalPressable(
        onPressed: onPressed,
        pressedScale: .94,
        borderRadius: radius,
        semanticLabel: 'اولویت: ${visual.label} — برای تغییر کلیک کنید',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: priority == 0 ? Colors.transparent : visual.soft,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                priority == 0
                    ? Icons.outlined_flag_rounded
                    : Icons.flag_rounded,
                color: visual.color,
                size: 13,
              ),
              if (priority > 0) ...<Widget>[
                const SizedBox(width: 5),
                Text(
                  visual.shortLabel,
                  style: TextStyle(
                    color: visual.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _TaskActionButton extends StatefulWidget {
  const _TaskActionButton({
    required this.semanticLabel,
    required this.icon,
    required this.hoverColor,
    required this.hoverIconColor,
    required this.onPressed,
  });

  final String semanticLabel;
  final IconData icon;
  final Color hoverColor;
  final Color hoverIconColor;
  final VoidCallback onPressed;

  @override
  State<_TaskActionButton> createState() => _TaskActionButtonState();
}

final class _TaskActionButtonState extends State<_TaskActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final radius = BorderRadius.circular(99);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: OriginalPressable(
        onPressed: widget.onPressed,
        pressedScale: .9,
        borderRadius: radius,
        semanticLabel: widget.semanticLabel,
        child: AnimatedOpacity(
          opacity: _hovered ? 1 : .55,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovered ? widget.hoverColor : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              color: _hovered ? widget.hoverIconColor : palette.faint,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}

final class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({
    required this.hasTasks,
    required this.hasQuery,
    required this.filter,
  });

  final bool hasTasks;
  final bool hasQuery;
  final int filter;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final (title, subtitle) = switch ((hasTasks, hasQuery, filter)) {
      (false, _, _) => (
        'هنوز کاری اضافه نکرده‌اید',
        'اولین کار خود را در کادر بالا بنویسید.',
      ),
      (true, true, _) => ('چیزی پیدا نشد', 'عبارت دیگری را جست‌وجو کنید.'),
      (true, false, 1) => (
        'هیچ کار فعالی نمانده',
        'همه چیز انجام شده — عالیه!',
      ),
      (true, false, 2) => (
        'کاری با اولویت بالا ندارید',
        'با دکمه پرچم کنار هر کار، اولویت تعیین کنید.',
      ),
      _ => ('هنوز کاری انجام نشده', 'کارها را با زدن دایره کنارشان تیک بزنید.'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasTasks
                  ? Icons.filter_alt_off_outlined
                  : Icons.checklist_rounded,
              color: palette.accent,
              size: 27,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.faint,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

extension on TaskItem {
  bool get done => isDone;
  DateTime get createdAt => createdAtUtc.toLocal();
}

final class _PriorityVisual {
  const _PriorityVisual({
    required this.label,
    required this.shortLabel,
    required this.color,
    required this.soft,
  });

  final String label;
  final String shortLabel;
  final Color color;
  final Color soft;
}

_PriorityVisual _priorityVisual(BuildContext context, int priority) {
  final palette = OriginalPalette.of(context);
  return switch (priority) {
    1 => _PriorityVisual(
      label: 'اولویت پایین',
      shortLabel: 'پایین',
      color: Theme.of(context).brightness == Brightness.dark
          ? OriginalDesignTokens.darkPriorityLow
          : OriginalDesignTokens.lightPriorityLow,
      soft: palette.accentSoft,
    ),
    2 => _PriorityVisual(
      label: 'اولویت متوسط',
      shortLabel: 'متوسط',
      color: palette.amber,
      soft: palette.amberSoft,
    ),
    3 => _PriorityVisual(
      label: 'اولویت بالا',
      shortLabel: 'بالا',
      color: palette.expense,
      soft: palette.expenseSoft,
    ),
    _ => _PriorityVisual(
      label: 'بدون اولویت',
      shortLabel: '',
      color: palette.faint,
      soft: Colors.transparent,
    ),
  };
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
}

String _fa(Object value) {
  const latin = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  return value.toString().split('').map((character) {
    final index = latin.indexOf(character);
    return index < 0 ? character : persian[index];
  }).join();
}
