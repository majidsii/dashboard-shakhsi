# Task 2.2 Design — Description, Start/Due Time, and Estimated Duration

Date: 2026-08-03  
Project: Dashboard Shakhsi v2  
Phase: 2  
Task: 2.2  
Status: Proposed for review

## 1. Purpose

Task 2.2 extends the existing Task v2 foundation with the remaining core planning fields required by the original product design:

- optional multi-line description;
- optional start date/time;
- optional due date/time;
- optional estimated duration.

The implementation must preserve the current Task 2.1 identity, status, ordering, migration, repository, and Tasks panel contracts.

The feature must be complete and production-oriented within this exact scope. It must not pull reminder, recurrence, timer, calendar, subtask, tag, goal, challenge, trash, or audit behavior forward from later Phase 2 tasks.

## 2. Confirmed product constraints

The following constraints are fixed:

- Persian-first and RTL user experience;
- Jalali date input and display;
- device-local wall-clock time for user interaction;
- persisted task timestamps are UTC;
- existing Liquid Glass visual language must remain unchanged;
- current quick-add flow remains available;
- a full-detail creation flow is added;
- the same full-detail form is reused for editing;
- desktop uses a centered Liquid Glass dialog;
- narrow layouts use an adaptive full-screen or near-full-screen presentation with the same visual language;
- no generic Material dialog appearance;
- existing Tasks panel behavior and visual hierarchy must remain compatible.

## 3. Domain model

`TaskItem` gains four optional canonical fields:

```dart
final String? description;
final DateTime? startAtUtc;
final DateTime? dueAtUtc;
final int? estimatedDurationMinutes;
```

### 3.1 Description contract

- optional;
- multi-line;
- trimmed before entering canonical domain state;
- an empty or whitespace-only value becomes `null`;
- plain text only;
- Markdown, rich text, attachments, and embedded content are outside scope;
- no arbitrary short product limit should be introduced unless required by a confirmed platform constraint.

### 3.2 Start and due contract

- `startAtUtc` is optional;
- `dueAtUtc` is optional;
- either may exist independently;
- if both exist, `dueAtUtc` must not be before `startAtUtc`;
- equal start and due instants are valid;
- non-null values must be UTC in canonical `TaskItem` state;
- the UI converts local Jalali date/time input to UTC before constructing or updating `TaskItem`;
- repository mapping converts persisted values to UTC defensively.

No rule ties start or due timestamps to task status in Task 2.2.

### 3.3 Estimated duration contract

- represented as nullable integer minutes;
- absence is `null`;
- zero and negative values are invalid;
- UI may accept hours and minutes but must normalize them to total minutes;
- no artificial 24-hour maximum is introduced;
- actual time and timer-derived duration are outside scope.

### 3.4 Canonicalization

Construction and `copyWith` must preserve one canonical representation:

- description is trimmed;
- blank description becomes `null`;
- date/time values remain nullable;
- duration remains nullable and positive when present.

Because nullable values must also be removable during editing, `copyWith` must support explicit clearing without confusing “argument omitted” with “set to null”. The chosen API should follow the existing explicit-clear convention already used for terminal timestamps or use a small private sentinel pattern if that produces a safer and clearer public contract.

### 3.5 Equality and diagnostics

The four new fields must be included in:

- equality;
- `hashCode`;
- useful diagnostic output where appropriate;
- domain tests.

Existing immutable identity fields remain unchanged:

- `id`;
- `displayNumber`;
- `createdAtUtc`.

## 4. Persistence design

The database schema advances from version 3 to version 4.

`tasks` gains:

```text
description TEXT NULL
start_at_utc INTEGER NULL
due_at_utc INTEGER NULL
estimated_duration_minutes INTEGER NULL
```

### 4.1 Database constraints

The schema must enforce:

```text
estimated_duration_minutes IS NULL
OR estimated_duration_minutes > 0
```

The start/due ordering invariant must also be protected at the persistence boundary where SQLite comparison semantics for Drift timestamps are reliable:

