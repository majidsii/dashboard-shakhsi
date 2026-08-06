# Shared Recurrence Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a deterministic Gregorian/Jalali recurrence domain and
timezone-aware occurrence engine without changing schema version 5 or Task
contracts.

**Architecture:** Immutable rule and occurrence models live in
`lib/core/recurrence/`. Calendar math is isolated behind Gregorian and Jalali
adapters. IANA timezone resolution is isolated behind a resolver, and the
engine combines candidate generation, termination, exceptions, DST policy,
range filtering, and stable ordering.

**Tech Stack:** Dart 3.12, Flutter test, `timezone` 0.11.1,
`shamsi_date` 1.1.1.

## Global Constraints

- Keep Drift schema version exactly 5.
- Do not add recurrence fields to `TaskItem` or methods to `TaskRepository`.
- Do not add Task UI, Calendar UI, or recurrence persistence.
- Every expansion range is UTC and half-open: `[start, end)`.
- `until` is inclusive.
- DST gaps advance to the first valid local minute.
- DST overlaps choose the first instant.
- Invalid monthly/yearly dates default to `skipPeriod`.
- Open series are guarded by `maximumOccurrences`.

---

### Task 1: Immutable recurrence domain

**Files:**
- Create: `lib/core/recurrence/recurrence_frequency.dart`
- Create: `lib/core/recurrence/recurrence_calendar.dart`
- Create: `lib/core/recurrence/recurrence_local_date_time.dart`
- Create: `lib/core/recurrence/recurrence_time_zone.dart`
- Create: `lib/core/recurrence/recurrence_end.dart`
- Create: `lib/core/recurrence/recurrence_month_selector.dart`
- Create: `lib/core/recurrence/recurrence_annual_date.dart`
- Create: `lib/core/recurrence/recurrence_exception.dart`
- Create: `lib/core/recurrence/recurrence_occurrence.dart`
- Create: `lib/core/recurrence/recurrence_rule.dart`
- Test: `test/core/recurrence/recurrence_domain_test.dart`

**Interfaces:**
- Produces: named `RecurrenceRule.daily`, `weekly`, `monthly`, and `yearly`
  factories; immutable selectors; fixed/floating timezone; three termination
  modes; skip/cancel/move exceptions.

- [ ] **Step 1: Install and run the domain tests in RED**

```bash
flutter test test/core/recurrence/recurrence_domain_test.dart
```

Expected: compilation fails because recurrence domain files do not exist.

- [ ] **Step 2: Implement validated immutable values**

```dart
final rule = RecurrenceRule.monthly(
  anchorLocalDateTime: RecurrenceLocalDateTime(
    year: 1405,
    month: 5,
    day: 14,
    hour: 9,
  ),
  monthlySelectors: <RecurrenceMonthSelector>[
    RecurrenceMonthSelector.dayOfMonth(31),
  ],
  invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
);
```

- [ ] **Step 3: Run the domain tests in GREEN**

```bash
flutter test test/core/recurrence/recurrence_domain_test.dart
```

Expected: all domain tests pass.

### Task 2: Gregorian and Jalali adapters

**Files:**
- Create: `lib/core/recurrence/recurrence_calendar_adapter.dart`
- Create: `lib/core/recurrence/gregorian_recurrence_calendar.dart`
- Create: `lib/core/recurrence/jalali_recurrence_calendar.dart`
- Test: `test/core/recurrence/recurrence_calendar_adapter_test.dart`

**Interfaces:**
- Consumes: `RecurrenceLocalDateTime`.
- Produces: date validation, month length, weekday, day addition, month shift,
  and Gregorian civil conversion.

- [ ] **Step 1: Run adapter tests before implementation**

```bash
flutter test test/core/recurrence/recurrence_calendar_adapter_test.dart
```

Expected: compilation fails because adapters do not exist.

- [ ] **Step 2: Implement both calendar adapters**

```dart
abstract interface class RecurrenceCalendarAdapter {
  bool isValidDate({
    required int year,
    required int month,
    required int day,
  });

  RecurrenceLocalDateTime addDays(
    RecurrenceLocalDateTime value,
    int days,
  );
}
```

- [ ] **Step 3: Verify Jalali month and year boundaries**

```bash
flutter test test/core/recurrence/recurrence_calendar_adapter_test.dart
```

Expected: Gregorian leap and Jalali boundary tests pass.

### Task 3: IANA timezone and DST resolver

**Files:**
- Create: `lib/core/recurrence/recurrence_time_zone_resolver.dart`
- Test: `test/core/recurrence/recurrence_time_zone_resolver_test.dart`

**Interfaces:**
- Consumes: Gregorian civil date/time plus IANA zone ID.
- Produces: effective Gregorian civil value and UTC instant.

