# Task 2.8 — Quick-Entry Templates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add persistent built-in and custom Task templates that prefill the existing Task Details flow without creating Tasks until the user explicitly saves the reviewed draft.

**Architecture:** Add a separate Task Template bounded context with its own domain model, Drift repository, system catalog/synchronizer, codecs, mappers, and presentation draft/UI. Templates store reusable intent only; Task identity, fixed scheduling dates, lifecycle state, recurrence anchors/history, reminder row identities, and timer data never enter template persistence. Schema 8 adds one unified `task_templates` table; system catalog synchronization preserves user visibility/order for existing built-ins while allowing new built-ins to appear deterministically.

**Tech Stack:** Flutter desktop, Riverpod, Drift/SQLite, existing Task Details/Reminder/Recurrence UI and domain, `shamsi_date`, Flutter widget tests.

## Global Constraints

- `PROJECT_ROADMAP.md` is the Source of Truth for Task 2.8 scope and approved behavior.
- Tasks 2.1–2.7 and their approved decisions are closed unless fresh repository evidence proves a regression.
- Current database schema is **7**; Task 2.8 moves it append-only to **8**.
- Do not run `flutter upgrade`.
- Do not change `TaskItem` or `TaskRepository` to persist template state.
- Do not create Tasks, reminder rows, recurrence rows, notification schedules, timer entries, or occurrence history when a template is selected.
- Start/due dates remain empty when applying a template.
- Template reminder identities and recurrence identities are always fresh when the Task is eventually saved.
- System templates cannot be edited in place or permanently deleted.
- All implementation proceeds RED → GREEN.
- Before declaring Task 2.8 complete: focused tests, Task 2.5/2.6/2.7 semantic verifiers, `flutter analyze`, full `flutter test`, `flutter build linux --debug`, and `git diff --check` must all be fresh and green.

---

## Frozen product decisions for implementation

### Initial built-in catalog

| systemKey | Template name | Initial Task title | Priority | Estimated duration | Reminder defaults | Recurrence default |
|---|---|---|---:|---:|---|---|
| `meeting` | جلسه | `جلسه با …` | 2 | 60 min | 15 minutes before | none |
| `follow_up` | پیگیری | `پیگیری …` | 2 | 20 min | at due | none |
| `deep_work` | کار عمیق | `کار عمیق روی …` | 3 | 120 min | none | none |
| `daily_work` | کار روزانه | `کار روزانه …` | 1 | 30 min | none | daily, interval 1, no end |
| `payment_due` | موعد پرداخت | `پرداخت …` | 3 | 10 min | one day before + at due | none |
| `call_message` | تماس / پیام | `تماس / پیام با …` | 1 | 15 min | 15 minutes before | none |
| `personal_errand` | خرید / کار شخصی | `خرید / کار شخصی …` | 0 | 30 min | none | none |

All built-ins start with empty description, `hidden = false`, and catalog order `0..6`.

### Validation policy

- `templateName`: trim, required, non-empty.
- `initialTaskTitle`: trim; **empty is allowed** because the existing Task Details validation remains the final Task-save boundary.
- `priority`: `0..3`.
- estimated duration: null or positive minutes.
- reminder defaults: at most one entry per `TaskReminderTrigger`.
- template recurrence: anchor-free; interval >= 1; frequency-specific selectors must be valid.
- relative recurrence end `daysAfterAnchor`: integer >= 1.
- `createdAtUtc` and `updatedAtUtc` must be UTC; updated >= created.
- `systemKey`: required only for `system`, forbidden for `custom`.
- `displayOrder`: zero-based and scoped independently to `TaskTemplateKind.system` and `TaskTemplateKind.custom`.

### System synchronization rule

1. Match built-ins by stable `systemKey`, never by translated name.
2. Existing system rows keep their `id`, `hidden`, and `displayOrder`.
3. Existing system canonical content is refreshed from the app catalog when catalog content changes.
4. Missing catalog entries are inserted once.
5. On an existing installation, a newly introduced system template is appended after the current maximum system order so existing user ordering is unchanged.
6. On a fresh installation, catalog order is `0..N-1`.
7. Re-running synchronization is idempotent and never duplicates a `systemKey`.
8. “Restore system defaults” sets current system templates visible and restores current catalog order/content; custom rows are untouched.

---

## File structure to add

