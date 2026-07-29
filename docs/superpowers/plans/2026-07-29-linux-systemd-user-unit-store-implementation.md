# Linux systemd User Unit Store Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Linux-only, injectable, two-file transactional store that installs and removes matching systemd user `.service` and `.timer` files with full in-process rollback.

**Architecture:** Resolve the systemd user-unit directory through an injected environment source, isolate all file access behind a link-aware filesystem contract, and implement installation as prepare → backup → commit → cleanup. The store writes both temporary files before touching current units, rejects symlinks, uses same-directory renames, restores the exact previous partial or complete pair on failure, and never invokes `systemctl`.

**Tech Stack:** Dart 3, Flutter test, `dart:io`, existing Task 10.1 `LinuxSystemdRenderedUnits` and `LinuxSystemdUnitNames`.

## Global Constraints

- Linux-specific production code only; Android, iOS, macOS, and Windows behavior remains unchanged.
- Prefer non-empty `XDG_CONFIG_HOME`; otherwise use non-empty `HOME/.config`.
- Resolve the final directory as `<config-base>/systemd/user`.
- Automated tests must never touch the real `~/.config/systemd/user`.
- Reject absolute file names, separators, traversal segments, unexpected extensions, symlinks, directories, and special destination entries.
- Final `.service` and `.timer` permissions are exactly `0644`.
- Temporary and backup files live in the same directory as final units.
- Installation provides full in-process rollback for both files.
- The original failure remains the primary cause; rollback failures are attached.
- Removal is idempotent and never removes the containing directory.
- Do not invoke a shell or `systemctl`.
- Do not add a persistent crash-recovery journal in this task.
- Follow RED → verify correct failure → GREEN → focused test → analyze → full test → Linux build → commit.

---

## File Map

### Production files

- Create `lib/core/notifications/linux_systemd_environment.dart`
  - injected environment contract and `Platform.environment` adapter
- Create `lib/core/notifications/linux_systemd_user_unit_path_resolver.dart`
  - XDG/HOME path resolution
- Create `lib/core/notifications/linux_systemd_file_system.dart`
  - entry-type model and injectable filesystem contract
- Create `lib/core/notifications/dart_io_linux_systemd_file_system.dart`
  - production `dart:io` adapter
- Create `lib/core/notifications/linux_systemd_user_unit_store_exception.dart`
  - structured operation, primary cause, and rollback failure model
- Create `lib/core/notifications/linux_systemd_user_unit_store.dart`
  - validation, installation transaction, rollback, and removal

### Test files

- Create `test/core/notifications/linux_systemd_user_unit_path_resolver_test.dart`
- Create `test/core/notifications/dart_io_linux_systemd_file_system_test.dart`
- Create `test/core/notifications/linux_systemd_user_unit_store_install_test.dart`
- Create `test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart`
- Create `test/core/notifications/linux_systemd_user_unit_store_remove_test.dart`
- Create `test/support/fake_linux_systemd_file_system.dart`

### Documentation

- Modify `docs/superpowers/specs/2026-07-29-linux-systemd-user-unit-store-design.md`
  - change status from approved to implemented only after the final gate
- Create `docs/superpowers/checkpoints/2026-07-29-linux-systemd-user-unit-store-checkpoint.md`

---

### Task 1: Environment Source and User Unit Path Resolver

**Files:**
- Create: `lib/core/notifications/linux_systemd_environment.dart`
- Create: `lib/core/notifications/linux_systemd_user_unit_path_resolver.dart`
- Test: `test/core/notifications/linux_systemd_user_unit_path_resolver_test.dart`

**Interfaces:**
- Produces:

```dart
abstract interface class LinuxSystemdEnvironment {
  String? value(String name);
}

final class PlatformLinuxSystemdEnvironment
    implements LinuxSystemdEnvironment {
  const PlatformLinuxSystemdEnvironment();

  @override
  String? value(String name);
}

final class LinuxSystemdUserUnitPathResolver {
  const LinuxSystemdUserUnitPathResolver(this._environment);

  String resolve();
}
```

