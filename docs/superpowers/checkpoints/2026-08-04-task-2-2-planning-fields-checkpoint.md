# Task Planning Fields — Task 2.2 Checkpoint

Date finalized: 2026-08-04
Phase: 2
Task: 2.2
Status: **Implemented and freshly verified**

## Completion boundary

- Task 2.1: complete and still green.
- Task 2.2: complete.
- Task 2.3 implementation is recorded separately.
- Tasks 2.4–2.11 are not marked complete.

## Scope completed

Tasks now persist normalized plain-text descriptions, optional UTC start and
due timestamps, and optional positive estimated duration. The user interface
uses device-local wall-clock time, Jalali dates, one shared adaptive Liquid
Glass create/edit dialog, quick add plus detailed add, full edit, explicit
clearing, and concise row metadata.

## Gate commit evidence

| Gate | Commit | Subject |
|---|---|---|
| 2.2.1 | `37c529b7119d1f5aa9a1243490229a2fa72c8060` | `feat: add canonical task planning fields` |
| 2.2.2 | `78bed453cae60494dd15c42b0af29a91787ed08b` | `feat: migrate tasks to planning schema` |
| 2.2.3 | `566792f8064cbe20a5cf0e258e98f82ba2de7665` | `feat: persist task planning details` |
| 2.2.4 | `d382f8cca190d64cb789112fe45ccbcac95d7143` | `feat: add task details draft validation` |
| 2.2.5–2.2.7 | `6d7a859a69e4a72ff5ee4aef2da2a12567785ca0` | `feat: complete task planning interface` |

## Fresh verification evidence

- Task 2.2 focused tests: **35 passed**
- Full project tests after Task 2.3 integration: **1084 passed**
- `flutter analyze`: **No issues found**
- `flutter build linux --debug`: **Succeeded**
- `git diff --check`: **Clean**
- Every Task 2.1 and Task 2.2 semantic verifier: **Passed**

## Persistence and restart evidence

- Schema version 3 upgrades deterministically to schema version 4.
- Existing rows retain identity, status, display number, and status-local order.
- New planning columns are nullable and default to `null` for migrated rows.
- Description, start, due, and duration survive database restart.
- Explicit clearing persists across restart.
- Status transition and reorder preserve all planning fields.

## Domain and time invariants

- Description is trimmed and blank text becomes `null`.
- Persisted start and due values are UTC.
- Due cannot be before start when both exist.
- Estimated duration is either `null` or positive total minutes.
- Create/edit draft conversion is deterministic and preserves immutable task
  identity, workflow status, order, and terminal timestamps.

## UI evidence

- Quick add remains available.
- Add with details and edit use one shared form.
- Jalali date and local time controls avoid the generic Gregorian picker.
- Narrow and desktop layouts remain RTL and Liquid Glass.
- Description and planning metadata render concisely in task rows.

## Explicit remaining scope

Reminder rules, recurrence, calendar, timers, templates, Undo, Trash, audit
history, and dashboard layout configuration remain outside Task 2.2.
