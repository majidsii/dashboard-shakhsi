# Task Panel Fidelity Stage 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring task rows and task interactions in the Flutter dashboard in line with the original version-one HTML while preserving the approved Liquid Glass background and both themes.

**Architecture:** Keep task-preview state local to `TasksPanel` for this visual-fidelity checkpoint. Build focused private widgets for row numbering, priority chips, edit/delete actions, and animated insertion/removal. Reuse the existing original palette and field/glass controls rather than introducing new dependencies.

**Tech Stack:** Flutter 3.44, Dart 3.12, Material widgets without Ink ripple, existing OriginalPalette/OriginalPressable controls.

## Global Constraints

- Preserve the current dark-background softening and all approved stage-two visual tokens.
- Do not change the finance panel.
- Match the original task CSS dimensions: row radius 20, row blur 16, 9px row gap, 24px check control, 31px action controls, 15px task text.
- Keep Persian RTL labels and Persian digits.
- Keep `flutter analyze` clean and all tests passing.

---

### Task 1: Add task interaction regression tests

**Files:**
- Create: `app/test/features/dashboard/tasks_panel_test.dart`

**Interfaces:**
- Consumes: `TasksPanel` public widget.
- Produces: regression coverage for add, number, priority, complete, edit, delete, and status/footer copy.

- [ ] Write widget tests that add a task and verify the version-one row controls.
- [ ] Verify the tests fail before the implementation because row numbering/edit/priority behavior is absent.

### Task 2: Port version-one task row behavior

**Files:**
- Modify: `app/lib/features/dashboard/presentation/widgets/tasks_panel.dart`

**Interfaces:**
- Consumes: existing `_TaskPreview`, `OriginalPressable`, `OriginalFieldSurface`, and `OriginalPalette`.
- Produces: numbered animated rows with inline editing, priority cycling, completion, and deletion.

- [ ] Sort active tasks before completed tasks, then apply the selected ordering.
- [ ] Add exact status/footer copy from the original HTML.
- [ ] Add visible Persian row numbering.
- [ ] Add priority chip, pencil button, delete button, and inline edit field.
- [ ] Add insertion and deletion animations without Material ripple.
- [ ] Restore context-specific empty-state copy.

### Task 3: Verify source contract and package patch

**Files:**
- Create: `app/tool/verify_task_fidelity_stage3.py`
- Create: `APPLY.md`

**Interfaces:**
- Produces: a lightweight source contract and user application instructions.

- [ ] Check required visual and interaction markers.
- [ ] Run static import/path checks.
- [ ] Package only changed source, tests, verifier, plan, and instructions.