- `resolve()` returns an absolute normalized path ending in `systemd/user`.
- It throws `LinuxSystemdConfigurationException` when no valid base exists.

- [ ] **Step 1: Write the failing resolver tests**

Create tests covering:

```dart
test('prefers non-empty XDG_CONFIG_HOME', () {
  final resolver = LinuxSystemdUserUnitPathResolver(
    MapLinuxSystemdEnvironment(<String, String>{
      'XDG_CONFIG_HOME': '/tmp/custom-config',
      'HOME': '/home/tester',
    }),
  );

  expect(resolver.resolve(), '/tmp/custom-config/systemd/user');
});

test('falls back to HOME dot config', () {
  final resolver = LinuxSystemdUserUnitPathResolver(
    MapLinuxSystemdEnvironment(<String, String>{
      'HOME': '/home/tester',
    }),
  );

  expect(resolver.resolve(), '/home/tester/.config/systemd/user');
});

test('treats whitespace-only XDG_CONFIG_HOME as missing', () {
  final resolver = LinuxSystemdUserUnitPathResolver(
    MapLinuxSystemdEnvironment(<String, String>{
      'XDG_CONFIG_HOME': '   ',
      'HOME': '/home/tester',
    }),
  );

  expect(resolver.resolve(), '/home/tester/.config/systemd/user');
});

test('rejects missing configuration bases', () {
  final resolver = LinuxSystemdUserUnitPathResolver(
    MapLinuxSystemdEnvironment(const <String, String>{}),
  );

  expect(resolver.resolve, throwsA(isA<LinuxSystemdConfigurationException>()));
});
```

Keep `MapLinuxSystemdEnvironment` inside the test file.

- [ ] **Step 2: Run RED**

```bash
flutter test test/core/notifications/linux_systemd_user_unit_path_resolver_test.dart
```

Expected: compile failure because the environment and resolver files do not exist.

- [ ] **Step 3: Implement the environment contract and resolver**

Use `Platform.environment[name]` only in `PlatformLinuxSystemdEnvironment`.

Normalize by:

```dart
String _clean(String? value) => value?.trim() ?? '';
```

Reject a non-empty base that is not absolute. On Linux paths, require `startsWith('/')`.

Join without a new path dependency:

```dart
String _append(String base, String suffix) {
  final normalizedBase =
      base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return '$normalizedBase/$suffix';
}
```

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_systemd_environment.dart \
  lib/core/notifications/linux_systemd_user_unit_path_resolver.dart \
  test/core/notifications/linux_systemd_user_unit_path_resolver_test.dart

flutter test test/core/notifications/linux_systemd_user_unit_path_resolver_test.dart
flutter analyze
```

Expected: all resolver tests pass and analyze is clean.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_environment.dart \
  lib/core/notifications/linux_systemd_user_unit_path_resolver.dart \
  test/core/notifications/linux_systemd_user_unit_path_resolver_test.dart

git commit -m "feat: resolve Linux systemd user unit directory"
```

---

### Task 2: Link-Aware Filesystem Contract and Dart IO Adapter

**Files:**
- Create: `lib/core/notifications/linux_systemd_file_system.dart`
- Create: `lib/core/notifications/dart_io_linux_systemd_file_system.dart`
- Test: `test/core/notifications/dart_io_linux_systemd_file_system_test.dart`

**Interfaces:**
- Produces:

```dart
enum LinuxSystemdEntryType {
  missing,
  regularFile,
  directory,
  symbolicLink,
  other,
}

abstract interface class LinuxSystemdFileSystem {
  Future<void> createDirectory(String path);
  Future<LinuxSystemdEntryType> typeOf(String path);
  Future<List<int>> readBytes(String path);
  Future<void> writeBytes(String path, List<int> bytes);
  Future<void> rename(String sourcePath, String destinationPath);
  Future<void> deleteFile(String path);
  Future<void> chmod(String path, int mode);
}
```

- `typeOf()` must use link-aware inspection and must not follow symlinks.
- `deleteFile()` is idempotent only for a missing path; directories and links are errors.
- `chmod(path, 0x1A4)` represents octal `0644`.

