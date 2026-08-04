import 'dart:async';

import 'package:dashboard_shakhsi/app/theme/original_design_tokens.dart';
import 'package:dashboard_shakhsi/app/widgets/original_controls.dart';
import 'package:dashboard_shakhsi/app/widgets/original_glass.dart';
import 'package:dashboard_shakhsi/core/ids/id_generator.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_item.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_reminder_rule.dart';
import 'package:dashboard_shakhsi/features/tasks/presentation/task_details/task_details_draft.dart';
import 'package:dashboard_shakhsi/features/tasks/presentation/task_details/task_details_form.dart';
import 'package:flutter/material.dart';

enum TaskDetailsDialogMode { create, edit }

final class TaskDetailsDialogResult {
  const TaskDetailsDialogResult({
    required this.task,
    required this.reminderRules,
  });

  final TaskItem task;
  final List<TaskReminderRule> reminderRules;
}

Future<TaskItem?> showTaskDetailsDialog({
  required BuildContext context,
  required TaskDetailsDialogMode mode,
  TaskItem? initialTask,
  DateTime Function()? now,
  String Function()? nextId,
}) async {
  final result = await showTaskDetailsEditorDialog(
    context: context,
    mode: mode,
    initialTask: initialTask,
    now: now,
    nextId: nextId,
  );
  return result?.task;
}

Future<TaskDetailsDialogResult?> showTaskDetailsEditorDialog({
  required BuildContext context,
  required TaskDetailsDialogMode mode,
  TaskItem? initialTask,
  List<TaskReminderRule> initialReminderRules = const <TaskReminderRule>[],
  DateTime Function()? now,
  String Function()? nextId,
}) {
  if (mode == TaskDetailsDialogMode.edit && initialTask == null) {
    throw ArgumentError('initialTask is required in edit mode.');
  }

  final nowSource = now ?? DateTime.now;
  final idSource = nextId ?? (() => const UuidV7IdGenerator().next());

  return showGeneralDialog<TaskDetailsDialogResult>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'فرم جزئیات کار',
    barrierColor: Colors.black.withValues(alpha: .34),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _TaskDetailsDialogShell(
        mode: mode,
        initialTask: initialTask,
        initialReminderRules: initialReminderRules,
        now: nowSource,
        nextId: idSource,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .965, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final class _TaskDetailsDialogShell extends StatefulWidget {
  const _TaskDetailsDialogShell({
    required this.mode,
    required this.initialTask,
    required this.initialReminderRules,
    required this.now,
    required this.nextId,
  });

  final TaskDetailsDialogMode mode;
  final TaskItem? initialTask;
  final List<TaskReminderRule> initialReminderRules;
  final DateTime Function() now;
  final String Function() nextId;

  @override
  State<_TaskDetailsDialogShell> createState() =>
      _TaskDetailsDialogShellState();
}

final class _TaskDetailsDialogShellState
    extends State<_TaskDetailsDialogShell> {
  final GlobalKey<TaskDetailsFormState> _formKey =
      GlobalKey<TaskDetailsFormState>();
  bool _saving = false;
  String? _submitError;

  bool get _isCreate => widget.mode == TaskDetailsDialogMode.create;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    final media = MediaQuery.of(context);
    final initialDraft = _isCreate
        ? TaskDetailsDraft.create(nowLocal: widget.now().toLocal())
        : TaskDetailsDraft.fromTaskWithReminderRules(
            widget.initialTask!,
            reminderRules: widget.initialReminderRules,
          );

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 600;
            final horizontal = narrow ? 8.0 : 24.0;
            final vertical = narrow ? 8.0 : 28.0;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(
                horizontal,
                vertical,
                horizontal,
                vertical + media.viewInsets.bottom,
              ),
              child: Align(
                alignment: narrow ? Alignment.topCenter : Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: narrow ? constraints.maxWidth : 720,
                    maxHeight: narrow
                        ? constraints.maxHeight
                        : constraints.maxHeight.clamp(520.0, 820.0).toDouble(),
                  ),
                  child: OriginalGlass(
                    radius: narrow
                        ? OriginalDesignTokens.rowRadius
                        : OriginalDesignTokens.cardRadius,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        _DialogHeader(
                          title: _isCreate
                              ? 'افزودن کار با جزئیات'
                              : 'ویرایش کار',
                          subtitle: _isCreate
                              ? 'زمان‌بندی و توضیحات را همان ابتدا ثبت کنید.'
                              : 'جزئیات کار را بدون تغییر وضعیت و ترتیب ویرایش کنید.',
                          onClose: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                        Container(height: 1, color: palette.line),
                        Expanded(
                          child: AbsorbPointer(
                            absorbing: _saving,
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                24,
                              ),
                              child: TaskDetailsForm(
                                key: _formKey,
                                initialDraft: initialDraft,
                                titleHint: _isCreate
                                    ? 'عنوان کار'
                                    : 'ویرایش کار',
                                onSubmit: () => unawaited(_save()),
                              ),
                            ),
                          ),
                        ),
                        if (_submitError case final error?)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Text(
                              error,
                              key: const ValueKey<String>(
                                'task-details-submit-error',
                              ),
                              style: TextStyle(
                                color: palette.expense,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Container(height: 1, color: palette.line),
                        _DialogActions(
                          saving: _saving,
                          primaryLabel: _isCreate
                              ? 'افزودن کار'
                              : 'ذخیره تغییرات',
                          onCancel: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          onSave: _saving ? null : () => unawaited(_save()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _saving = true;
      _submitError = null;
    });

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    try {
      final savedAtUtc = widget.now().toUtc();
      final task = _isCreate
          ? form.draft.buildNewTask(id: widget.nextId(), savedAtUtc: savedAtUtc)
          : form.draft.applyTo(
              task: widget.initialTask!,
              savedAtUtc: savedAtUtc,
            );
      final reminderRules = form.draft.buildReminderRules(
        taskId: task.id,
        savedAtUtc: savedAtUtc,
        nextId: widget.nextId,
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(TaskDetailsDialogResult(task: task, reminderRules: reminderRules));
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = 'ذخیره اطلاعات انجام نشد. دوباره تلاش کنید.';
      });
    }
  }
}

final class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          OriginalPressable(
            semanticLabel: 'بستن فرم کار',
            onPressed: onClose,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.close_rounded, color: palette.muted, size: 21),
            ),
          ),
        ],
      ),
    );
  }
}

final class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.saving,
    required this.primaryLabel,
    required this.onCancel,
    required this.onSave,
  });

  final bool saving;
  final String primaryLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 16),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: <Widget>[
          OriginalGhostButton(
            label: 'انصراف',
            icon: Icons.close_rounded,
            onPressed: onCancel,
          ),
          OriginalPrimaryButton(
            label: saving ? 'در حال ذخیره…' : primaryLabel,
            icon: saving ? Icons.hourglass_top_rounded : Icons.check_rounded,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}
