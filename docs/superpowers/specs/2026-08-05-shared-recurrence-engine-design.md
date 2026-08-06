# Shared Recurrence Engine — Design

Date: 2026-08-05
Status: Approved for Task 2.5 implementation
Phase: 2 — Planning and Execution

## Goal

Build one deterministic recurrence core that Tasks, Finance, Habits,
Challenges, and Installments can reuse without importing feature-specific
state or persistence.

## Scope

Task 2.5 creates only `lib/core/recurrence/` domain and expansion
infrastructure. It does not add recurrence columns or tables, Task UI,
Task occurrence completion, Calendar UI, missed-occurrence policy, working-day
rules, or feature-specific repositories. Those integrations begin in Task 2.6.

## Rule model

A rule selects one frequency (`daily`, `weekly`, `monthly`, or `yearly`) and a
positive interval. Weekly rules support multiple weekdays. Monthly rules
support multiple fixed days and the last day of month. Yearly rules support
multiple month/day pairs.

Each rule also carries:

- a Gregorian or Jalali calendar;
- a fixed or floating IANA timezone;
- `never`, inclusive `until`, or `afterCount` termination;
- `skipPeriod` or `clampToLastDay` invalid-date policy.

The default invalid-date policy is `skipPeriod`. Floating timezone rules keep
their civil clock time and resolve against the device timezone supplied to
each expansion call. Fixed rules retain their configured IANA zone.

## Time model

Civil dates are represented by `RecurrenceLocalDateTime`. Their fields are
interpreted in the rule calendar and are never treated as UTC instants.

Each output occurrence includes:

- original scheduled civil date/time;
- effective civil date/time after DST or move exception;
- final UTC instant;
- resolved timezone ID;
- rule calendar;
- stable sequence number;
- scheduled, moved, skipped, or canceled status.

## Calendar adapters

Gregorian and Jalali conversions live behind `RecurrenceCalendarAdapter`.
Adapters validate dates, calculate month length and weekday, shift months,
add civil days, and convert between rule-calendar civil values and Gregorian
civil values.

## Timezone resolver

`TimezoneRecurrenceResolver` uses the existing `timezone` IANA database.

- Ordinary civil times map to their single instant.
- A DST gap advances minute-by-minute to the first valid civil minute.
- A DST overlap chooses the earlier matching UTC instant.
- Unknown zones fail explicitly.
- Timezone database initialization remains an application/startup concern.

## Expansion contract

`RecurrenceEngine.expand` accepts a UTC half-open range `[start, end)`, the
current floating timezone ID, optional exceptions, and a safety limit.

Expansion is deterministic for identical inputs. It generates candidates from
the rule anchor, applies inclusive rule termination, applies one exception per
original occurrence, filters by effective UTC instant, sorts chronologically,
and returns an immutable list.

Open-ended expansion is always bounded by the requested UTC range and
`maximumOccurrences`. Empty monthly or yearly periods remain visible to the
engine, so impossible active dates terminate at the range boundary instead of
looping forever.

## Exceptions

Core exceptions are date operations only:

- skip;
- cancel;
- move.

They match the stable original civil date/time key. Feature-specific meanings
such as task completion remain outside the core.

## Persistence boundary

Task 2.5 does not change Drift schema version 5 and does not persist recurrence
rules. Persistence ownership and Task linkage are Task 2.6 concerns.

## Verification

The focused matrix covers:

- all four frequencies and intervals;
- multiple weekly/monthly selectors;
- invalid dates with skip and clamp;
- Gregorian and Jalali boundaries;
- leap dates;
- fixed and floating zones;
- DST gaps and overlaps;
- all termination modes;
- skip, cancel, and move exceptions;
- half-open ranges, ordering, duplicate suppression, safety limits;
- repeated deterministic expansion;
- unchanged Task and schema contracts.
