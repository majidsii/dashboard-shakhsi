#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

FILES = {
    "labels": ROOT / "lib/features/tasks/presentation/task_details/task_planning_labels.dart",
    "duration": ROOT / "lib/features/tasks/presentation/task_details/task_duration_field.dart",
    "date_time": ROOT / "lib/features/tasks/presentation/task_details/task_jalali_date_time_field.dart",
    "form": ROOT / "lib/features/tasks/presentation/task_details/task_details_form.dart",
    "dialog": ROOT / "lib/features/tasks/presentation/task_details/task_details_dialog.dart",
    "panel": ROOT / "lib/features/dashboard/presentation/widgets/tasks_panel.dart",
    "labels_test": ROOT / "test/features/tasks/presentation/task_details/task_planning_labels_test.dart",
    "duration_test": ROOT / "test/features/tasks/presentation/task_details/task_duration_field_test.dart",
    "date_time_test": ROOT / "test/features/tasks/presentation/task_details/task_jalali_date_time_field_test.dart",
    "dialog_test": ROOT / "test/features/tasks/presentation/task_details/task_details_dialog_test.dart",
    "panel_test": ROOT / "test/features/dashboard/tasks_panel_details_test.dart",
}


def need(condition: bool, message: str) -> None:
    if not condition:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


def compact(value: str) -> str:
    return re.sub(r"\s+", " ", value)


for name, path in FILES.items():
    need(path.is_file(), f"missing {name}: {path}")

sources = {name: path.read_text(encoding="utf-8") for name, path in FILES.items()}
flat = {name: compact(value) for name, value in sources.items()}

# Jalali/local control contract.
date_time = sources["date_time"]
need("final class TaskJalaliDateTimeField" in date_time, "date/time field missing")
need("Jalali.fromDateTime" in date_time, "Jalali display conversion missing")
need(".toDateTime()" in date_time, "Jalali to local DateTime conversion missing")
need("showDatePicker" not in date_time, "generic Gregorian date picker is forbidden")
need("OriginalGlass" in date_time, "date selector does not use OriginalGlass")
need("OriginalFieldSurface" in date_time, "date/time field surface missing")
for semantic in (
    "انتخاب تاریخ $label",
    "انتخاب ساعت $label",
    "پاک کردن زمان $label",
    "ماه قبل",
    "ماه بعد",
    "تأیید ساعت",
):
    need(semantic in date_time, f"date/time semantic missing: {semantic}")
need(
    re.search(
        r"DateTime\s*\(\s*gregorian\.year\s*,\s*gregorian\.month\s*,\s*"
        r"gregorian\.day\s*,\s*base\.hour\s*,\s*base\.minute",
        date_time,
        re.DOTALL,
    )
    is not None,
    "date selection does not preserve local time",
)
need(
    re.search(
        r"DateTime\s*\(\s*base\.year\s*,\s*base\.month\s*,\s*base\.day\s*,\s*"
        r"selected\.hour\s*,\s*selected\.minute",
        date_time,
        re.DOTALL,
    )
    is not None,
    "time selection does not preserve local date",
)

# Duration control.
duration = sources["duration"]
need("final class TaskDurationField" in duration, "duration field missing")
need("FilteringTextInputFormatter.digitsOnly" in duration, "numeric input guard missing")
for token in (
    "ساعت مدت تخمینی",
    "دقیقه مدت تخمینی",
    "پاک کردن مدت تخمینی",
    "Wrap(",
):
    need(token in duration, f"duration contract missing: {token}")

# Shared form and draft wiring.
form = sources["form"]
need("final class TaskDetailsForm" in form, "shared form missing")
need("TaskDetailsDraft" in form, "form is not draft-backed")
need("TaskJalaliDateTimeField" in form, "start/due control missing from form")
need("TaskDurationField" in form, "duration control missing from form")
need(form.count("TaskJalaliDateTimeField(") == 2, "form must use exactly two date/time fields")
for label in ("عنوان", "اولویت", "توضیحات", "شروع", "سررسید"):
    need(label in form, f"form field missing: {label}")
need("minLines: 3" in form and "maxLines: 6" in form, "description is not multiline")
need("Map<TaskDetailsField, String>" in form, "inline field error map missing")