```text
lib/features/tasks/domain/
  task_template.dart
  task_template_recurrence.dart
  task_template_repository.dart

lib/features/tasks/data/
  task_template_codec.dart
  drift_task_template_repository.dart
  system_task_template_catalog.dart
  task_template_synchronizer.dart

lib/features/tasks/application/
  task_template_mapper.dart

lib/features/tasks/presentation/task_templates/
  task_template_draft.dart
  task_template_recurrence_draft.dart
  task_template_picker.dart
  task_template_manager_dialog.dart
  task_template_editor_dialog.dart
```

Tests mirror those boundaries under `test/features/tasks/...` plus schema/restart tests under `test/core/database/`.

---

### Task 1: Freeze Task Template domain invariants

**Files:**
- Create: `lib/features/tasks/domain/task_template.dart`
- Create: `lib/features/tasks/domain/task_template_recurrence.dart`
- Create: `lib/features/tasks/domain/task_template_repository.dart`
- Create: `test/features/tasks/domain/task_template_test.dart`
- Create: `test/features/tasks/domain/task_template_recurrence_test.dart`

**Interfaces:**

```dart
enum TaskTemplateKind { system, custom }

final class TaskTemplateReminderDefault {
  const TaskTemplateReminderDefault({
    required this.trigger,
    required this.privacyMode,
  });

  final TaskReminderTrigger trigger;
  final NotificationPrivacyMode privacyMode;
}

enum TaskTemplateRecurrenceEndKind { never, afterCount, daysAfterAnchor }

final class TaskTemplateRecurrenceEnd {
  const TaskTemplateRecurrenceEnd.never();
  factory TaskTemplateRecurrenceEnd.afterCount(int count);
  factory TaskTemplateRecurrenceEnd.daysAfterAnchor(int days);
}

final class TaskTemplateRecurrence {
  // Same reusable recurrence intent as RecurrenceRule, but no occurrence anchor.
  // Contains frequency/interval/calendar/timezone/selectors/invalid-date-policy/end.
}

final class TaskTemplate {
  TaskTemplate({
    required String id,
    required this.kind,
    String? systemKey,
    required String templateName,
    required String initialTaskTitle,
    String? description,
    required this.priority,
    this.estimatedDurationMinutes,
    List<TaskTemplateReminderDefault> reminderDefaults = const [],
    this.recurrenceDefault,
    required this.hidden,
    required this.displayOrder,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
}
```

Repository contract:

```dart
abstract interface class TaskTemplateRepository {
  Stream<List<TaskTemplate>> watchAll();
  Future<List<TaskTemplate>> getAll();
  Future<TaskTemplate?> getById(String id);

  Future<void> createCustom(TaskTemplate template);
  Future<void> updateCustom(TaskTemplate template);
  Future<void> deleteCustom(String id);

  Future<TaskTemplate> duplicateAsCustom({
    required String sourceId,
    required String newId,
    required DateTime savedAtUtc,
  });

  Future<void> setHidden({
    required String id,
    required bool hidden,
    required DateTime changedAtUtc,
  });

  Future<void> reorderKind({
    required TaskTemplateKind kind,
    required List<String> orderedIds,
    required DateTime changedAtUtc,
  });

  Future<void> reconcileSystemCatalog({
    required List<TaskTemplate> canonicalSystemTemplates,
    required DateTime changedAtUtc,
  });

  Future<void> restoreSystemDefaults({
    required List<TaskTemplate> canonicalSystemTemplates,
    required DateTime changedAtUtc,
  });
}
```

- [ ] Write RED tests for trimming/normalization, blank template name, allowed blank initial title, invalid priority/duration/order, UTC timestamps, system/custom key invariant, duplicate reminder triggers, recurrence selector validation, `afterCount >= 1`, and `daysAfterAnchor >= 1`.
- [ ] Run `flutter test test/features/tasks/domain/task_template_test.dart test/features/tasks/domain/task_template_recurrence_test.dart` and confirm RED because domain types do not exist.
- [ ] Implement the smallest immutable domain types and equality/hash behavior needed by tests.
- [ ] Re-run the two focused domain tests until GREEN.

---

### Task 2: Add versioned template codecs

**Files:**
- Create: `lib/features/tasks/data/task_template_codec.dart`
- Create: `test/features/tasks/data/task_template_codec_test.dart`

**Interfaces:**

