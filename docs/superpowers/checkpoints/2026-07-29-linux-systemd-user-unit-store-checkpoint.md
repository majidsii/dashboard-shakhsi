# Linux systemd User Unit Store — Verification Checkpoint

Date: 2026-07-29  
Phase: 1  
Task: 10.2  
Branch: `feat/v2-complete-dashboard`  
Implementation HEAD before checkpoint commit: `6c4129ef14e7`

## Verified scope

- injected environment source
- XDG-first and HOME-fallback path resolution
- link-aware filesystem contract
- Dart IO adapter using POSIX FFI for chmod
- exact `0644` unit permissions
- safe two-file preparation and replacement
- complete in-process rollback for full and partial previous pairs
- original-cause preservation with rollback failure aggregation
- idempotent and symlink-safe removal
- no `systemctl` invocation
- no scheduler/platform integration in this Task
- no real user systemd directory touched by focused tests

## Fresh verification evidence

| Gate | Result |
|---|---:|
| Focused Task 10.2 tests | 74 passed |
| Flutter analyze | No issues found |
| Full Flutter suite | 352 passed |
| Linux debug build | Successful |
| `git diff --check` | Run separately before commit |

## Permission implementation

The Dart IO adapter applies permissions through
`package:posix` and `chmodWithMode(path, mode)`. It does not invoke a shell,
`Process.run`, or `systemctl`.

The final service and timer mode is decimal `420`, equivalent to octal `0644`.

## Transaction guarantees

The install transaction:

1. validates final and transaction-owned paths without following symlinks
2. snapshots previous bytes and POSIX modes
3. writes and chmods both temporary units
4. backs up existing service and timer files
5. installs both prepared files through same-directory rename
6. removes backups after successful commit
7. restores the exact previous complete or partial pair after an observed failure
8. keeps the original error primary and appends rollback failures

## Known crash boundary

Task 10.2 guarantees rollback for failures observed by the running process.

A power loss, kernel crash, or forced process termination between filesystem
operations is not recovered through a persistent journal. Persistent
crash-recovery journaling remains deferred to a later hardening task.

## Cross-platform boundary

This Task adds Linux storage primitives only. It does not wire the store into
the scheduler and does not change Android, iOS, macOS, or Windows behavior.

## Next task

Task 10.3 — `systemctl --user` command driver.
