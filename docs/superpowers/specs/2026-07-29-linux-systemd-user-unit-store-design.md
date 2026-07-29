# Linux systemd User Unit Store — Design

Date: 2026-07-29  
Phase: 1  
Task: 10.2  
Status: Approved for implementation planning

## Objective

Add a Linux-only atomic file store for systemd user notification units.

The store installs and removes matching `.service` and `.timer` files under
the current user's systemd configuration directory. It guarantees that a
failed two-file replacement does not leave mismatched unit versions.

This task does not invoke `systemctl`, schedule notifications, write Drift
records, or change Android, iOS, macOS, or Windows behavior.

## Platform scope

The implementation is Linux-specific.

- Linux uses the new systemd user-unit store.
- Android keeps its existing native notification scheduling backend.
- iOS and macOS keep their existing native notification scheduling backend.
- Windows keeps its existing platform implementation.
- Non-Linux code must not resolve or create systemd directories.

A later platform selector task will route only Linux scheduling operations to
the systemd backend.

## Resolved configuration path

The user-unit directory is resolved in this order:

1. If `XDG_CONFIG_HOME` is defined and non-empty:

   ```text
   $XDG_CONFIG_HOME/systemd/user
   ```

2. Otherwise, if `HOME` is defined and non-empty:

   ```text
   $HOME/.config/systemd/user
   ```

3. Otherwise, resolution fails with a descriptive configuration error.

The resolver does not create the directory. Directory creation belongs to the
store operation.

## Components

### LinuxSystemdUserUnitPathResolver

Responsibilities:

- read environment values from an injected environment source
- prefer `XDG_CONFIG_HOME`
- fall back to `HOME/.config`
- append `systemd/user`
- reject missing or empty base directories
- return a normalized absolute path

The resolver has no direct dependency on `Platform.environment`.

### LinuxSystemdFileSystem

Injected filesystem contract used by the store.

Required operations:

- create a directory recursively
- test whether a path exists without following symlinks
- inspect entry type using `lstat`
- read file bytes
- write file bytes
- rename a path
- delete a path
- apply numeric permissions
- enumerate transaction-owned temporary artifacts when required

The contract must distinguish regular files, directories, symlinks, and
missing entries.

### DartIoLinuxSystemdFileSystem

Production implementation backed by `dart:io`.

Responsibilities:

- adapt `dart:io` operations to the injected contract
- preserve original filesystem exceptions
- use link-aware inspection for destination validation
- never invoke a shell

### LinuxSystemdUserUnitStore

Public operations:

```dart
Future<void> install(LinuxSystemdRenderedUnits units);
Future<void> remove(LinuxSystemdUnitNames names);
```

Dependencies:

- `LinuxSystemdUserUnitPathResolver`
- `LinuxSystemdFileSystem`
- transaction ID generator

The store accepts only file names produced by the Task 10.1 renderer and unit
name model.

## Security rules

- Destination `.service` and `.timer` paths must remain inside the resolved
  systemd user-unit directory.
- Absolute paths, path separators, traversal segments, and unexpected suffixes
  in supplied file names are rejected.
- Existing destination symlinks are rejected.
- Existing temporary or backup paths that are symlinks are rejected before use.
- The store never follows a destination symlink.
- Files are created with final permission `0644`.
- Unit contents are written as bytes without shell interpolation.
- Unrelated files in the directory are never modified.

## Installation transaction

Each installation uses unique temporary and backup paths in the same directory
as the final units so that rename operations stay on the same filesystem.

Example transaction-owned paths:

```text
.<service-name>.<transaction-id>.tmp
.<timer-name>.<transaction-id>.tmp
.<service-name>.<transaction-id>.bak
.<timer-name>.<transaction-id>.bak
```

### Preflight

1. Resolve the user-unit directory.
2. Create the directory recursively.
3. Validate final file names.
4. Validate that destination entries are either missing or regular files.
5. Reject symlink destinations.
6. Validate that transaction-owned temp and backup paths do not already exist
   as unsafe entry types.

### Prepare

1. Write complete service contents to the service temp file.
2. Write complete timer contents to the timer temp file.
3. Apply permission `0644` to both temp files.
4. Do not modify either final file during preparation.

If preparation fails, delete transaction-owned temp files and leave current
final units unchanged.

### Commit