```dart
final class TaskTemplateCodec {
  const TaskTemplateCodec();

  String encodeReminderDefaults(List<TaskTemplateReminderDefault> values);
  List<TaskTemplateReminderDefault> decodeReminderDefaults(String source);

  String? encodeRecurrence(TaskTemplateRecurrence? value);
  TaskTemplateRecurrence? decodeRecurrence(String? source);
}
```

Persistence JSON uses explicit `version: 1`. Recurrence JSON contains no anchor and supports only template end kinds `never`, `afterCount`, and `daysAfterAnchor`.

- [ ] Write RED round-trip tests for all reminder triggers/privacy modes and daily/weekly/monthly/yearly recurrence configurations.
- [ ] Add RED malformed/unknown-version/unknown-enum tests.
- [ ] Verify RED.
- [ ] Implement strict versioned JSON encode/decode; do not reuse `TaskRecurrenceCodec.encodeRule()` because that codec requires a concrete anchor and absolute `RecurrenceEnd.until`.
- [ ] Re-run codec tests until GREEN.

---

### Task 3: Schema 7 → 8 and restart-safe storage

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Regenerate: `lib/core/database/app_database.g.dart`
- Create: `test/core/database/task_template_schema_migration_test.dart`
- Create: `test/core/database/task_template_restart_test.dart`
- Modify: `test/core/database/database_restart_test.dart` only if the project’s aggregate schema-chain fixture requires explicit schema 8 coverage.

**Table:** `task_templates`

```text
id                          TEXT PRIMARY KEY
template_kind               TEXT NOT NULL  CHECK system|custom
system_key                  TEXT NULL UNIQUE
template_name               TEXT NOT NULL
initial_task_title          TEXT NOT NULL
description                 TEXT NULL
priority                    INTEGER NOT NULL CHECK 0..3
estimated_duration_minutes  INTEGER NULL CHECK > 0
reminder_defaults_json      TEXT NOT NULL
recurrence_default_json     TEXT NULL
hidden                      INTEGER NOT NULL
display_order               INTEGER NOT NULL CHECK >= 0
created_at_utc              DATETIME NOT NULL
updated_at_utc              DATETIME NOT NULL
```

Additional constraints:

```text
CHECK length(trim(template_name)) > 0
CHECK ((template_kind = 'system' AND system_key IS NOT NULL AND length(trim(system_key)) > 0)
    OR (template_kind = 'custom' AND system_key IS NULL))
CHECK updated_at_utc >= created_at_utc
UNIQUE(template_kind, display_order)
```

Migration is append-only:

```dart
int get schemaVersion => 8;

if (from < 8) {
  await migrator.createTable(taskTemplateRows);
}
```

- [ ] Write a RED schema-7 fixture test containing Tasks, reminder rows, recurrence rows/exceptions/completions, timer entries, and notification schedules; upgrade to 8 and assert all old rows are untouched and the new table exists empty.
- [ ] Write RED restart test: create custom/system-state rows through schema 8, close DB, reopen same file, verify exact persisted values/order/visibility.
- [ ] Run those tests and confirm RED.
- [ ] Add `TaskTemplateRows`, register it in `@DriftDatabase`, increment schema to 8, and add only `if (from < 8) createTable` migration.
- [ ] Run `dart run build_runner build --delete-conflicting-outputs` (or the repository’s established Drift generation command if different).
- [ ] Re-run migration/restart tests until GREEN.

---

### Task 4: Implement atomic Drift repository behavior

**Files:**
- Create: `lib/features/tasks/data/drift_task_template_repository.dart`
- Create: `test/features/tasks/data/drift_task_template_repository_test.dart`

**Required behavior:**

- `watchAll/getAll`: deterministic `kind, displayOrder, id` ordering.
- `createCustom`: reject system values, assign/require custom order coherently, no partial write.
- `updateCustom`: reject existing system rows and preserve identity/kind/order unless explicitly allowed by the update contract.
- `deleteCustom`: reject system rows; compact remaining custom order.
- `setHidden`: allowed for system/custom and persists across restart.
- `duplicateAsCustom`: source may be system/custom; output is custom, `systemKey = null`, `hidden = false`, fresh ID/timestamps, appended to custom order, name `کپی ${source.templateName}`; reusable content copied exactly.
- `reorderKind`: supplied IDs must equal the complete current ID set for exactly one kind; reject duplicate, missing, extra, or foreign-kind IDs atomically; use temporary high-range positions before writing `0..N-1`.
- `reconcileSystemCatalog`: transactionally apply the frozen synchronization rule.
- `restoreSystemDefaults`: restore current system catalog content, visibility, and catalog order; custom rows untouched.