- [ ] **Step 1: Run timezone tests in RED**

```bash
flutter test test/core/recurrence/recurrence_time_zone_resolver_test.dart
```

Expected: resolver import is missing.

- [ ] **Step 2: Implement exact local-to-instant matching**

```dart
final resolution = resolver.resolve(
  gregorianLocalDateTime: local,
  timeZoneId: 'America/New_York',
);
```

The implementation enumerates plausible offsets. If no exact mapping exists,
it advances by one civil minute until the first valid mapping. When two exact
mappings exist, it chooses the earlier UTC instant.

- [ ] **Step 3: Verify ordinary, gap, overlap, and unknown-zone cases**

```bash
flutter test test/core/recurrence/recurrence_time_zone_resolver_test.dart
```

Expected: all resolver tests pass.

### Task 4: Deterministic occurrence engine

**Files:**
- Create: `lib/core/recurrence/recurrence_engine.dart`
- Test: `test/core/recurrence/recurrence_engine_test.dart`

**Interfaces:**
- Consumes: `RecurrenceRule`, UTC range, floating timezone ID, exceptions,
  safety limit.
- Produces: immutable chronological `List<RecurrenceOccurrence>`.

- [ ] **Step 1: Run the engine matrix in RED**

```bash
flutter test test/core/recurrence/recurrence_engine_test.dart
```

Expected: `RecurrenceEngine` is undefined.

- [ ] **Step 2: Implement candidate generation and termination**

```dart
final occurrences = engine.expand(
  rule: rule,
  rangeStartUtc: rangeStartUtc,
  rangeEndUtc: rangeEndUtc,
  floatingTimeZoneId: currentDeviceTimeZoneId,
  exceptions: exceptions,
);
```

Daily adds civil days, weekly uses ISO Monday-based active weeks, monthly
generates all selectors in each active month, and yearly generates all annual
dates in each active year.

- [ ] **Step 3: Apply exceptions and range filtering**

Exception identity uses the original civil storage key. Move changes effective
civil time but preserves sequence and original identity. Filtering uses the
effective UTC instant.

- [ ] **Step 4: Run the full recurrence matrix**

```bash
flutter test test/core/recurrence
```

Expected: all recurrence tests pass.

### Task 5: Compatibility and project verification

**Files:**
- Create: `tool/verify_phase2_task2_5_green.py`
- Verify: `lib/core/database/app_database.dart`
- Verify: `lib/features/tasks/domain/task_item.dart`
- Verify: `lib/features/tasks/domain/task_repository.dart`

- [ ] **Step 1: Run semantic verifiers**

```bash
python3 tool/verify_phase2_task2_4_complete.py
python3 tool/verify_phase2_task2_5_green.py
```

Expected: schema 5 and prior Task contracts remain unchanged.

- [ ] **Step 2: Run fresh project gates**

```bash
flutter analyze
flutter test
flutter build linux --debug
git diff --check
```

Expected: clean analyzer, all tests pass, Linux debug build succeeds, and no
whitespace errors remain.

- [ ] **Step 3: Commit the engine**

```bash
git add docs/superpowers/specs/2026-08-05-shared-recurrence-engine-design.md   docs/superpowers/plans/2026-08-05-task-2-5-shared-recurrence-engine.md   lib/core/recurrence test/core/recurrence   tool/verify_phase2_task2_5_green.py
git commit -m "feat: add shared recurrence engine"
git push
```

### Task 6: Evidence checkpoint

**Files:**
- Create:
  `docs/superpowers/checkpoints/2026-08-05-task-2-5-recurrence-checkpoint.md`
- Create: `tool/verify_phase2_task2_5_complete.py`
- Modify: `docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md`
- Modify: `tool/verify_phase2_task2_1_complete.py`

- [ ] **Step 1: Generate the checkpoint from fresh logs**

```bash
python3 finalize_phase2_task2_5.py
```

- [ ] **Step 2: Verify all completed Task checkpoints**

```bash
python3 tool/verify_phase2_task2_2_complete.py
python3 tool/verify_phase2_task2_3_complete.py
python3 tool/verify_phase2_task2_4_complete.py
python3 tool/verify_phase2_task2_5_complete.py
```

- [ ] **Step 3: Commit Task 2.5 evidence**

```bash
git add docs/superpowers/specs/2026-08-02-phase-2-tasks-v2-design.md   docs/superpowers/checkpoints/2026-08-05-task-2-5-recurrence-checkpoint.md   tool/verify_phase2_task2_1_complete.py   tool/verify_phase2_task2_5_complete.py
git commit -m "docs: checkpoint shared recurrence engine"
git push
```
