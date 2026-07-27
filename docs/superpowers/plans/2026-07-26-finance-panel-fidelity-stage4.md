# Finance Panel Fidelity Stage 4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Match the original finance panel visually while making the preview form, summaries, charts, debts, installments, and recent transactions interactive in memory.

**Architecture:** Keep `FinancePanel` as the orchestration widget, move calculations and formatting into `finance_preview_models.dart`, and isolate chart painting in `finance_charts.dart`. No persistence is introduced in this visual fidelity stage.

**Tech Stack:** Flutter, Dart 3.12, CustomPainter, Vazirmatn, shamsi_date.

## Global Constraints

- Preserve the original 780px content width and Liquid Glass components.
- Preserve RTL Persian layout and Jalali labels.
- Do not add dependencies or generated files.
- Keep data in memory until the Drift persistence phase.

---

### Task 1: Finance calculations and formatting

**Files:**
- Create: `app/lib/features/dashboard/presentation/widgets/finance_preview_models.dart`
- Test: `app/test/features/dashboard/finance_panel_test.dart`

- [x] Add transaction, debt, installment, summary, month, category, and day preview models.
- [x] Add Persian number parsing/formatting and Jalali aggregation helpers.

### Task 2: Original finance charts

**Files:**
- Create: `app/lib/features/dashboard/presentation/widgets/finance_charts.dart`

- [x] Paint the six-month income/expense trend with grid labels and area fills.
- [x] Paint the expense-category donut and legend.
- [x] Paint the seven-day expense bars.

### Task 3: Interactive finance panel

**Files:**
- Modify: `app/lib/features/dashboard/presentation/widgets/finance_panel.dart`
- Test: `app/test/features/dashboard/finance_panel_test.dart`

- [x] Make summary cards derive values from in-memory entries.
- [x] Match the original segmented form and dynamic type-specific fields.
- [x] Render debts, installments, payments, transactions, filters, and delete actions.
- [x] Preserve original glass radii, padding, typography, and responsive two-column chart layout.

### Task 4: Verification contract

**Files:**
- Create: `app/tool/verify_finance_fidelity_stage4.py`

- [ ] Validate required files, keys, original labels, chart painters, and no missing package imports.
- [ ] Run `flutter analyze`, focused finance tests, all tests, and Linux launch on the user's Flutter environment.