1. Rename an existing service file to its service backup path.
2. Rename an existing timer file to its timer backup path.
3. Rename the prepared service temp file to the final service path.
4. Rename the prepared timer temp file to the final timer path.
5. Apply permission `0644` to both final files.
6. Delete both backups.

The transaction is successful only after both final files are installed and
both backup files are removed.

## Rollback semantics

If any failure occurs after commit begins:

1. Capture the original failure.
2. Remove newly installed final files owned by the transaction.
3. Restore the previous service backup when it existed.
4. Restore the previous timer backup when it existed.
5. Delete remaining temp files.
6. Delete transaction-owned backups only after restoration succeeds.
7. Re-throw an installation exception containing:
   - the original failure
   - any rollback failures
   - affected unit file names

The original failure remains the primary cause. Rollback failures must not hide
it.

Expected outcomes:

| Previous service | Previous timer | Installation failure | Final state |
|---|---|---|---|
| missing | missing | before commit | both missing |
| missing | missing | after service install | both missing |
| present | present | after service install | both previous versions |
| present | present | after timer install | both previous versions |
| present | missing | any commit failure | service restored, timer missing |
| missing | present | any commit failure | service missing, timer restored |

A partially existing previous pair is preserved exactly during rollback.

## Removal semantics

Removal is idempotent.

1. Resolve the directory.
2. Validate file names and destination entry types.
3. Reject symlinks.
4. Remove the timer file when present.
5. Remove the service file when present.
6. Ignore missing final files.
7. Do not remove the containing directory.
8. Do not modify unrelated files.

Removal does not call `systemctl`. The command-driver task will disable and stop
timers before invoking store removal.

## Crash boundary

This task guarantees rollback for failures observed within the running process.

It does not guarantee automatic recovery after process termination, power loss,
or kernel crash between rename operations. A persistent transaction journal is
explicitly deferred to Phase 1 hardening because it adds recovery state and
startup reconciliation complexity.

The same-directory rename design minimizes but does not eliminate that crash
window.

## Error model

Use explicit exception types or structured failure data for:

- missing configuration environment
- unsafe file name
- symlink destination
- invalid destination entry type
- preparation failure
- commit failure
- rollback failure

Errors must include operation context without embedding unit contents.

## Test strategy

Tests use an injected in-memory or fake filesystem. No test writes to the real
`~/.config/systemd/user` directory.

### Path resolver tests

- prefers non-empty `XDG_CONFIG_HOME`
- falls back to non-empty `HOME`
- rejects missing variables
- rejects empty variables
- produces the expected `systemd/user` suffix
- does not resolve paths on non-Linux selector tests

### Validation tests

- accepts renderer-generated names
- rejects absolute names
- rejects `..`
- rejects `/` and `\\`
- rejects unexpected extensions
- rejects destination symlinks
- rejects directories and special entries
- leaves unrelated files untouched

### Successful install tests

- creates the directory recursively
- writes both units
- applies `0644`
- replaces an existing matching pair
- replaces a partially existing pair
- leaves no temp or backup artifacts
- installs deterministic byte-for-byte contents

### Failure-injection tests

Inject failures at:

- service temp write
- timer temp write
- service temp chmod
- timer temp chmod
- service backup rename
- timer backup rename
- service install rename
- timer install rename
- final chmod
- service backup cleanup
- timer backup cleanup
- service rollback restore
- timer rollback restore
- temp cleanup

For every failure point, assert:

- previous state is restored when rollback can succeed
- no unrelated entry changes
- the original cause remains available
- rollback failures are attached rather than substituted

### Removal tests

- removes both files
- removes only the existing file from a partial pair
- succeeds when both files are absent
- rejects symlinks
- leaves the directory and unrelated entries intact

## Acceptance criteria

Task 10.2 is complete when:

- the resolver, filesystem contract, Dart IO adapter, and store exist
- the install operation provides full in-process two-file rollback
- destination symlinks are rejected
- permissions are `0644`
- XDG and HOME fallback behavior is tested
- real user systemd paths are never touched by automated tests
- focused tests pass
- `flutter analyze` reports no issues
- the full Flutter test suite passes
- Linux debug build succeeds
- Android, iOS, macOS, and Windows production behavior is unchanged

## Deferred work

The following belong to later Task 10 packages:

- `systemctl --user` execution
- daemon reload
- enabling, starting, stopping, and disabling timers
- Linux scheduler backend
- Drift reconciliation
- hidden notification-delivery application entry point
- persistent crash-recovery journal
- cross-platform scheduler selector
