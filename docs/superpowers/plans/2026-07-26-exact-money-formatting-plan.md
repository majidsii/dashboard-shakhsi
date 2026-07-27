# Exact Money Formatting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add exact eight-decimal money entry, calculation, and display across the finance panel.

**Architecture:** Extend the existing fixed-point `Money` value object with exact parsing, formatting, comparison, clamping, and integer multiplication. Add a dedicated Flutter `TextInputFormatter` for live Persian money formatting, then migrate finance preview models and chart projections from integer major units to `Money`.

**Tech Stack:** Dart 3.12, Flutter 3.44, widget tests, fixed-point integer arithmetic.

## Global Constraints

- Scale is exactly 8 fractional digits.
- Monetary calculations never use `double`.
- Persian, Arabic, and Latin input digits are supported.
- All display output uses Persian digits and grouped integer parts.
- Count fields remain integer-only.

---

### Task 1: Exact money value object

**Files:**
- Modify: `app/lib/core/money/money.dart`
- Test: `app/test/core/money/money_test.dart`

- [ ] Add failing tests for parsing mixed digits, eight decimals, formatting, arithmetic, clamping, and over-precision rejection.
- [ ] Run `flutter test test/core/money/money_test.dart` and confirm the new tests fail.
- [ ] Implement exact fixed-point parsing and formatting without `double`.
- [ ] Re-run the money tests and confirm they pass.

### Task 2: Live amount input formatter

**Files:**
- Create: `app/lib/core/money/money_input_formatter.dart`
- Test: `app/test/core/money/money_input_formatter_test.dart`
- Modify: `app/lib/app/widgets/original_controls.dart`

- [ ] Add failing tests for live grouping, Persian/Arabic input normalization, trailing decimal preservation, eight-digit fractional limit, and caret stability.
- [ ] Implement `MoneyInputFormatter`.
- [ ] Expose `inputFormatters` through `OriginalTextField`.
- [ ] Run formatter tests.

### Task 3: Finance model migration

**Files:**
- Modify: `app/lib/features/dashboard/presentation/widgets/finance_preview_models.dart`
- Modify: `app/lib/features/dashboard/presentation/widgets/finance_charts.dart`
- Modify: `app/lib/features/dashboard/presentation/widgets/finance_panel.dart`
- Test: `app/test/features/dashboard/finance_panel_test.dart`

- [ ] Add failing widget tests for grouped decimal entry and exact decimal summaries.
- [ ] Replace finance amount integers with scale-8 `Money` values.
- [ ] Keep installment counts as integers.
- [ ] Use exact values for totals, debt balances, and labels.
- [ ] Convert exact values to `double` only inside chart coordinate calculations.
- [ ] Run finance and full test suites.

### Task 4: Verification and handoff

**Files:**
- Create: `app/tool/verify_money_format_stage5.py`
- Create: `APPLY.md`

- [ ] Add a structural verifier for scale, formatter use, and Money-based finance models.
- [ ] Run formatting, analyzer, targeted tests, and full tests.
- [ ] Package only source, tests, docs, and verification tools.