- [ ] Write RED CRUD/restriction tests.
- [ ] Write RED hide/restore/duplicate tests.
- [ ] Write RED reorder atomicity tests for duplicate/incomplete/foreign IDs and no partial writes.
- [ ] Write RED sync tests: fresh install, second idempotent run, canonical content update preserving user hidden/order, new built-in append without disturbing existing user order, and no duplicate `systemKey`.
- [ ] Verify RED.
- [ ] Implement repository transactions and strict row/domain mapping through `TaskTemplateCodec`.
- [ ] Re-run repository tests until GREEN.

---

### Task 5: Add canonical system catalog and synchronizer

**Files:**
- Create: `lib/features/tasks/data/system_task_template_catalog.dart`
- Create: `lib/features/tasks/data/task_template_synchronizer.dart`
- Create: `test/features/tasks/data/system_task_template_catalog_test.dart`
- Create: `test/features/tasks/data/task_template_synchronizer_test.dart`

**Interfaces:**

```dart
final class SystemTaskTemplateCatalog {
  const SystemTaskTemplateCatalog();
  List<TaskTemplate> build({required DateTime nowUtc});
}

final class TaskTemplateSynchronizer {
  const TaskTemplateSynchronizer({
    required TaskTemplateRepository repository,
    required SystemTaskTemplateCatalog catalog,
    required DateTime Function() nowUtc,
  });

  Future<void> synchronize();
  Future<void> restoreDefaults();
}
```

- [ ] Write RED catalog test asserting exactly the seven frozen entries, unique stable keys, exact default metadata, and order 0..6.
- [ ] Write RED synchronizer tests asserting it delegates canonical reconciliation and restore through one transaction boundary.
- [ ] Verify RED.
- [ ] Implement catalog and synchronizer.
- [ ] Re-run focused tests until GREEN.

---

### Task 6: Map templates to Task Details without leaking identities or dates

**Files:**
- Create: `lib/features/tasks/application/task_template_mapper.dart`
- Modify: `lib/features/tasks/presentation/task_details/task_recurrence_draft.dart`
- Modify: `lib/features/tasks/presentation/task_details/task_recurrence_field.dart`
- Create: `test/features/tasks/application/task_template_mapper_test.dart`
- Modify/Create focused tests for `TaskRecurrenceDraft` relative-link behavior.

**Interfaces:**

```dart
final class TaskTemplateMapper {
  const TaskTemplateMapper();

  TaskDetailsDraft toTaskDetailsDraft(TaskTemplate template);

  TaskTemplateDraft fromTaskDetailsDraft(TaskDetailsDraft source);
}
```

`toTaskDetailsDraft()` must:

- copy initial title/description/priority/duration;
- set `startLocal = null` and `dueLocal = null` always;
- create reminder drafts with `existingId = null` and `createdAtUtc = null`;
- create recurrence draft with `existingId = null` and `existingCreatedAtUtc = null`;
- never carry task status/position/identity/lifecycle/timer/occurrence state because those concepts are absent from `TaskTemplate`.

Extend `TaskRecurrenceDraft` with presentation-only relative-end linkage:

```dart
int? relativeEndDaysAfterAnchor;

DateTime? effectiveUntilLocal(DateTime? anchorLocal);
```

Rules:

- `daysAfterAnchor` maps to `endKind = RecurrenceEndKind.until` plus `relativeEndDaysAfterAnchor = N`.
- while link exists, changing start/due anchor recomputes effective end from the current anchor.
- manually editing the absolute “until” date clears `relativeEndDaysAfterAnchor`.
- `build()` uses the effective derived date.
- no new value is added to core `RecurrenceEndKind`.

`fromTaskDetailsDraft()` must:

- strip start/due;
- strip reminder existing IDs/created timestamps;
- strip recurrence existing ID/created timestamp and anchor;
- convert absolute recurrence end to `daysAfterAnchor` using the draft anchor (`dueLocal ?? startLocal`) and a rounded 24-hour day delta so DST 23/25-hour day transitions still map to the intended day count;
- preserve `never` and `afterCount` directly;
- reject an absolute-until recurrence with no anchor or non-positive relative delta.