- [ ] **Step 1: Write failing adapter tests using a temporary directory**

Create tests that operate only under `Directory.systemTemp.createTemp()`:

```dart
test('typeOf distinguishes missing regular directory and symlink', () async {
  final root = await Directory.systemTemp.createTemp('systemd-fs-test-');
  addTearDown(() => root.delete(recursive: true));

  final adapter = const DartIoLinuxSystemdFileSystem();
  final filePath = '${root.path}/unit.service';
  final directoryPath = '${root.path}/nested';
  final linkPath = '${root.path}/unit-link.service';

  await File(filePath).writeAsString('unit');
  await Directory(directoryPath).create();
  await Link(linkPath).create(filePath);

  expect(
    await adapter.typeOf('${root.path}/missing'),
    LinuxSystemdEntryType.missing,
  );
  expect(
    await adapter.typeOf(filePath),
    LinuxSystemdEntryType.regularFile,
  );
  expect(
    await adapter.typeOf(directoryPath),
    LinuxSystemdEntryType.directory,
  );
  expect(
    await adapter.typeOf(linkPath),
    LinuxSystemdEntryType.symbolicLink,
  );
});
```

Also test write/read, same-filesystem rename, missing delete, and `0644` after chmod using `FileStat.mode & 0x1FF`.

- [ ] **Step 2: Run RED**

```bash
flutter test test/core/notifications/dart_io_linux_systemd_file_system_test.dart
```

Expected: compile failure because the contract and adapter are missing.

- [ ] **Step 3: Implement minimal Dart IO adapter**

Use:

```dart
final type = await FileSystemEntity.type(
  path,
  followLinks: false,
);
```

Map `FileSystemEntityType` explicitly.

For permissions, invoke no shell. Use `File(path).setLastModified` only for timestamps; do not use it for mode. Implement `chmod` through `Process.run('/bin/chmod', <String>['0644', '--', path])` is forbidden by the spec because it is an external command. Instead use `FileStat`-compatible native permissions only if the current Dart SDK exposes them. If the project SDK lacks a direct permission API, keep `chmod` in the contract and implement the adapter with `Process.run('/usr/bin/chmod', ...)` only after explicitly revising the approved spec. Do not silently violate the no-command constraint.

**Plan decision for this repository:** add package dependency `file` only if it exposes no chmod; it does not. Therefore use `dart:ffi` is out of scope. The implementation task must first check the project's existing dependencies for a POSIX mode helper. If none exists, stop at this reviewer gate and request an approved spec amendment before production implementation.

This gate is intentional: do not fake permission success.

- [ ] **Step 4: Verify GREEN or stop at the permission gate**

```bash
dart format \
  lib/core/notifications/linux_systemd_file_system.dart \
  lib/core/notifications/dart_io_linux_systemd_file_system.dart \
  test/core/notifications/dart_io_linux_systemd_file_system_test.dart

flutter test test/core/notifications/dart_io_linux_systemd_file_system_test.dart
flutter analyze
```

Expected: adapter tests pass only when real `0644` application is verified.

- [ ] **Step 5: Commit**

```bash
git add \
  pubspec.yaml \
  pubspec.lock \
  lib/core/notifications/linux_systemd_file_system.dart \
  lib/core/notifications/dart_io_linux_systemd_file_system.dart \
  test/core/notifications/dart_io_linux_systemd_file_system_test.dart

git commit -m "feat: add link-aware Linux systemd filesystem"
```

---

### Task 3: Fake Filesystem and Store Error Model

**Files:**
- Create: `test/support/fake_linux_systemd_file_system.dart`
- Create: `lib/core/notifications/linux_systemd_user_unit_store_exception.dart`
- Test: `test/core/notifications/linux_systemd_user_unit_store_install_test.dart`

**Interfaces:**
- Produces:

