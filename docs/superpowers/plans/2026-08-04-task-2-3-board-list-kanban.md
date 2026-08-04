# Task 2.3 Atomic Board Operations, List, and Kanban Views Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Task 2.2 evidence and add a production-ready Liquid Glass List/Kanban task experience backed by the existing atomic status transition and per-status reorder repository contracts.

**Architecture:** Keep schema version 4 and `TaskRepository` unchanged. Add a Flutter-independent board operation coordinator that translates final board positions into either one complete same-status reorder or one atomic cross-status transition. Add a dedicated Liquid Glass Kanban widget with four canonical columns, drag handles, drop zones, and accessible move controls, then integrate it as an alternate view inside the existing `TasksPanel` while preserving the current list behavior.

**Tech Stack:** Flutter 3.44+, Dart 3.12, Riverpod 2.6.1, Drift 2.34.2, existing Original/Liquid Glass components, Flutter widget tests, Python semantic verifiers.

## Global Constraints

- Worktree: `~/projects/personal/dashboard-shakhsi-v2-integration`
- Branch: `feat/v2-complete-dashboard`
- Task 2.1 and every Task 2.2 verifier must remain green.
- No schema change and no new persistence dependency.
- `TaskRepository` signatures remain unchanged.
- Same-status order changes use `reorderWithinStatus`.
- Cross-status moves use the existing atomic `transition`.
- User-facing layout remains RTL and Liquid Glass.
- List remains the default view and keeps current canceled-task hiding.
- Kanban shows all four canonical statuses, including canceled.
- Search applies to both views; list-only sort and filter behavior remains unchanged.
- Quick add, detailed add, full edit, priority, completion, and deletion remain available.
- Drag-and-drop must have equivalent accessible button actions.
- Narrow layouts use horizontal Kanban scrolling without overflow.
- Every implementation step follows RED → observed failure → GREEN → focused verification → full verification → commit/push.
- Verifiers use semantic checks and do not depend on formatter line wrapping.

---

## File structure

### New production files

- `lib/features/tasks/presentation/task_board/task_view_mode.dart`
  - Canonical list/Kanban selection enum.
- `lib/features/tasks/presentation/task_board/task_board_operations.dart`
  - Flutter-independent move request and repository orchestration.
- `lib/features/tasks/presentation/task_board/task_kanban_board.dart`
  - Four-column Liquid Glass Kanban UI, drag/drop, and accessible controls.

### Existing production file modified

- `lib/features/dashboard/presentation/widgets/tasks_panel.dart`
  - View toggle, Kanban integration, busy move state, and shared existing actions.

### New tests

- `test/features/tasks/presentation/task_board/task_board_operations_test.dart`
  - Exact same-status order, no-op behavior, transition delegation, clamping, invalid identity.
- `test/features/tasks/presentation/task_board/task_kanban_board_test.dart`
  - Four columns, canceled visibility, drag handles, accessible moves, narrow layout.
- `test/features/dashboard/tasks_panel_views_test.dart`
  - Default list compatibility, view switching, transition integration, quick-add preservation.

### Documentation and verification

- `docs/superpowers/plans/2026-08-04-task-2-3-board-list-kanban.md`
- `tool/verify_phase2_task2_3_green.py`
- Generated after fresh verification:
  - `docs/superpowers/checkpoints/2026-08-04-task-2-2-planning-fields-checkpoint.md`
  - `docs/superpowers/checkpoints/2026-08-04-task-2-3-board-list-kanban-checkpoint.md`
  - `tool/verify_phase2_task2_2_complete.py`
  - `tool/verify_phase2_task2_3_complete.py`

---

### Task 1: Pure board move orchestration

**Files:**
- Create: `lib/features/tasks/presentation/task_board/task_board_operations.dart`
- Test: `test/features/tasks/presentation/task_board/task_board_operations_test.dart`

**Interfaces:**
- Produces:
  ```dart
  final class TaskBoardMoveRequest {
    final String taskId;
    final TaskStatus targetStatus;
    final int targetPosition;
  }
  ```
- Produces:
  ```dart
  Future<void> TaskBoardOperations.move({
    required List<TaskItem> tasks,
    required TaskBoardMoveRequest request,
  })
  ```

- [ ] **Step 1: Write RED tests**
  - Move an item inside one status and expect one complete `orderedIds` inventory.
  - Keep a task at the same final position and expect no repository write.
  - Move across statuses and expect one `transition` with UTC `changedAtUtc`.
  - Clamp negative and oversized final positions.
  - Reject missing and duplicate task identities without writes.

- [ ] **Step 2: Run RED**
  ```bash
  flutter test \
    test/features/tasks/presentation/task_board/task_board_operations_test.dart
  ```
  Expected: compile failure because `task_board_operations.dart` is absent.

- [ ] **Step 3: Implement GREEN**
  - Resolve exactly one task identity.
  - Sort the source status by canonical `positionInStatus`, `createdAtUtc`, and ID.
  - For the same status, remove the task, clamp the final position, insert once, compare with the previous order, and call `reorderWithinStatus` only when changed.
  - For a different status, clamp against target inventory and call `transition` exactly once.
  - Convert the injected clock value to UTC.

- [ ] **Step 4: Verify**
  ```bash
  flutter test \
    test/features/tasks/presentation/task_board/task_board_operations_test.dart
  ```

---

### Task 2: Liquid Glass Kanban board