- [ ] Write RED template→draft tests for no fixed dates, copied reusable fields, fresh reminder identities, fresh recurrence identity, and no immediate Task persistence.
- [ ] Write RED relative-end tests for derived end, anchor changes, manual override breaking link, and DST-adjacent day-count conversion.
- [ ] Write RED task-draft→template tests for excluded identity/scheduling data.
- [ ] Verify RED.
- [ ] Implement mapper plus the minimal `TaskRecurrenceDraft/Field` extension.
- [ ] Re-run mapper/recurrence focused tests until GREEN.

---

### Task 7: Add dedicated Template presentation drafts/editor

**Files:**
- Create: `lib/features/tasks/presentation/task_templates/task_template_draft.dart`
- Create: `lib/features/tasks/presentation/task_templates/task_template_recurrence_draft.dart`
- Create: `lib/features/tasks/presentation/task_templates/task_template_editor_dialog.dart`
- Create: `test/features/tasks/presentation/task_templates/task_template_draft_test.dart`
- Create: `test/features/tasks/presentation/task_templates/task_template_editor_dialog_test.dart`

**Behavior:**

- Editor fields: template name, initial Task title, description, priority, estimated duration, reminder defaults, recurrence defaults.
- No Start/Due controls.
- System templates are never opened in in-place edit mode.
- Initial Task title may be blank; template name may not.
- Reminder defaults can be configured even though no due date exists.
- Recurrence defaults can be configured without an anchor and can choose: no end / after N occurrences / N days after anchor.
- Editor returns a validated custom `TaskTemplateDraft`; repository persistence remains outside the dialog.

- [ ] Write RED draft validation tests.
- [ ] Write RED widget tests proving no Start/Due controls exist and the relative recurrence-end editor exists.
- [ ] Write RED create/edit custom result tests.
- [ ] Verify RED.
- [ ] Implement the dedicated editor without weakening `TaskDetailsDraft` validation.
- [ ] Re-run focused tests until GREEN.

---

### Task 8: Wire repository and startup synchronization through Riverpod

**Files:**
- Modify: `lib/core/providers/persistence_providers.dart`
- Create/Modify provider tests following the existing persistence-provider test location/pattern in the repository.

**Providers:**

```dart
final taskTemplateRepositoryProvider = Provider<TaskTemplateRepository>((ref) {
  return DriftTaskTemplateRepository(ref.watch(appDatabaseProvider));
});

final systemTaskTemplateCatalogProvider = Provider<SystemTaskTemplateCatalog>(
  (ref) => const SystemTaskTemplateCatalog(),
);

final taskTemplateSynchronizerProvider = Provider<TaskTemplateSynchronizer>((ref) {
  return TaskTemplateSynchronizer(
    repository: ref.watch(taskTemplateRepositoryProvider),
    catalog: ref.watch(systemTaskTemplateCatalogProvider),
    nowUtc: () => ref.read(appClockProvider).now().toUtc(),
  );
});

final taskTemplateStartupProvider = FutureProvider<void>((ref) async {
  await ref.watch(taskTemplateSynchronizerProvider).synchronize();
});

final taskTemplatesProvider = StreamProvider<List<TaskTemplate>>((ref) async* {
  await ref.watch(taskTemplateStartupProvider.future);
  yield* ref.watch(taskTemplateRepositoryProvider).watchAll();
});
```

- [ ] Write RED provider test proving built-ins are synchronized before the exposed template stream is consumed.
- [ ] Write RED restart/provider test proving user hidden/order state is not reset by provider recreation.
- [ ] Verify RED.
- [ ] Add the providers using existing `appClockProvider` and `appDatabaseProvider` conventions.
- [ ] Re-run focused provider tests until GREEN.

---

### Task 9: Build Picker and Manager flows

**Files:**
- Create: `lib/features/tasks/presentation/task_templates/task_template_picker.dart`
- Create: `lib/features/tasks/presentation/task_templates/task_template_manager_dialog.dart`
- Create: `test/features/tasks/presentation/task_templates/task_template_picker_test.dart`
- Create: `test/features/tasks/presentation/task_templates/task_template_manager_dialog_test.dart`

**Picker:**