```text
start_at_utc IS NULL
OR due_at_utc IS NULL
OR due_at_utc >= start_at_utc
```

Domain validation remains mandatory even if the database has equivalent checks.

### 4.2 Version 3 to version 4 migration

Migration from schema 3 must:

- preserve every existing task row exactly;
- preserve display numbers;
- preserve status-local positions;
- preserve status and terminal timestamps;
- preserve title, priority, creation, and update timestamps;
- initialize all four new fields to `NULL`;
- preserve the notification table and every unrelated table;
- survive database close and reopen;
- leave `PRAGMA user_version` equal to 4.

Prefer additive `ALTER TABLE ... ADD COLUMN` migration if Drift and SQLite constraints can be expressed safely for the required columns. If table reconstruction is necessary to add complete constraints, it must be deterministic and must retain all Task 2.1 invariants.

Migration tests must verify both data preservation and exact schema shape.

## 5. Repository behavior

`TaskRepository` does not need new methods solely for Task 2.2. Existing operations remain the public persistence interface:

- `create`;
- `update`;
- `watchAll`;
- `watchByStatus`;
- `getById`;
- transition and reorder operations.

`DriftTaskRepository` must map and persist all four new fields.

### 5.1 Create

Create must:

- preserve repository-owned display-number allocation;
- preserve repository-owned status-position allocation;
- persist normalized Task 2.2 fields;
- reject invalid domain state before partial writes;
- remain transactional.

### 5.2 Update

Update must:

- persist title, priority, description, start, due, estimated duration, and `updatedAtUtc`;
- preserve `id`, `displayNumber`, and `createdAtUtc`;
- not silently alter status-local order unless explicitly supplied through the existing canonical task update behavior;
- allow clearing any optional Task 2.2 field;
- remain compatible with status and terminal timestamp invariants.

### 5.3 Transition and reorder

Transition, reorder, delete, and delete-completed behavior must remain unchanged except that the new fields must survive those operations untouched.

## 6. User interface design

## 6.1 Quick add

The existing quick-add row remains available and visually compatible.

Quick add creates:

- title;
- selected priority;
- `planned` status;
- no description;
- no start;
- no due;
- no estimated duration.

It must retain the existing behavior of moving the newly created planned task to position zero.

A new “add with details” action is added near the quick-add controls without weakening the current hierarchy or crowding narrow layouts.

## 6.2 Shared details form

One reusable Task details form supports two modes:

```text
create
edit
```

Create mode starts with empty optional fields.  
Edit mode is initialized from the selected canonical `TaskItem`.

The form contains only fields within Task 2.2 plus existing editable core fields required for a complete task:

- title;
- priority;
- description;
- start date/time;
- due date/time;
- estimated duration.

Status-board operations remain outside this form unless an existing product contract already requires status editing there. Task 2.3 owns the richer List/Kanban workflow.

## 6.3 Liquid Glass compatibility

The form must use the project’s existing:

- design tokens;
- palette;
- glass surfaces;
- borders;
- radii;
- typography;
- controls;
- spacing language;
- motion principles.

It must not introduce a visually separate Material form system.

Desktop:

- centered adaptive glass dialog;
- bounded width and height;
- scrollable content where needed;
- clear primary and secondary actions.

Narrow screens:

- full-screen or near-full-screen adaptive presentation;
- safe-area aware;
- keyboard-safe;
- same tokens and visual language;
- no reduced-capability mobile form.

## 6.4 Jalali and local-time interaction

Users see and select Jalali dates.

Time selection uses the device’s local wall clock.

The form converts selected local date/time to UTC when saving.

When editing, stored UTC values are converted back to local time and shown through Jalali date labels.

Clearing start or due must be explicit and accessible.

## 6.5 Form validation

The form validates before repository writes:

- title is required after trimming;
- blank description is normalized to null;
- if both start and due exist, due cannot precede start;
- estimated duration must be positive;
- hours/minutes input must normalize safely;
- invalid input produces a clear Persian inline error;
- the dialog remains open on validation or repository failure;
- duplicate submissions are prevented while saving.