# Dialog contract.
dialog = sources["dialog"]
need("enum TaskDetailsDialogMode { create, edit }" in dialog, "dialog mode enum missing")
need("showTaskDetailsDialog" in dialog, "dialog entry point missing")
need("showGeneralDialog<TaskItem>" in dialog, "custom adaptive route missing")
need("AlertDialog" not in dialog, "default AlertDialog is forbidden")
need("TaskDetailsForm(" in dialog, "dialog does not reuse shared form")
need("LayoutBuilder(" in dialog, "adaptive width branch missing")
need("constraints.maxWidth < 600" in dialog, "narrow adaptive breakpoint missing")
need("if (_saving) return;" in dialog, "duplicate-save protection missing")
need("buildNewTask(" in dialog and "applyTo(" in dialog, "create/edit projection missing")
need("AbsorbPointer" in dialog, "saving interaction lock missing")
for label in (
    "افزودن کار با جزئیات",
    "ویرایش کار",
    "افزودن کار",
    "ذخیره تغییرات",
    "انصراف",
):
    need(label in dialog, f"dialog Persian action missing: {label}")

# Planning labels.
labels = sources["labels"]
for function_name in (
    "taskStartLabel",
    "taskDueLabel",
    "taskEstimatedDurationLabel",
):
    need(function_name in labels, f"planning label function missing: {function_name}")
need("Jalali.fromDateTime" in labels, "planning labels are not Jalali-aware")
need("toLocal()" in labels, "planning labels do not convert UTC to local")
need("taskPersianDigits" in labels, "Persian digits helper missing")

# TasksPanel integration and legacy quick-add preservation.
panel = sources["panel"]
for token in (
    "hintText: 'یک کار جدید بنویسید…'",
    "_addTask()",
    "افزودن با جزئیات",
    "_addTaskWithDetails()",
    "TaskDetailsDialogMode.create",
    "TaskDetailsDialogMode.edit",
    "await repository.create(result)",
    "await repository.transition(",
    "await ref.read(taskRepositoryProvider).update(result)",
    "taskStartLabel(task)",
    "taskDueLabel(task)",
    "taskEstimatedDurationLabel(task)",
    "_TaskPlanningChip",
):
    need(token in panel, f"TasksPanel integration missing: {token}")
need("_editController" not in panel, "legacy inline title editor remains")
need("_editing" not in panel, "legacy duplicate edit state remains")
need(
    "task.status != TaskStatus.canceled" in panel,
    "canceled-task hiding was lost",
)
need(
    "TaskStatus.completed" in panel and "_toggleTask" in panel,
    "completion transition was lost",
)

# Tests prove behavior rather than source shape only.
coverage = {
    "date_time_test": (
        "null state uses Persian unset labels",
        "custom Jalali date selection preserves local time",
        "project time selector preserves selected date",
        "find.byType(CalendarDatePicker), findsNothing",
        "narrow width",
    ),
    "duration_test": (
        "emits numeric hour and minute values",
        "clear action is explicit",
        "narrow width wraps without overflow",
        "59",
    ),
    "dialog_test": (
        "create mode renders one complete shared task form",
        "blank title stays open",
        "blocks duplicates",
        "preserves immutable workflow fields",
        "clear actions remove every optional planning value",
        "due-before-start",
        "narrow layout",
        "find.byType(AlertDialog), findsNothing",
    ),
    "panel_test": (
        "add with details persists fields and renders metadata",
        "full edit clears optional fields",
        "narrow panel keeps quick add",
        "taskRepositoryProvider",
        "positionInStatus, 0",
        "displayNumber, 1",
    ),
    "labels_test": (
        "formats Jalali local date and time",
        "duration labels cover minutes exact hours and mixed values",
        "isNull",
    ),
}
for test_name, tokens in coverage.items():
    source = sources[test_name]
    for token in tokens:
        need(token in source, f"{test_name} coverage missing: {token}")

print(
    "OK: Heavy Task 2.2 UI package provides tested Liquid Glass Jalali/local "
    "date-time and duration controls, one adaptive create/edit dialog, "
    "canonical draft projection, detailed add, full edit, concise planning "
    "metadata, quick-add compatibility, and narrow-layout coverage."
)
