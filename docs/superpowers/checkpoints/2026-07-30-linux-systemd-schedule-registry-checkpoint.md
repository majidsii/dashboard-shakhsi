# Task 10.4 Checkpoint — Persistent Linux Schedule Registry

Date: 2026-07-30  
Phase: 1  
Status: Implemented and verified  
Scope: Task 10.4 only; Tasks 10.5 and 10.6 remain pending.

## Outcome

Task 10.4 implements a bounded, privacy-preserving Linux platform inventory
for app-owned notification schedules. Drift remains the desired-state source
of truth. The registry records platform inventory only and does not call
`systemctl`, render units, or implement the scheduler.

## Gate commits

| Gate | Commit | Scope |
|---|---|---|
| 10.4.1 | `1e0273dd1a5d4278c690f82037cc0d049d9b7c6f` | Immutable registry and discovery models |
| 10.4.2 | `b6e27e5c6356a560e51dfb1e5e1d0905293cd11b` | Duplicate-aware JSON and canonical codec |
| 10.4.3 | `49eec3fd26c87940d5c20e2459467e04c50f9d0a` | Canonical SHA-256 request fingerprint |
| 10.4.4 | `a4408248546e33ac27508fcb2f201fab842d6efe` | Filesystem inventory extensions |
| 10.4.5 | `094200285f980b1a567205af4d98d90be9a685d9` | Safe registry load |
| 10.4.6 | `be65eca45aa9dadc9af2320dc3c70a1d8f43c6f2` | Atomic replacement and rollback |
| 10.4.7 | `5fc32515f35e4d6b26a035add2e91d768e596145` | Corrupt quarantine and unit discovery |
| 10.4.8 | This checkpoint commit | Final lifecycle and adapter checkpoint |

The Gate 10.4.8 hash is intentionally represented as “this checkpoint commit.”
A Git commit cannot contain its own final hash without changing that hash.

## Verification evidence

| Check | Result |
|---|---|
| Task 10.4 focused tests | `264` passed |
| Full Flutter test suite | `744` passed |
| `flutter analyze` | `No issues found` |
| `flutter build linux --debug` | `Succeeded: build/linux/x64/debug/bundle/dashboard_shakhsi` |
| Completion verifier | Passed |
| `git diff --check` | No output |

The final checkpoint includes:

- a complete fake-filesystem lifecycle from missing registry through two
  generations, discovery, corrupt quarantine, and return to generation zero;
- a real Linux temporary-directory adapter check for mode `0600`, exact model
  loading, direct-name listing, and symlink rejection;
- no automated access to the real HOME or real XDG systemd directory;
- no real `systemctl` invocation.

## Final interfaces

```dart
abstract interface class LinuxSystemdScheduleRegistryStore {
  Future<LinuxSystemdScheduleRegistry> load();

  Future<void> replace(LinuxSystemdScheduleRegistry next);

  Future<void> quarantineCorruptRegistry();

  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs();
}
```

```dart
abstract interface class LinuxSystemdFileSystem {
  Future<void> createDirectory(String path);

  Future<LinuxSystemdEntryType> typeOf(String path);

  Future<int> fileLength(String path);

  Future<List<String>> listNames(String directoryPath);

  Future<List<int>> readBytes(String path);

  Future<int> readMode(String path);

  Future<void> writeBytes(String path, List<int> bytes);

  Future<void> rename(String sourcePath, String destinationPath);

  Future<void> deleteFile(String path);

  Future<void> chmod(String path, int mode);
}
```

## Registry guarantees

- schema version is exactly `1`;
- generation transitions are exactly `current + 1`;
- entries are immutable and sorted by schedule identifier;
- duplicate schedule, timer, and service identities are rejected;
- JSON duplicate keys are rejected recursively;
- input is limited to 1 MiB and 10,000 entries;
- canonical encoding is deterministic UTF-8 JSON with one final newline;
- request fingerprints use SHA-256 over canonical request content;
- registry mode is exactly `0600`;
- app unit discovery accepts only exact lowercase 16-hex service/timer names;
- corrupt registries are quarantined byte-for-byte without decoding;
- exceptions retain causes and rollback failures without printing sensitive
  notification content.

## Privacy boundary

The registry model and encoded registry never store:

- notification title;
- notification body;
- notification payload;
- rendered service contents;
- rendered timer contents.

The lifecycle checkpoint verifies that title, body, payload keys, and payload
values do not appear in registry bytes.

## Durability boundary

Task 10.4 provides:

- atomic same-directory replacement for the registry file;
- in-process rollback for every observed replacement failure;
- exact restoration of prior raw bytes and mode when rollback succeeds;
- primary-error preservation with attached ordered rollback failures;
- deterministic recovery inputs for later scheduler reconciliation.

Task 10.4 does **not** claim cross-resource power-loss atomicity. One atomic
transaction cannot span the registry file, two systemd unit files, the systemd
user manager, and Drift. Explicit file and directory synchronization may be
added later through a narrower POSIX durability adapter if product risk
requires it.

## Deferred work

Task 10.5 remains pending and will add retained unit-store transactions plus
the production Linux `NotificationScheduler` orchestration.

Task 10.6 remains pending and will add repository lookup, hidden delivery mode,
platform wiring, and startup reconciliation.