Repository or unexpected failures must be surfaced through the project’s established error presentation rather than crashing or silently closing the form.

## 6.6 Task row compatibility

The current Tasks panel row must remain recognizable and Liquid Glass-compatible.

Task 2.2 may add concise metadata indicators for available planning data, but it must avoid turning the current row into the future Task 2.3 List/Kanban design.

Permitted concise metadata:

- start label;
- due label;
- estimated duration;
- an indication that a description exists.

Any metadata must remain readable in RTL, adapt to narrow width, and avoid changing current completion, priority, edit, delete, numbering, filtering, and progress behavior.

The existing edit action should open the shared details form rather than only editing the title.

## 7. Explicit non-goals

Task 2.2 does not implement:

- reminder rules or notification projection;
- recurrence rules or occurrences;
- calendar view;
- Kanban or the full Task v2 list redesign;
- timers;
- actual time;
- time entries;
- tags;
- subtasks;
- goal or challenge links;
- templates;
- undo;
- trash;
- audit history;
- dashboard layout configuration.

These remain assigned to later Phase 2 tasks.

## 8. Error handling and consistency

Validation exists at multiple boundaries:

1. UI validation for immediate Persian feedback;
2. domain validation for canonical state;
3. database checks for persisted integrity.

No invalid Task 2.2 state should be partially written.

Migration and restart tests must prove persistent consistency.

The design must not weaken any Task 2.1 atomic transition or per-status ordering guarantee.

## 9. Testing strategy

Implementation follows strict TDD.

### Domain tests

Cover:

- description trimming;
- blank-to-null normalization;
- valid independent start and due;
- due equal to start;
- rejection of due before start;
- rejection of local non-UTC canonical timestamps;
- positive estimated duration;
- rejection of zero and negative duration;
- `copyWith` preservation and explicit clearing;
- equality and hash inclusion.

### Schema and migration tests

Cover:

- schema version 4;
- exact new columns;
- version 3 to 4 migration;
- all legacy values preserved;
- new values initially null;
- check constraints;
- restart after migration.

### Repository tests

Cover:

- create mapping;
- update mapping;
- clearing optional fields;
- watch/get round-trip;
- restart persistence;
- transition and reorder preserving Task 2.2 data;
- display number and status position invariants unchanged.

### Widget tests

Cover:

- existing quick add still works;
- add-with-details opens the complete form;
- create with all fields;
- edit and clear optional fields;
- Jalali/local display from UTC;
- invalid due-before-start feedback;
- invalid duration feedback;
- duplicate-save prevention;
- adaptive narrow layout;
- Liquid Glass component/token usage through stable semantic or widget contracts;
- existing Tasks panel tests remain green.

### Verification

Every Gate follows:

```text
RED
valid observed failure
GREEN
focused tests
flutter analyze
full test suite
Linux debug build
git diff --check
focused commit and push
```

## 10. Proposed implementation boundaries

Task 2.2 should be split into independently verifiable Gates:

1. canonical TaskItem planning fields;
2. schema version 4 and deterministic migration;
3. Drift repository mapping and restart persistence;
4. reusable Task details form domain/controller behavior;
5. Liquid Glass create/edit UI and quick-add integration;
6. compatibility, regression, and Task 2.2 checkpoint.

The detailed file-by-file implementation plan is written only after this design is reviewed and committed.

## 11. Acceptance criteria

Task 2.2 is complete only when:

- all four planning fields exist in canonical domain state;
- all fields persist and survive restart;
- schema 3 migrates deterministically to schema 4;
- invalid time and duration states are rejected;
- quick add remains intact;
- add-with-details and full edit flows work;
- dates are Jalali in the UI and UTC in persistence;
- the new interface fully matches the existing Liquid Glass design language;
- Task 2.1 identity, status, ordering, transitions, panel behavior, and tests remain compatible;
- focused and full tests pass;
- analyze is clean;
- Linux debug build succeeds;
- `git diff --check` is clean;
- a checkpoint records exact Gate commits and fresh verification evidence.
