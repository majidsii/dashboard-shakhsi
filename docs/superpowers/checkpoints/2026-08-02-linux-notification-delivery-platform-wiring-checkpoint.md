# Linux Notification Delivery and Platform Wiring — Task 10.6 Checkpoint

Date finalized: 2026-08-02  
Phase: 1  
Task: 10.6  
Cross-task scope: Tasks 10.4–10.6  
Status: **Implemented and freshly verified**

## Completion boundary

- Task 10.4 — Persistent Linux Schedule Registry: **Complete**
- Task 10.5 — Linux systemd Notification Scheduler: **Complete**
- Task 10.6 — Delivery Entrypoint and Platform Wiring: **Complete**
- Tasks 10.4–10.6 as one Linux notification pipeline: **Complete**
- Unrelated Phase 1 work: **Not assessed and not marked complete**

## Scope completed

Task 10.6 adds exact persisted schedule lookup, a strict hidden invocation,
validated absolute executable resolution, shell-free delivery commands,
persisted private notification delivery, hidden application dispatch before UI,
lazy platform scheduler selection, non-blocking startup reconciliation, and an
in-memory integrated Linux delivery checkpoint.

The pipeline retains Drift desired state after hidden delivery. Hidden systemd
arguments contain only the executable path, hidden-delivery flag, and schedule
identifier. Title, body, owner, privacy mode, and payload are loaded from Drift
at execution time.

## Gate commit evidence

| Gate | Commit | Subject |
|---|---|---|
| 10.6.1 | `95eed8d4db2a058c015eccca09010115c48dab7c` | `feat: add notification schedule lookup` |
| 10.6.2 | `4c7c45563e17678fac3a6318e698caf1897a871b` | `feat: parse Linux notification delivery command` |
| 10.6.3 | `9fccf00e69e5fff644642be17d128dd5be0e8f58` | `feat: resolve Linux notification delivery executable` |
| 10.6.4 | `2e4ff6d3f0ab42f4dd2fff85d8d5517808bc92bf` | `feat: deliver persisted Linux notifications` |
| 10.6.5 | `d7d50a42eb75cc24d0b69f7e01da51dba1baec44` | `feat: run hidden Linux notification mode` |
| 10.6.6 | `9c588d8e9093f955cd4d2084d8c184b20f1e2381` | `feat: select Linux systemd notification scheduler` |
| 10.6.7 | `8ae31c79354753bf87fc134a15b6cc92d63f8254` | `feat: reconcile Linux notifications at startup` |
| 10.6.8 | `b667f6469f22a75abdd0c00da1a037258d18a4dc` | `test: verify Linux notification delivery composition` |

## Fresh verification evidence

- Tasks 10.4–10.6 focused tests: **250 passed**
- Full project tests: **1005 passed**
- `flutter analyze`: **No issues found**
- `flutter build linux --debug`: **Succeeded**
- `git diff --check`: **Clean**
- Real user systemd process: **Not used by focused tests**
- Real HOME/XDG user-unit directory: **Not used by focused tests**
- Real desktop notification plugin/display: **Not used by focused tests**
- Database integration: **In-memory Drift only**

## Hidden delivery guarantees

- Hidden arguments are parsed exactly and reject trailing or malformed input.
- Hidden mode is selected before dashboard, router, and normal startup work.
- Exact `scheduleId` lookup reads the complete persisted request.
- Missing requests exit successfully without displaying a notification.
- Private content uses the privacy policy while retaining exact navigation
  payload and stable display identity.
- Delivery resources close on success and typed failure.
- Desired Drift state is not deleted after hidden delivery.

## Platform and startup guarantees

- Linux selects `LinuxSystemdNotificationScheduler`.
- Android, macOS, and Windows retain the native platform scheduler.
- Unsupported targets select the no-op scheduler.
- Non-Linux branches do not construct Linux filesystem, registry, unit-store,
  process-runner, executable, or systemd dependencies.
- Normal startup reconciliation is provider-scope single-flight.
- The dashboard renders immediately while reconciliation is pending.
- Startup failure is reported with its stack trace without replacing the UI.
- A failed reconciliation can retry without repeating plugin initialization.

## Integrated pipeline evidence

The focused integration test covers:

1. persisted Drift schedule creation;
2. deterministic minimal systemd service command rendering;
3. controlled fake systemd enable/start/health mutation;
4. hidden entrypoint dispatch without normal UI startup;
5. exact persisted lookup;
6. privacy-safe immediate display;
7. payload and stable-ID preservation;
8. retained desired Drift state;
9. successful missing-request no-op;
10. lazy unsupported-platform selection;
11. one startup reconciliation per provider scope.

## Remaining durability boundary

No atomic transaction spans Drift, two systemd unit files, the systemd user
manager, and the registry file. The implementation provides in-process
rollback and deterministic restart reconciliation, but it does **not** claim
power-loss atomicity or explicit fsync durability across all resources.

This boundary remains documented by design and is not expanded by Task 10.6.

## Prior task checkpoints

- [Task 10.4 registry checkpoint](2026-07-30-linux-systemd-schedule-registry-checkpoint.md)
- [Task 10.5 scheduler checkpoint](2026-07-30-linux-systemd-notification-scheduler-checkpoint.md)