- waits for template startup/sync;
- excludes hidden templates;
- renders System and Custom sections separately, each ordered by `displayOrder`;
- shows name plus optional metadata (initial title, priority, duration, reminder/recurrence indicators);
- selecting an item returns the `TaskTemplate`; it never writes a Task;
- final action opens “مدیریت قالب‌ها”.

**Manager:**

- create custom;
- edit custom;
- delete custom with confirmation;
- duplicate system/custom to custom;
- hide/show both kinds;
- drag reorder within the current kind only;
- restore system defaults/visibility;
- visually distinguish system templates;
- never expose permanent-delete/edit-in-place actions for system rows.

- [ ] Write RED picker hidden-exclusion/section/order/selection tests.
- [ ] Write RED manager system-vs-custom capability tests.
- [ ] Write RED duplicate/hide/restore/reorder UI-to-repository interaction tests.
- [ ] Verify RED.
- [ ] Implement picker/manager using providers and dedicated editor.
- [ ] Re-run focused presentation tests until GREEN.

---

### Task 10: Reuse full Task Details create flow for templates and add “Save as template”

**Files:**
- Modify: `lib/features/tasks/presentation/task_details/task_details_dialog.dart`
- Modify: `lib/features/tasks/presentation/task_details/task_details_form.dart` only if a safe accessor/action hook is needed.
- Modify: `test/features/tasks/presentation/task_details/task_details_dialog_test.dart`
- Create/Modify: focused Task Details template integration tests.

**Create API change:**

```dart
Future<TaskDetailsDialogResult?> showTaskDetailsEditorDialog({
  required BuildContext context,
  required TaskDetailsDialogMode mode,
  TaskItem? initialTask,
  TaskDetailsDraft? initialCreateDraft,
  ...
});
```

Rules:

- `initialCreateDraft` is allowed only in create mode.
- create mode uses `initialCreateDraft ?? TaskDetailsDraft.create(...)`.
- selecting a template therefore opens the exact existing full Task Details form with Start/Due empty.
- dialog still returns a `TaskDetailsDialogResult`; persistence remains in `TasksPanel`.

**Save-as-template action:**

Add edit-mode action **ذخیره به‌عنوان قالب**. It reads the current form draft, validates reusable values, maps through `TaskTemplateMapper.fromTaskDetailsDraft`, opens the template editor with `templateName` initially equal to the current Task title, and persists a **new custom template** only after template-editor confirmation. It does not mutate the Task and does not copy fixed dates/IDs/history/timer data.

- [ ] Write RED test that template-prefilled create dialog retains template fields but Start/Due are null and no Task exists before dialog save.
- [ ] Write RED test that normal empty create flow is unchanged.
- [ ] Write RED edit-mode “ذخیره به‌عنوان قالب” tests for fresh custom identity and excluded fields.
- [ ] Verify RED.
- [ ] Implement the minimal dialog API/action changes.
- [ ] Re-run Task Details focused tests until GREEN.

---

### Task 11: Replace New Task with split action in Tasks panel

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/tasks_panel.dart`
- Modify/Create: `test/features/dashboard/tasks_panel_test.dart`
- Modify/Create: `test/features/dashboard/tasks_panel_persistence_test.dart`

**Flow:**

Primary segment:

```text
New Task -> existing empty Task Details create flow
```

Arrow segment:

```text
Arrow
 -> Template Picker
 -> select template
 -> TaskTemplateMapper.toTaskDetailsDraft(template)
 -> full Task Details create dialog
 -> user reviews/adds schedule
 -> existing Task + reminder + recurrence save path