**Files:**
- Create: `lib/features/tasks/presentation/task_board/task_kanban_board.dart`
- Create: `lib/features/tasks/presentation/task_board/task_view_mode.dart`
- Test: `test/features/tasks/presentation/task_board/task_kanban_board_test.dart`

**Interfaces:**
- Consumes `TaskBoardMoveRequest`.
- Produces:
  ```dart
  TaskKanbanBoard({
    required List<TaskItem> tasks,
    required Set<String> busyTaskIds,
    required Future<void> Function(TaskBoardMoveRequest) onMove,
    required ValueChanged<TaskItem> onEdit,
    required ValueChanged<TaskItem> onPriority,
    required ValueChanged<TaskItem> onDelete,
  })
  ```

- [ ] **Step 1: Write RED widget tests**
  - Assert four canonical columns and all status labels.
  - Assert canceled tasks are visible.
  - Assert one drag handle per task.
  - Invoke accessible next-status and reorder controls and inspect the request.
  - Render at 390px and verify horizontal scrolling with no overflow.

- [ ] **Step 2: Run RED**
  ```bash
  flutter test \
    test/features/tasks/presentation/task_board/task_kanban_board_test.dart
  ```
  Expected: compile failure because the board widget is absent.

- [ ] **Step 3: Implement GREEN**
  - Render columns in `TaskStatus.values` order.
  - Use `OriginalGlass`, `OriginalFieldSurface`, `OriginalPressable`, and existing palette tokens.
  - Sort each column by canonical status-local position.
  - Put a `DragTarget` before the first card and after every card.
  - Put a `LongPressDraggable` on the dedicated drag handle.
  - Translate drop-slot coordinates into final post-removal positions.
  - Add edit, priority, delete, previous/next status, and up/down actions with semantic labels.
  - Disable actions and reduce opacity while the task is busy.
  - Use horizontal scrolling for narrow and desktop layouts.

- [ ] **Step 4: Verify**
  ```bash
  flutter test \
    test/features/tasks/presentation/task_board/task_kanban_board_test.dart
  ```

---

### Task 3: TasksPanel List/Kanban integration

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/tasks_panel.dart`
- Test: `test/features/dashboard/tasks_panel_views_test.dart`

**Interfaces:**
- List remains `TaskViewMode.list`.
- Kanban is `TaskViewMode.kanban`.
- Produces `_moveBoardTask(TaskBoardMoveRequest, List<TaskItem>)`.

- [ ] **Step 1: Write RED integration tests**
  - Confirm default list shows planned/in-progress/completed but hides canceled.
  - Switch to Kanban and confirm all four columns and canceled task.
  - Trigger a next-status action and verify repository transition.
  - Return to list and verify quick add and detailed add remain available.

- [ ] **Step 2: Run RED**
  ```bash
  flutter test test/features/dashboard/tasks_panel_views_test.dart
  ```
  Expected: no Kanban toggle or columns exist.

- [ ] **Step 3: Implement GREEN**
  - Add a compact `OriginalPills` view selector after the toolbar.
  - Keep all existing list code inside the list branch without changing its default.
  - Render `TaskKanbanBoard` in the Kanban branch.
  - Search task title and description for the board.
  - Track moving task IDs and prevent duplicate moves.
  - Delegate moves through `TaskBoardOperations`.
  - Reuse existing edit, priority, and delete flows.

- [ ] **Step 4: Verify**
  ```bash
  flutter test \
    test/features/dashboard/tasks_panel_views_test.dart \
    test/features/dashboard/tasks_panel_test.dart \
    test/features/dashboard/tasks_panel_details_test.dart \
    test/features/dashboard/tasks_panel_persistence_test.dart
  ```

---

### Task 4: Semantic verification and checkpoints

**Files:**
- Create: `tool/verify_phase2_task2_3_green.py`
- Generate after code commit:
  - Task 2.2 and Task 2.3 checkpoint documents.
  - Task 2.2 and Task 2.3 complete verifiers.
- Modify after code commit:
  - `docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md`

- [ ] **Step 1: Run all stable Gate verifiers**
  ```bash
  python3 tool/verify_phase2_task2_1_complete.py
  python3 tool/verify_phase2_task2_2_1_green.py
  python3 tool/verify_phase2_task2_2_2_green.py
  python3 tool/verify_phase2_task2_2_3_green.py
  python3 tool/verify_phase2_task2_2_4_green.py
  python3 tool/verify_phase2_task2_2_ui_green.py
  python3 tool/verify_phase2_task2_3_green.py
  ```

- [ ] **Step 2: Run focused suites**
  ```bash
  flutter test [Task 2.2 focused files]
  flutter test [Task 2.3 focused files]
  ```

- [ ] **Step 3: Run fresh full verification**
  ```bash
  flutter analyze
  flutter test
  flutter build linux --debug
  git diff --check
  ```

- [ ] **Step 4: Commit and push production**
  ```bash
  git commit -m "feat: add task list and kanban board"
  git push
  ```

- [ ] **Step 5: Generate exact checkpoints**
  - Parse focused/full test logs.
  - Resolve exact Task 2.2 Gate commits by subject.
  - Record the Task 2.3 implementation commit and its Task 2.2 parent.
  - Mark Tasks 2.2 and 2.3 implemented in the Phase 2 design map.
  - Generate stable complete verifiers.

- [ ] **Step 6: Commit and push evidence**
  ```bash
  git commit -m "docs: checkpoint task planning and board views"
  git push
  ```