```dart
enum LinuxSystemdUserUnitStoreOperation {
  install,
  remove,
}

final class LinuxSystemdRollbackFailure {
  const LinuxSystemdRollbackFailure({
    required this.step,
    required this.error,
    required this.stackTrace,
  });

  final String step;
  final Object error;
  final StackTrace stackTrace;
}

final class LinuxSystemdUserUnitStoreException implements Exception {
  const LinuxSystemdUserUnitStoreException({
    required this.operation,
    required this.serviceFileName,
    required this.timerFileName,
    required this.cause,
    required this.causeStackTrace,
    this.rollbackFailures = const <LinuxSystemdRollbackFailure>[],
  });
}
```

The fake filesystem must:

```dart
final class FakeLinuxSystemdFileSystem
    implements LinuxSystemdFileSystem {
  final Map<String, FakeLinuxSystemdEntry> entries;
  final List<String> operations;
  String? failNextOperationNamed;

  void seedFile(String path, List<int> bytes, {int mode = 0x1A4});
  void seedSymlink(String path, String target);
  List<String> pathsWhere(bool Function(String path) predicate);
}
```

- Failure injection throws only once and records the attempted operation.
- Rename moves entry data and mode exactly.
- The fake never reads the real filesystem.

- [ ] **Step 1: Write failing tests for structured errors and fake semantics**

Tests must verify:

- fake write/read round trip
- fake rename preserves mode and bytes
- fake `typeOf` identifies symlink without following
- injected failure happens once
- `LinuxSystemdUserUnitStoreException.toString()` contains operation and file names but not file contents
- rollback failure list is immutable

- [ ] **Step 2: Run RED**

```bash
flutter test test/core/notifications/linux_systemd_user_unit_store_install_test.dart
```

Expected: compile failure for missing fake and error model.

- [ ] **Step 3: Implement the fake and errors**

Keep fake-only entry classes under `test/support`. Production error classes contain no filesystem implementation details.

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_systemd_user_unit_store_exception.dart \
  test/support/fake_linux_systemd_file_system.dart \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart

flutter test test/core/notifications/linux_systemd_user_unit_store_install_test.dart
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_user_unit_store_exception.dart \
  test/support/fake_linux_systemd_file_system.dart \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart

git commit -m "test: add Linux systemd store failure harness"
```

---

### Task 4: Safe Unit Names and Successful Atomic Installation

**Files:**
- Create: `lib/core/notifications/linux_systemd_user_unit_store.dart`
- Modify: `test/core/notifications/linux_systemd_user_unit_store_install_test.dart`

**Interfaces:**
- Consumes:

```dart
LinuxSystemdRenderedUnits
LinuxSystemdUserUnitPathResolver
LinuxSystemdFileSystem
```

- Produces:

```dart
typedef LinuxSystemdTransactionIdFactory = String Function();

final class LinuxSystemdUserUnitStore {
  LinuxSystemdUserUnitStore({
    required LinuxSystemdUserUnitPathResolver pathResolver,
    required LinuxSystemdFileSystem fileSystem,
    required LinuxSystemdTransactionIdFactory transactionIdFactory,
  });

  Future<void> install(LinuxSystemdRenderedUnits units);
  Future<void> remove(LinuxSystemdUnitNames names);
}
```

- [ ] **Step 1: Write failing successful-install tests**

Cover:

```dart
test('installs a new service and timer with mode 0644', () async {
  final store = buildStore(transactionId: 'tx-1');
  final units = buildRenderedUnits();

  await store.install(units);

  expect(fake.readText('/xdg/systemd/user/${units.serviceFileName}'), service);
  expect(fake.readText('/xdg/systemd/user/${units.timerFileName}'), timer);
  expect(fake.modeOf(servicePath), 0x1A4);
  expect(fake.modeOf(timerPath), 0x1A4);
});
```

Also verify:

- directory creation
- existing complete pair replacement
- existing service-only pair replacement
- existing timer-only pair replacement
- temp files are fully written before any final path changes
- no temp or backup artifacts remain
- unrelated entries remain byte-for-byte unchanged
- names with `/`, `\`, `..`, absolute prefixes, wrong suffixes, or embedded NUL are rejected
- destination symlink, directory, and `other` entry types are rejected

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart
```

Expected: compile failure because `LinuxSystemdUserUnitStore` is missing.

- [ ] **Step 3: Implement validation and success path**