```

Manager is reachable from the Picker.

The save transaction/application behavior after dialog confirmation must remain the existing Task creation boundary: task repository creates the Task; reminder repository/service persists fresh reminder rules; recurrence service/repository persists fresh recurrence rule; notification projection runs only after Task persistence.

- [ ] Write RED widget test for two independently clickable split-action segments.
- [ ] Write RED primary-segment regression test for empty Task flow.
- [ ] Write RED template-segment test proving picker opens, selection opens full Task Details, and Task count remains unchanged until final save.
- [ ] Write RED integration test proving saved templated Task gets new reminder/recurrence IDs and no fixed template scheduling values.
- [ ] Write RED manager-entry reachability test.
- [ ] Verify RED.
- [ ] Implement split action and template flow without changing List/Kanban/Calendar behavior.
- [ ] Re-run dashboard/Task Details focused tests until GREEN.

---

### Task 12: Focused regression, semantic verifier, checkpoint, and Roadmap handoff

**Files:**
- Create: `tool/verify_phase2_task2_8_complete.py`
- Create: `docs/superpowers/checkpoints/2026-08-07-task-2-8-quick-entry-templates-checkpoint.md`
- Modify: `PROJECT_ROADMAP.md`

**Focused verification set must include at least:**

```text
test/features/tasks/domain/task_template_test.dart
test/features/tasks/domain/task_template_recurrence_test.dart
test/features/tasks/data/task_template_codec_test.dart
test/features/tasks/data/drift_task_template_repository_test.dart
test/features/tasks/data/system_task_template_catalog_test.dart
test/features/tasks/data/task_template_synchronizer_test.dart
test/features/tasks/application/task_template_mapper_test.dart
test/features/tasks/presentation/task_templates/
test/features/tasks/presentation/task_details/task_details_dialog_test.dart
test/features/dashboard/tasks_panel_test.dart
test/features/dashboard/tasks_panel_persistence_test.dart
test/core/database/task_template_schema_migration_test.dart
test/core/database/task_template_restart_test.dart
```

Retain regressions for reminders, recurrence, calendar, timer, and database restart chain.

- [ ] Run Task 2.8 focused tests and record the actual count.
- [ ] Run existing Task 2.5 semantic verifier.
- [ ] Run existing Task 2.6 semantic verifier.
- [ ] Run existing Task 2.7 semantic verifier.
- [ ] Run `flutter analyze` and require no issues.
- [ ] Run full `flutter test` and record actual total.
- [ ] Run `flutter build linux --debug` and require success.
- [ ] Run `git diff --check` and require clean output.
- [ ] Review `git diff --stat` and `git status -sb` for scope leaks.
- [ ] Commit implementation with a focused message such as `feat: add quick-entry task templates`.
- [ ] Push implementation commit and record its exact full hash.
- [ ] Write `tool/verify_phase2_task2_8_complete.py` to semantically assert schema 8, template table/repository/catalog/mapper/UI/provider wiring, seven stable built-ins, relative-end representation, and Roadmap/checkpoint markers.
- [ ] Run Task 2.8 semantic verifier against the implementation commit and require PASS.
- [ ] Update checkpoint with exact implementation commit and fresh evidence.
- [ ] Update `PROJECT_ROADMAP.md`: Task 2.8 → `IMPLEMENTED AND FRESHLY VERIFIED`, schema → 8, record verification counts/commit/checkpoint, update latest checkpoint/verifier, and advance `CURRENT TASK` to **2.9 — Undo, 30-Day Trash, and Audit History** with status `DESIGN IN PROGRESS` or `PENDING` according to the next-session boundary.
- [ ] Also refresh the stale `Last known synced HEAD at handoff capture` field to the actual checkpoint/handoff commit as part of this documentation boundary.
- [ ] Commit checkpoint/docs with `docs: checkpoint quick-entry task templates`.
- [ ] Push checkpoint commit.
- [ ] Run final `git status -sb` and confirm branch is clean and synced.

---

## Implementation commit discipline

Use RED → GREEN in the order above. Do not bundle Task 2.9 work. Intermediate local commits are acceptable if a gate becomes large, but the checkpoint must record the exact pushed Task 2.8 implementation commit that passed fresh verification.

## Self-review against approved Task 2.8 design

- Hybrid system + unlimited custom templates: covered.
- Seven built-ins with frozen defaults: covered.
- System hide/restore/reorder/duplicate, no edit/delete: covered.
- Custom CRUD/hide/show/duplicate/reorder: covered.
- Separate template name vs Task title: covered.
- Reusable fields only; no fixed Task schedule/identity/history/timer state: covered.
- Picker opens full Task Details rather than persisting immediately: covered.
- Dedicated template draft/editor boundary: covered.
- Reminder defaults create fresh identities only when Task is saved: covered.
- Anchor-free recurrence and relative days-after-anchor end: covered.
- Save existing Task as template with absolute-until → relative days conversion: covered.
- Unified table and deterministic system synchronization: covered.
- Schema 7 → 8 migration/restart: covered.
- Validation/error/atomic reorder cases: covered.
- Split New Task action, Picker, Manager, restore defaults: covered.
- Final focused/full/analyze/build/diff/verifier/checkpoint/Roadmap protocol: covered.
