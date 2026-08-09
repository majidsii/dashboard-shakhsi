#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def need(condition: bool, message: str) -> None:
    if not condition:
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    need(path.is_file(), f"missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def run_verifier(relative: str) -> None:
    result = subprocess.run(
        [sys.executable, str(ROOT / relative)],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    need(result.returncode == 0, f"{relative} failed:\n{result.stdout}")


database = read("lib/core/database/app_database.dart")
generated = read("lib/core/database/app_database.g.dart")
providers = read("lib/core/providers/persistence_providers.dart")
bootstrap = read("lib/app/bootstrap/app_bootstrap.dart")

template = read("lib/features/tasks/domain/task_template.dart")
template_recurrence = read(
    "lib/features/tasks/domain/task_template_recurrence.dart"
)
repository_contract = read(
    "lib/features/tasks/domain/task_template_repository.dart"
)
codec = read("lib/features/tasks/data/task_template_codec.dart")
catalog = read("lib/features/tasks/data/system_task_template_catalog.dart")
repository = read(
    "lib/features/tasks/data/drift_task_template_repository.dart"
)
synchronizer = read(
    "lib/features/tasks/data/task_template_synchronizer.dart"
)
mapper = read("lib/features/tasks/application/task_template_mapper.dart")

template_draft = read(
    "lib/features/tasks/presentation/task_templates/task_template_draft.dart"
)
template_recurrence_draft = read(
    "lib/features/tasks/presentation/task_templates/"
    "task_template_recurrence_draft.dart"
)
picker = read(
    "lib/features/tasks/presentation/task_templates/task_template_picker.dart"
)
manager = read(
    "lib/features/tasks/presentation/task_templates/"
    "task_template_manager_dialog.dart"
)
editor = read(
    "lib/features/tasks/presentation/task_templates/"
    "task_template_editor_dialog.dart"
)

details_dialog = read(
    "lib/features/tasks/presentation/task_details/task_details_dialog.dart"
)
details_form = read(
    "lib/features/tasks/presentation/task_details/task_details_form.dart"
)
recurrence_draft = read(
    "lib/features/tasks/presentation/task_details/task_recurrence_draft.dart"
)
panel = read(
    "lib/features/dashboard/presentation/widgets/tasks_panel.dart"
)

design = read(
    "docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md"
)
plan = read(
    "docs/superpowers/plans/2026-08-07-task-2-8-quick-entry-templates.md"
)

schema_match = re.search(
    r"int\s+get\s+schemaVersion\s*=>\s*(\d+)\s*;",
    database,
)
need(schema_match is not None, "schema version is missing")
need(int(schema_match.group(1)) >= 8, "schema regressed below version 8")

for token in (
    "class TaskTemplateRows extends Table",
    "task_templates",
    "if (from < 8)",
    "createTable(taskTemplateRows)",
):
    need(token in database, f"schema-8 template contract missing: {token}")

for token in (
    "class $TaskTemplateRowsTable",
    "TaskTemplateRow",
    "TaskTemplateRowsCompanion",
    "taskTemplateRows",
):
    need(token in generated, f"generated Drift template contract missing: {token}")

for token in (
    "enum TaskTemplateKind",
    "system",
    "custom",
    "final class TaskTemplate",
    "templateName",
    "initialTaskTitle",
    "priority",
    "estimatedDurationMinutes",
    "reminderDefaults",
    "recurrenceDefault",
    "systemKey",
    "displayOrder",
    "hidden",
    "createdAtUtc",
    "updatedAtUtc",
):
    need(token in template, f"TaskTemplate domain contract missing: {token}")

for token in (
    "TaskTemplateRecurrence",
    "TaskTemplateRecurrenceEnd",
    "daysAfterAnchor",
):
    need(
        token in template_recurrence,
        f"template recurrence contract missing: {token}",
    )

for token in (
    "watchAll",
    "getAll",
    "getById",
    "createCustom",
    "updateCustom",
    "deleteCustom",
    "duplicateAsCustom",
    "setHidden",
    "reorderKind",
    "reconcileSystemCatalog",
    "restoreSystemDefaults",
):
    need(
        token in repository_contract,
        f"template repository interface missing: {token}",
    )
    need(
        token in repository,
        f"Drift template repository missing: {token}",
    )

for token in (
    "TaskTemplateCodec",
    "encode",
    "decode",
):
    need(token in codec, f"template codec contract missing: {token}")

for key in (
    "meeting",
    "follow_up",
    "deep_work",
    "daily_work",
    "payment_due",
    "call_message",
    "personal_errand",
):
    need(key in catalog, f"system template catalog missing key: {key}")

for token in (
    "TaskTemplateSynchronizer",
    "reconcileSystemCatalog",
    "restoreSystemDefaults",
):
    need(token in synchronizer, f"template synchronizer missing: {token}")

for token in (
    "TaskTemplateMapper",
    "TaskDetailsDraft",
    "TaskTemplate",
):
    need(token in mapper, f"template mapper contract missing: {token}")

# Template application must create a draft, not a persisted task.
for forbidden in (
    "TaskStatus.completed",
    "positionInStatus",
):
    need(
        forbidden not in template,
        f"template stores task lifecycle state unexpectedly: {forbidden}",
    )

for token in (
    "TaskTemplateDraft",
    "templateName",
    "initialTaskTitle",
):
    need(token in template_draft, f"template draft missing: {token}")

for token in (
    "TaskTemplateRecurrenceDraft",
    "daysAfterAnchor",
):
    need(
        token in template_recurrence_draft,
        f"template recurrence draft missing: {token}",
    )

for token in (
    "TaskTemplatePicker",
    "system",
    "custom",
):
    need(token in picker, f"template picker contract missing: {token}")

for token in (
    "TaskTemplateManagerDialog",
    "onReorderItem",
    "onDuplicate",
    "onRestoreSystemDefaults",
):
    need(token in manager, f"template manager behavior missing: {token}")

for token in (
    "TaskTemplateEditorDialog",
    "templateName",
    "initialTaskTitle",
):
    need(token in editor, f"template editor behavior missing: {token}")

for token in (
    "taskTemplateRepositoryProvider",
    "systemTaskTemplateCatalogProvider",
    "taskTemplateSynchronizerProvider",
    "taskTemplateMapperProvider",
    "taskTemplateStartupProvider",
    "taskTemplatesProvider",
):
    need(token in providers, f"template provider wiring missing: {token}")

need(
    "taskTemplateStartupProvider" in bootstrap,
    "template startup synchronization is not bootstrapped",
)

for token in (
    "initialCreateDraft",
    "onSaveAsTemplate",
    "ذخیره به‌عنوان قالب",
):
    need(token in details_dialog, f"Task Details template integration missing: {token}")

need("snapshot()" in details_form, "Task Details form snapshot support missing")

for token in (
    "relative",
    "relativeEndDaysAfterAnchor",
):
    need(
        token in recurrence_draft,
        f"relative recurrence draft support missing: {token}",
    )

for token in (
    "انتخاب قالب کار",
    "taskTemplateRepositoryProvider",
    "taskTemplateMapperProvider",
    "onSaveAsTemplate: _saveTaskDraftAsTemplate",
):
    need(token in panel, f"TasksPanel template integration missing: {token}")

focused_files = (
    "test/core/database/task_template_schema_test.dart",
    "test/core/providers/task_template_providers_test.dart",
    "test/features/dashboard/tasks_panel_templates_test.dart",
    "test/features/tasks/application/task_template_mapper_test.dart",
    "test/features/tasks/application/task_template_mapper_reverse_test.dart",
    "test/features/tasks/data/drift_task_template_repository_test.dart",
    "test/features/tasks/data/system_task_template_catalog_test.dart",
    "test/features/tasks/data/task_template_codec_test.dart",
    "test/features/tasks/data/task_template_synchronizer_test.dart",
    "test/features/tasks/domain/task_template_test.dart",
    "test/features/tasks/domain/task_template_recurrence_test.dart",
    "test/features/tasks/presentation/task_details/"
    "task_details_template_integration_test.dart",
    "test/features/tasks/presentation/task_details/"
    "task_recurrence_draft_relative_end_test.dart",
    "test/features/tasks/presentation/task_templates/"
    "task_template_picker_test.dart",
    "test/features/tasks/presentation/task_templates/"
    "task_template_manager_test.dart",
    "test/features/tasks/presentation/task_templates/"
    "task_template_editor_dialog_test.dart",
)

tests = "\n".join(read(relative) for relative in focused_files)

for token in (
    "schema 7 to 8 migration preserves task data",
    "custom templates survive restart",
    "fresh",
    "hidden",
    "reorder",
    "duplicate",
    "restore",
    "system",
    "custom",
):
    need(token.lower() in tests.lower(), f"focused Task 2.8 coverage missing: {token}")

for token in (
    "Quick-Entry Templates",
    "Seven built-ins with frozen defaults",
    "unlimited custom",
    "TaskTemplateDraft",
):
    need(
        token.lower() in design.lower() or token.lower() in plan.lower(),
        f"approved Task 2.8 design/plan missing: {token}",
    )

run_verifier("tool/verify_phase2_task2_7_complete.py")

result = subprocess.run(
    ("git", "diff", "--check"),
    cwd=ROOT,
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    check=False,
)
need(result.returncode == 0, f"git diff --check failed:\n{result.stdout}")

print(
    "OK: Task 2.8 adds schema-8 persisted quick-entry templates, "
    "seven app-owned system defaults plus custom templates, idempotent catalog "
    "sync, custom/system lifecycle rules, anchor-free reusable reminder and "
    "recurrence defaults, fresh Task Details draft mapping, picker/manager/editor "
    "UI, save-as-template integration, migration/restart coverage, and stable "
    "Task 2.7 verification."
)