Validate renderer names independently:

```dart
final servicePattern = RegExp(
  r'^dashboard-shakhsi-notification-[0-9a-f]{16}\.service$',
);
final timerPattern = RegExp(
  r'^dashboard-shakhsi-notification-[0-9a-f]{16}\.timer$',
);
```

Require both names to share the same base.

Transaction paths:

```dart
'.$fileName.$transactionId.tmp'
'.$fileName.$transactionId.bak'
```

Validate transaction ID with:

```dart
RegExp(r'^[A-Za-z0-9_-]{1,64}$')
```

Preparation order:

1. create directory
2. preflight all final/temp/backup entries
3. write service temp
4. write timer temp
5. chmod service temp
6. chmod timer temp

Commit order:

1. backup existing service
2. backup existing timer
3. rename service temp to final
4. rename timer temp to final
5. chmod service final
6. chmod timer final
7. delete service backup
8. delete timer backup

Track each completed step in transaction state; do not infer state from current existence during rollback.

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_systemd_user_unit_store.dart \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart

flutter test \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart

flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_user_unit_store.dart \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart

git commit -m "feat: install Linux systemd units transactionally"
```

---

### Task 5: Full Rollback and Failure Aggregation

**Files:**
- Modify: `lib/core/notifications/linux_systemd_user_unit_store.dart`
- Create: `test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart`

**Interfaces:**
- `install()` throws `LinuxSystemdUserUnitStoreException`.
- `cause` and `causeStackTrace` describe the original failure.
- `rollbackFailures` preserves every rollback or cleanup failure in execution order.

- [ ] **Step 1: Write parameterized RED tests for every failure point**

Use a table:

```dart
final failurePoints = <String>[
  'write:$serviceTemp',
  'write:$timerTemp',
  'chmod:$serviceTemp',
  'chmod:$timerTemp',
  'rename:$serviceFinal->$serviceBackup',
  'rename:$timerFinal->$timerBackup',
  'rename:$serviceTemp->$serviceFinal',
  'rename:$timerTemp->$timerFinal',
  'chmod:$serviceFinal',
  'chmod:$timerFinal',
  'delete:$serviceBackup',
  'delete:$timerBackup',
];
```

For each previous state:

```dart
enum PreviousPairState {
  missing,
  complete,
  serviceOnly,
  timerOnly,
}
```

Assert after an injected failure:

- previous service bytes restored or absent as before
- previous timer bytes restored or absent as before
- previous modes restored
- no transaction temp files remain when cleanup succeeds
- no transaction backup files remain when restoration succeeds
- unrelated entries are unchanged
- exception `cause` is the injected original error

Add dedicated tests where restoration or cleanup also fails. Assert the original cause remains unchanged and rollback failures are appended.

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart
```

Expected: failures showing partial final state or missing rollback aggregation.

- [ ] **Step 3: Implement rollback with explicit transaction state**

Use a private state object:

```dart
final class _InstallTransactionState {
  bool serviceHadPrevious = false;
  bool timerHadPrevious = false;
  bool serviceBackedUp = false;
  bool timerBackedUp = false;
  bool serviceInstalled = false;
  bool timerInstalled = false;
}
```

Rollback order:

1. delete newly installed timer when installed
2. delete newly installed service when installed
3. restore service backup when backed up
4. restore timer backup when backed up
5. delete remaining service temp
6. delete remaining timer temp
7. delete backup only after successful restore

Wrap each rollback action independently and collect failures:

```dart
Future<void> attemptRollback(
  String step,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error, stackTrace) {
    rollbackFailures.add(
      LinuxSystemdRollbackFailure(
        step: step,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
```

Do not throw from inside rollback until all possible actions have been attempted.

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_systemd_user_unit_store.dart \
  test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart

flutter test \
  test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart

flutter test \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart

flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_user_unit_store.dart \
  test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart

