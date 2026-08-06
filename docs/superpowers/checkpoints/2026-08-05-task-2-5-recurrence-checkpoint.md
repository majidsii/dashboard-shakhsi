# Task 2.5 — Shared Recurrence Engine Checkpoint

Date: 2026-08-05
Status: **Implemented and freshly verified**
Code commit: `3affb2579bed4afffaf37cb7122b565d1b236897`

## Delivered boundary

Task 2.5 adds shared recurrence infrastructure under
`lib/core/recurrence/` without changing Drift schema version 5, `TaskItem`,
or `TaskRepository`.

Implemented capabilities:

- immutable daily, weekly, monthly, and yearly rules with positive intervals;
- Gregorian and Jalali calendar adapters;
- multiple weekly weekdays, monthly selectors, and annual dates;
- fixed and floating IANA timezone modes;
- first-valid-minute handling for DST gaps;
- first-instant handling for DST overlaps;
- `never`, inclusive `until`, and `afterCount` termination;
- `skipPeriod` and `clampToLastDay` invalid-date policies;
- skip, cancel, and move exceptions keyed by original civil time;
- UTC half-open range expansion, stable ordering, immutable output, and
  `maximumOccurrences` safety bounds;
- deterministic repeated expansion suitable for restart recovery.

Task-specific persistence, recurring Task rows, occurrence completion, and
Calendar UI remain pending for Task 2.6.

## Fresh verification evidence

- Task 2.5 focused tests: **24 passed**
- Full project tests: **1126 passed**
- `flutter analyze`: **No issues found**
- `flutter build linux --debug`: **Succeeded**
- `git diff --check`: **Clean**
- Task 2.4 checkpoint verifier: **Passed**
- Task 2.5 semantic verifier: **Passed**

## Compatibility evidence

- Drift schema remains version 5.
- No recurrence table was added.
- `TaskItem` remains free of recurrence fields.
- `TaskRepository` remains recurrence-free.
- Existing Task 2.2, Task 2.3, and Task 2.4 checkpoints remain valid.
