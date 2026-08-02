# Linux systemd Notification Scheduler — Task 10.5 Checkpoint

Date finalized: 2026-08-02  
Phase: 1  
Task: 10.5  
Status: **Implemented and freshly verified**

## Scope

Task 10.5 implements `LinuxSystemdNotificationScheduler` and retained
systemd unit transactions. It composes the fixed clock, immediate notification
gateway, delivery-command factory, deterministic renderer, transactional unit
store, hardened user-systemd driver, persistent registry, request fingerprint,
writer-preferring global lock, and per-schedule FIFO mutex.

Task 10.6 remains pending. This checkpoint does not add the hidden delivery
entrypoint or application provider wiring.

## Gate commit evidence

| Gate | Commit | Subject |
|---|---|---|
| 10.5.1 | `f3a3eff61381e5207907fb9772070a3d1343fbaa` | `feat: define retained systemd unit transactions` |
| 10.5.2 | `198bc8773f9a52bd920705ace9eb9e6b719cb8a0` | `feat: retain Linux unit install rollback state` |
| 10.5.3 | `b64c6fbdf5ed3f04a7bd77cbc19c3fc17d056cba` | `feat: retain Linux unit removal snapshots` |
| 10.5.4 | `0e8a93340dc934828f5e5921cfa18c424acbe78f` | `feat: define Linux scheduler contracts` |
| 10.5.5 | `85fe5fad836fa285cd548854fcca4bf5fa10535c` | `feat: schedule Linux systemd notifications` |
| 10.5.6 | `dc593ec5e2db315c2f5a9673a45bc2be3de02ca7` | `feat: rollback failed Linux schedules` |
| 10.5.7 | `fa143633e6f401cd4b99c5595b16c5ef4118c9f1` | `feat: cancel Linux systemd notifications` |
| 10.5.8 | `35f75809fa3ac1dfe90308b69caca47ea7bdfb12` | `feat: serialize Linux scheduler owner operations` |
| 10.5.9 | `ed7a2186429f10e2bfaaeabbf8813042752ffe53` | `feat: recover Linux notification inventory` |
| 10.5.10 | `45ae3471384d8571c25f92e3cf6f838797c97c30` | `feat: reconcile Linux notification schedules` |

## Fresh verification evidence

- Task 10.5 focused tests: **167 passed**
- Full project tests: **911 passed**
- `flutter analyze`: **No issues found**
- `flutter build linux --debug`: **Succeeded**
- `git diff --check`: **Clean**
- Real user systemd access: **Not used by checkpoint tests**

## Retained transaction guarantees

- Install and remove operations retain exact previous unit-pair state.
- Applied but unfinalized transactions can roll back.
- Finalized transactions cannot be silently rolled back.
- Primary failures remain primary when rollback also fails.
- Wrapper methods preserve the same retained transaction semantics.

## Scheduling and locking guarantees

- Due requests clean stale platform state before immediate delivery.
- Future requests render, install, reload, enable, verify, register, and finalize.
- Healthy matching requests are idempotent.
- Changed or unhealthy requests are replaced or repaired.
- Same-schedule operations are FIFO serialized.
- Different schedule IDs can overlap under the global read lock.
- Writer-preferring owner cancellation and reconciliation exclude new readers.

## Cancellation and rollback guarantees

- Cancellation handles missing, registry-only, unit-only, and complete state.
- Owner cancellation uses exact owner matching and deterministic schedule order.
- Batch failure stops at the first failed schedule and reports immutable
  completed schedule IDs.
- Failed schedule and cancel operations restore retained files, registry
  evidence, daemon visibility, and previous enabled state when possible.

## Reconciliation guarantees

- Desired requests use last-value-wins normalization and deterministic sorting.
- Due desired items are cleaned without startup immediate delivery.
- Stale registry entries, orphan complete pairs, and partial pairs are removed.
- Corrupt registry state is quarantined and rebuilt from desired state.
- Healthy matching schedules are preserved.
- Missing, changed, and unhealthy schedules are repaired.
- Successful repairs are preserved across later batch failure.
- Partial reconciliation reports the failing schedule, immutable completed IDs,
  confirmed status when available, original cause, and rollback failures.

## Remaining work

Task 10.6 — Delivery Entrypoint and Platform Wiring — is still **pending**.