git commit -m "feat: roll back Linux systemd unit installation"
```

---

### Task 6: Idempotent and Symlink-Safe Removal

**Files:**
- Modify: `lib/core/notifications/linux_systemd_user_unit_store.dart`
- Create: `test/core/notifications/linux_systemd_user_unit_store_remove_test.dart`

**Interfaces:**
- Consumes `LinuxSystemdUnitNames`.
- `remove()` does not remove the user-unit directory.
- Missing final files are success.
- Existing symlink, directory, or special entries are errors.

- [ ] **Step 1: Write failing removal tests**

Cover:

```dart
test('removes timer before service', () async {
  await store.remove(names);

  expect(fake.operations, containsAllInOrder(<String>[
    'delete:$timerPath',
    'delete:$servicePath',
  ]));
});
```

Also test:

- both present
- both missing
- service only
- timer only
- timer symlink
- service symlink
- directory destination
- unrelated files preserved
- containing directory preserved
- delete timer failure prevents service deletion
- errors are wrapped with operation `remove`

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_user_unit_store_remove_test.dart
```

Expected: failures because `remove()` is unimplemented or incomplete.

- [ ] **Step 3: Implement minimal removal**

Flow:

1. resolve directory
2. derive and validate final paths
3. inspect both entries without following links
4. reject unsafe entry types before deleting either file
5. delete timer when regular
6. delete service when regular
7. leave directory untouched

Wrap failures in `LinuxSystemdUserUnitStoreException` with an empty rollback list.

- [ ] **Step 4: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_systemd_user_unit_store.dart \
  test/core/notifications/linux_systemd_user_unit_store_remove_test.dart

flutter test \
  test/core/notifications/linux_systemd_user_unit_store_remove_test.dart

flutter test \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_remove_test.dart

flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add \
  lib/core/notifications/linux_systemd_user_unit_store.dart \
  test/core/notifications/linux_systemd_user_unit_store_remove_test.dart

git commit -m "feat: remove Linux systemd units safely"
```

---

### Task 7: Final Verification and Checkpoint

**Files:**
- Create: `docs/superpowers/checkpoints/2026-07-29-linux-systemd-user-unit-store-checkpoint.md`
- Modify: `docs/superpowers/specs/2026-07-29-linux-systemd-user-unit-store-design.md`
- Create: `tool/verify_phase1_task10_2_complete.py`

**Interfaces:**
- No new runtime API.
- Checkpoint records actual focused and full-suite results.

- [ ] **Step 1: Add the final static verifier**

The verifier must confirm:

- all six production files exist
- all five test files and fake filesystem exist
- store contains both `install` and `remove`
- destination symlink rejection exists
- mode `0x1A4` exists
- rollback failure aggregation exists
- no `systemctl`, `/bin/sh`, or `sh -c` appears in Task 10.2 production files
- no test references the real user's `.config/systemd/user`

- [ ] **Step 2: Run all focused tests**

```bash
flutter test \
  test/core/notifications/linux_systemd_user_unit_path_resolver_test.dart \
  test/core/notifications/dart_io_linux_systemd_file_system_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_remove_test.dart
```

Expected: all focused Task 10.2 tests pass.

- [ ] **Step 3: Run repository verification**

```bash
python3 tool/verify_phase1_task10_2_complete.py

flutter analyze

flutter test

flutter build linux --debug

git diff --check
```

Expected:

- verifier prints `OK`
- analyze reports no issues
- full suite passes
- Linux debug bundle builds
- diff check is clean

- [ ] **Step 4: Write checkpoint with real outputs**

Document:

- exact focused test count
- exact full test count
- Linux build output
- permission implementation used by the Dart IO adapter
- known crash boundary
- confirmation that no non-Linux selector or backend changed

Change the design status to:

```text
Status: Implemented and verified
```

- [ ] **Step 5: Commit and push**

```bash
git add -A

git commit -m "feat: add atomic Linux systemd unit store"

git push
```

---

## Execution Review Gates

Stop and review after each commit:

1. Resolver API and environment semantics
2. Filesystem contract and real permission application
3. Fake filesystem and error model
4. Successful transaction behavior
5. Rollback matrix and failure aggregation
6. Removal safety
7. Full repository verification

The Task 10.2 branch is complete only after Gate 7 succeeds.
