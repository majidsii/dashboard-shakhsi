# Persistent Linux systemd Schedule Registry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a privacy-preserving, versioned, strictly decoded, atomically replaced registry that inventories app-owned Linux systemd notification schedules without calling `systemctl`.

**Architecture:** Keep registry domain validation, strict JSON decoding, request fingerprinting, filesystem primitives, and file-store orchestration in separate focused files. The production store resolves the existing systemd user directory, checks file type and size before reading, uses same-directory temp/backup renames with mode `0600`, preserves the original error when rollback also fails, quarantines corruption without deleting evidence, and discovers only exact app-owned unit names.

**Tech Stack:** Dart 3.12+, Flutter test, `dart:convert`, `dart:io`, `cryptography: ^2.9.0`, existing `LinuxSystemdUserUnitPathResolver`, `LinuxSystemdFileSystem`, `NotificationRequest`, `NotificationOwner`, `LinuxSystemdTimerName`, and `LinuxSystemdUnitNames`.

## Global Constraints

- Implement only Task 10.4 from `docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md`.
- Do not call `systemctl`, `Process.start`, `Process.run`, a shell, or any notification gateway.
- Drift remains desired state; this registry is only platform inventory.
- Registry schema version is exactly `1`.
- Missing registry means an empty schema-version-1 registry with generation `0`.
- Registry final name is exactly `dashboard-shakhsi-notification-registry.json`.
- Registry final permissions are exactly octal `0600` (`0x180`).
- Registry size limit is exactly `1 MiB` (`1 << 20` bytes).
- Registry entry-count limit is exactly `10,000`.
- Registry content contains no title, body, payload, rendered service text, or rendered timer text.
- Fingerprints use SHA-256 over canonical UTF-8 JSON and are 64 lowercase hexadecimal characters.
- Every timestamp stored in the registry is UTC and uses canonical `DateTime.toIso8601String()` text ending in `Z`.
- Unknown JSON keys, duplicate JSON object keys, unsupported versions, malformed UTF-8, non-integer numeric fields, and corrupt content fail closed.
- `load()` never silently deletes, quarantines, or treats corrupt content as empty.
- Atomic replacement uses same-directory temp and backup files.
- The original operation failure remains primary; rollback failures are attached in encounter order.
- Symlinks, directories, and special files are never followed or replaced.
- Unit discovery lists direct children only, validates every app-owned matched path, and ignores unrelated names.
- Tests use `FakeLinuxSystemdFileSystem` or a process-owned temporary directory; no test touches the real user systemd directory.
- Follow RED → verify expected failure → GREEN → focused tests → `flutter analyze` → full `flutter test` → Linux debug build → `git diff --check` → commit.
- Remove each RED-only verifier before its Gate commit; retain the GREEN verifier.
- Task 10.4 uses eight review Gates and eight commits.

## Implementation Clarification

The approved spec requires one discovery operation while also requiring complete and partial pairs to be reported. The concrete signature is therefore:

```dart
Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs();
```

`LinuxSystemdUnitDiscovery` exposes both immutable sets:

```dart
Set<LinuxSystemdUnitNames> completePairs;
Set<LinuxSystemdPartialUnitPair> partialPairs;
```

This preserves the approved method name and satisfies the partial-pair recovery requirement without a second directory scan.

---

## File Map

### New production files

- `lib/core/notifications/linux_systemd_schedule_registry.dart`
  - immutable registry, entry, discovery, and partial-pair models
- `lib/core/notifications/linux_systemd_schedule_registry_exception.dart`
  - typed failure categories, operation metadata, primary cause, rollback failures
- `lib/core/notifications/linux_systemd_registry_json_decoder.dart`
  - recursive-descent JSON decoder that rejects duplicate object keys
- `lib/core/notifications/linux_systemd_schedule_registry_codec.dart`
  - strict version-1 schema decoder and canonical encoder
- `lib/core/notifications/linux_notification_request_fingerprint.dart`
  - canonical request JSON and SHA-256 digest
- `lib/core/notifications/linux_systemd_schedule_registry_store.dart`
  - store interface and transaction-ID factory
- `lib/core/notifications/linux_systemd_schedule_registry_file_store.dart`
  - production load, atomic replace, rollback, quarantine, and unit discovery

### Modified production files

- `lib/core/notifications/linux_systemd_notification_unit.dart`
  - add strict construction of `LinuxSystemdUnitNames` from an app-owned base name
- `lib/core/notifications/linux_systemd_file_system.dart`
  - add `fileLength` and `listNames`
- `lib/core/notifications/dart_io_linux_systemd_file_system.dart`
  - implement length-before-read support and non-recursive, non-following directory listing

### New tests

- `test/core/notifications/linux_systemd_schedule_registry_model_test.dart`
- `test/core/notifications/linux_systemd_registry_json_decoder_test.dart`
- `test/core/notifications/linux_systemd_schedule_registry_codec_test.dart`
- `test/core/notifications/linux_notification_request_fingerprint_test.dart`
- `test/core/notifications/linux_systemd_file_system_registry_extensions_test.dart`
- `test/core/notifications/linux_systemd_schedule_registry_store_load_test.dart`
- `test/core/notifications/linux_systemd_schedule_registry_store_replace_test.dart`
- `test/core/notifications/linux_systemd_schedule_registry_store_recovery_test.dart`
- `test/core/notifications/linux_systemd_schedule_registry_final_checkpoint_test.dart`

### Modified test support

- `test/support/fake_linux_systemd_file_system.dart`
  - deterministic `fileLength`, `listNames`, operation recording, and injected failures

### Documentation

- Create `docs/superpowers/checkpoints/2026-07-29-linux-systemd-schedule-registry-checkpoint.md`
- Update Task 10.4 status in `docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md` only after the final Gate passes

---

# Gate 10.4.1 — Immutable Registry and Discovery Models

**Files:**
- Create: `lib/core/notifications/linux_systemd_schedule_registry.dart`
- Create: `lib/core/notifications/linux_systemd_schedule_registry_exception.dart`
- Modify: `lib/core/notifications/linux_systemd_notification_unit.dart`
- Test: `test/core/notifications/linux_systemd_schedule_registry_model_test.dart`
- Create: `tool/verify_phase1_task10_4_1_green.py`

**Interfaces:**

```dart
enum LinuxSystemdScheduleRegistryOperation {
  validate,
  decode,
  load,
  replace,
  quarantine,
  discover,
}

enum LinuxSystemdScheduleRegistryFailure {
  unsupportedSchemaVersion,
  malformedJson,
  malformedUtf8,
  oversizedRegistry,
  excessiveEntryCount,
  invalidGeneration,
  invalidGenerationTransition,
  duplicateScheduleId,
  duplicateTimerName,
  duplicateServiceName,
  invalidScheduleId,
  invalidOwner,
  invalidTimestamp,
  invalidFingerprint,
  invalidUnitIdentity,
  unsafeRegistryPath,
  insecureRegistryMode,
  unsafeAppUnitPath,
  atomicReplacementFailed,
  quarantineFailed,
  discoveryFailed,
}

final class LinuxSystemdRegistryRollbackFailure {
  const LinuxSystemdRegistryRollbackFailure({
    required String step,
    required Object error,
    required StackTrace stackTrace,
  });
}

final class LinuxSystemdScheduleRegistryException implements Exception {
  factory LinuxSystemdScheduleRegistryException({
    required LinuxSystemdScheduleRegistryOperation operation,
    required LinuxSystemdScheduleRegistryFailure failure,
    String? path,
    String? field,
    Object? cause,
    StackTrace? causeStackTrace,
    List<LinuxSystemdRegistryRollbackFailure> rollbackFailures =
        const <LinuxSystemdRegistryRollbackFailure>[],
  });
}
```

```dart
final class LinuxSystemdScheduleRegistryEntry {
  factory LinuxSystemdScheduleRegistryEntry({
    required String scheduleId,
    required NotificationOwner owner,
    required LinuxSystemdTimerName timerName,
    required String serviceFileName,
    required DateTime scheduledAtUtc,
    required String requestFingerprint,
  });

  final String scheduleId;
  final NotificationOwner owner;
  final LinuxSystemdTimerName timerName;
  final String serviceFileName;
  final DateTime scheduledAtUtc;
  final String requestFingerprint;
}
```

```dart
final class LinuxSystemdScheduleRegistry {
  factory LinuxSystemdScheduleRegistry({
    required int schemaVersion,
    required int generation,
    required Iterable<LinuxSystemdScheduleRegistryEntry> entries,
  });

  factory LinuxSystemdScheduleRegistry.empty();

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final int generation;
  final List<LinuxSystemdScheduleRegistryEntry> entries;

  LinuxSystemdScheduleRegistryEntry? entryForScheduleId(String scheduleId);
}
```

```dart
final class LinuxSystemdPartialUnitPair {
  const LinuxSystemdPartialUnitPair({
    required String baseName,
    required bool hasService,
    required bool hasTimer,
  });

  final String baseName;
  final bool hasService;
  final bool hasTimer;
}

final class LinuxSystemdUnitDiscovery {
  factory LinuxSystemdUnitDiscovery({
    required Iterable<LinuxSystemdUnitNames> completePairs,
    required Iterable<LinuxSystemdPartialUnitPair> partialPairs,
  });

  final Set<LinuxSystemdUnitNames> completePairs;
  final Set<LinuxSystemdPartialUnitPair> partialPairs;
}
```

Add this factory to `LinuxSystemdUnitNames`:

```dart
factory LinuxSystemdUnitNames.parseBaseName(String baseName)
```

It accepts only:

```text
dashboard-shakhsi-notification-<16 lowercase hexadecimal characters>
```

- [ ] **Step 1: Write RED tests for a valid entry and deterministic registry ordering**

Use two entries inserted in reverse order and verify the stored list is sorted:

```dart
final registry = LinuxSystemdScheduleRegistry(
  schemaVersion: 1,
  generation: 7,
  entries: <LinuxSystemdScheduleRegistryEntry>[
    entry(scheduleId: 'z-reminder'),
    entry(scheduleId: 'a-reminder'),
  ],
);

expect(
  registry.entries.map((item) => item.scheduleId),
  orderedEquals(<String>['a-reminder', 'z-reminder']),
);
expect(registry.entryForScheduleId('a-reminder'), isNotNull);
expect(registry.entries, isA<List<LinuxSystemdScheduleRegistryEntry>>());
```

- [ ] **Step 2: Add RED tests for every model invariant**

Cover exact failures for:

```text
schemaVersion != 1
generation < 0
blank scheduleId
scheduleId with surrounding whitespace
non-UTC scheduledAtUtc
fingerprint shorter or longer than 64 characters
uppercase fingerprint
non-hex fingerprint
timer/service base mismatch
stable names not derived from scheduleId
duplicate scheduleId
duplicate timer name
duplicate service name
```

Construct stable names with:

```dart
final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
final timerName = LinuxSystemdTimerName.parse(names.timerFileName);
```

Expect `LinuxSystemdScheduleRegistryException` with the matching `failure` enum, not a generic `ArgumentError`.

- [ ] **Step 3: Add RED tests for immutable equality-friendly discovery models**

Verify:

```dart
final discovery = LinuxSystemdUnitDiscovery(
  completePairs: <LinuxSystemdUnitNames>[namesB, namesA, namesA],
  partialPairs: <LinuxSystemdPartialUnitPair>[
    LinuxSystemdPartialUnitPair(
      baseName: partialBase,
      hasService: true,
      hasTimer: false,
    ),
  ],
);

expect(discovery.completePairs.length, 2);
expect(
  discovery.completePairs.map((item) => item.baseName),
  orderedEquals(<String>[namesA.baseName, namesB.baseName]),
);
expect(
  () => discovery.completePairs.add(namesA),
  throwsUnsupportedError,
);
```

Also reject a partial pair where both flags are true or both are false.

- [ ] **Step 4: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_schedule_registry_model_test.dart
```

Expected: compilation failure because the registry model and exception files do not exist and `LinuxSystemdUnitNames.parseBaseName` is undefined.

- [ ] **Step 5: Implement minimal validated models**

Implementation rules:

```dart
static final RegExp _fingerprintPattern = RegExp(r'^[0-9a-f]{64}$');
static final RegExp _baseNamePattern = RegExp(
  r'^dashboard-shakhsi-notification-[0-9a-f]{16}$',
);
```

Normalize `scheduleId` exactly as the existing request model does, but reject non-canonical input:

```dart
final normalized = scheduleId.trim();
if (normalized.isEmpty || normalized != scheduleId) {
  throw LinuxSystemdScheduleRegistryException(
    operation: LinuxSystemdScheduleRegistryOperation.validate,
    failure: LinuxSystemdScheduleRegistryFailure.invalidScheduleId,
    field: 'scheduleId',
  );
}
```

Verify unit identity using:

```dart
final expected = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
if (timerName.value != expected.timerFileName ||
    serviceFileName != expected.serviceFileName) {
  throw LinuxSystemdScheduleRegistryException(
    operation: LinuxSystemdScheduleRegistryOperation.validate,
    failure: LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
  );
}
```

Sort before storing and reject duplicates in one pass with three sets. Store all collections with `List.unmodifiable`, `Set.unmodifiable`, and deterministic insertion order.

- [ ] **Step 6: Verify GREEN**

```bash
dart format \
  lib/core/notifications/linux_systemd_schedule_registry.dart \
  lib/core/notifications/linux_systemd_schedule_registry_exception.dart \
  lib/core/notifications/linux_systemd_notification_unit.dart \
  test/core/notifications/linux_systemd_schedule_registry_model_test.dart

python3 tool/verify_phase1_task10_4_1_green.py

flutter test \
  test/core/notifications/linux_systemd_schedule_registry_model_test.dart

flutter analyze
git diff --check
```

- [ ] **Step 7: Commit Gate 10.4.1**

```bash
git add \
  lib/core/notifications/linux_systemd_schedule_registry.dart \
  lib/core/notifications/linux_systemd_schedule_registry_exception.dart \
  lib/core/notifications/linux_systemd_notification_unit.dart \
  test/core/notifications/linux_systemd_schedule_registry_model_test.dart \
  tool/verify_phase1_task10_4_1_green.py

git commit -m "feat: add Linux schedule registry models"
git push
```

---

# Gate 10.4.2 — Duplicate-Aware JSON Decoder and Canonical Registry Codec

**Files:**
- Create: `lib/core/notifications/linux_systemd_registry_json_decoder.dart`
- Create: `lib/core/notifications/linux_systemd_schedule_registry_codec.dart`
- Test: `test/core/notifications/linux_systemd_registry_json_decoder_test.dart`
- Test: `test/core/notifications/linux_systemd_schedule_registry_codec_test.dart`
- Create: `tool/verify_phase1_task10_4_2_green.py`

**Interfaces:**

```dart
final class LinuxSystemdRegistryJsonDecoder {
  const LinuxSystemdRegistryJsonDecoder();

  Object? decode(String source);
}
```

```dart
final class LinuxSystemdScheduleRegistryCodec {
  const LinuxSystemdScheduleRegistryCodec({
    LinuxSystemdRegistryJsonDecoder jsonDecoder =
        const LinuxSystemdRegistryJsonDecoder(),
  });

  static const int maximumFileBytes = 1 << 20;
  static const int maximumEntries = 10000;

  LinuxSystemdScheduleRegistry decodeBytes(List<int> bytes);
  List<int> encodeBytes(LinuxSystemdScheduleRegistry registry);
}
```

- [ ] **Step 1: Write RED tests for the strict decoder**

The recursive-descent decoder must accept ordinary JSON and reject duplicate keys at every nesting level:

```dart
expect(
  decoder.decode('{"a":1,"b":{"c":true},"d":[null,"x"]}'),
  equals(<String, Object?>{
    'a': 1,
    'b': <String, Object?>{'c': true},
    'd': <Object?>[null, 'x'],
  }),
);

expect(
  () => decoder.decode('{"a":1,"a":2}'),
  throwsA(
    isA<LinuxSystemdScheduleRegistryException>().having(
      (error) => error.failure,
      'failure',
      LinuxSystemdScheduleRegistryFailure.malformedJson,
    ),
  ),
);

expect(
  () => decoder.decode('{"outer":{"x":1,"x":2}}'),
  throwsA(isA<LinuxSystemdScheduleRegistryException>()),
);
```

Also test escaped strings, Unicode escapes including surrogate pairs, exponent numbers, trailing content, unterminated structures, invalid escapes, and control characters inside strings.

- [ ] **Step 2: Implement the strict decoder as a recursive-descent parser**

Use one private parser with these exact methods:

```dart
Object? parse();
Object? _parseValue();
Map<String, Object?> _parseObject();
List<Object?> _parseArray();
String _parseString();
num _parseNumber();
void _skipWhitespace();
bool _consume(String token);
Never _malformed(String message);
```

Rules:

- `_parseObject` owns a `Set<String> keys`; adding an existing key throws.
- Strings decode `\" \\ \/ \b \f \n \r \t \uXXXX`.
- A high surrogate must be followed by a low surrogate.
- Number grammar is JSON grammar, not Dart's permissive parser.
- Return `int` when the lexeme contains no decimal point or exponent and `int.parse` succeeds.
- Return `double` for fractional/exponent forms.
- After `_parseValue`, only JSON whitespace may remain.
- Wrap every syntax error as `LinuxSystemdScheduleRegistryException` with operation `decode`, failure `malformedJson`, and no source content in the exception.

- [ ] **Step 3: Run strict-decoder RED and GREEN**

```bash
flutter test \
  test/core/notifications/linux_systemd_registry_json_decoder_test.dart
```

Expected RED: missing decoder.

After implementation:

```bash
dart format \
  lib/core/notifications/linux_systemd_registry_json_decoder.dart \
  test/core/notifications/linux_systemd_registry_json_decoder_test.dart

flutter test \
  test/core/notifications/linux_systemd_registry_json_decoder_test.dart
```

- [ ] **Step 4: Write RED tests for canonical version-1 registry encoding**

Use a two-entry registry and assert exact UTF-8 text, including field order and one final newline:

```json
{"schemaVersion":1,"generation":7,"entries":[{"scheduleId":"a-reminder","ownerType":"task","ownerId":"task-a","timerName":"dashboard-shakhsi-notification-...timer","serviceFileName":"dashboard-shakhsi-notification-...service","scheduledAtUtc":"2026-07-30T05:30:00.000Z","requestFingerprint":"..."},{"scheduleId":"z-reminder",...}]}
```

The expected Dart string must end with exactly `\n` and contain no spaces outside string values.

- [ ] **Step 5: Add strict decode tests**

Cover:

```text
empty bytes
whitespace-only bytes
malformed UTF-8
top-level non-object
unknown top-level key
missing top-level key
duplicate top-level key
schemaVersion as 1.0
unsupported schemaVersion
generation as 7.0
negative generation
entries as non-array
unknown entry key
missing entry key
duplicate entry key
unknown ownerType
invalid UTC timestamp
non-canonical timestamp
invalid fingerprint
more than 10,000 entries
exactly 10,000 entries
exactly 1 MiB input
more than 1 MiB input
```

For malformed UTF-8, use:

```dart
const <int>[0x7b, 0x22, 0x78, 0x22, 0x3a, 0xff, 0x7d]
```

For canonical timestamps, require:

```dart
value.endsWith('Z') &&
DateTime.parse(value).isUtc &&
DateTime.parse(value).toIso8601String() == value
```

- [ ] **Step 6: Implement the codec**

Decode bytes with:

```dart
final source = utf8.decode(bytes, allowMalformed: false);
```

Catch only the UTF-8 `FormatException` and map it to `malformedUtf8`. Feed the resulting string to `LinuxSystemdRegistryJsonDecoder`.

Require exact key sets with a helper:

```dart
void _requireExactKeys(
  Map<String, Object?> object,
  Set<String> expected, {
  required String field,
})
```

Build `NotificationOwner` with `NotificationOwnerType.values.byName`, then build the validated entry model. Do not include decoded values in errors.

Encode with insertion-ordered Dart maps, sorted registry entries, `jsonEncode`, and:

```dart
utf8.encode('$encoded\n')
```

- [ ] **Step 7: Verify Gate 10.4.2**

```bash
dart format \
  lib/core/notifications/linux_systemd_registry_json_decoder.dart \
  lib/core/notifications/linux_systemd_schedule_registry_codec.dart \
  test/core/notifications/linux_systemd_registry_json_decoder_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_codec_test.dart

python3 tool/verify_phase1_task10_4_2_green.py

flutter test \
  test/core/notifications/linux_systemd_registry_json_decoder_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_codec_test.dart

flutter analyze
flutter test
flutter build linux --debug
git diff --check
```

- [ ] **Step 8: Commit Gate 10.4.2**

```bash
git add \
  lib/core/notifications/linux_systemd_registry_json_decoder.dart \
  lib/core/notifications/linux_systemd_schedule_registry_codec.dart \
  test/core/notifications/linux_systemd_registry_json_decoder_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_codec_test.dart \
  tool/verify_phase1_task10_4_2_green.py

git commit -m "feat: add strict Linux registry codec"
git push
```

---

# Gate 10.4.3 — Canonical Notification Request Fingerprint

**Files:**
- Create: `lib/core/notifications/linux_notification_request_fingerprint.dart`
- Test: `test/core/notifications/linux_notification_request_fingerprint_test.dart`
- Create: `tool/verify_phase1_task10_4_3_green.py`

**Interface:**

```dart
final class LinuxNotificationRequestFingerprint {
  const LinuxNotificationRequestFingerprint({
    int deliveryCommandSchemaVersion = 1,
  });

  Future<String> compute(NotificationRequest request) async;
}
```

- [ ] **Step 1: Write the fixed-vector RED test**

Use this request:

```dart
final request = NotificationRequest(
  scheduleId: 'task-42-reminder',
  owner: NotificationOwner(
    type: NotificationOwnerType.task,
    id: 'task-42',
  ),
  title: 'Pay rent',
  body: 'Due today',
  scheduledAtUtc: DateTime.parse('2026-07-30T05:30:00.000Z'),
  privacyMode: NotificationPrivacyMode.full,
  payload: const <String, String>{
    'z': '9',
    'a': '1',
  },
);
```

Expect this exact digest:

```text
f6ae7b7f35da4a7dfe74fc9144e726232ece9c67f130357d1ed39cef9ed51174
```

- [ ] **Step 2: Add sensitivity and determinism tests**

Verify the digest:

- is unchanged when payload insertion order changes;
- is unchanged across repeated calls;
- changes independently when schedule ID, owner type, owner ID, title, body, UTC time, privacy mode, payload key, payload value, or delivery-command schema version changes;
- is exactly 64 lowercase hex characters;
- does not expose title, body, or payload text.

- [ ] **Step 3: Run RED**

```bash
flutter test \
  test/core/notifications/linux_notification_request_fingerprint_test.dart
```

Expected: missing fingerprint class.

- [ ] **Step 4: Implement canonical JSON and SHA-256**

Construct fields in this exact order:

```dart
final canonical = jsonEncode(<String, Object>{
  'fingerprintSchemaVersion': 1,
  'deliveryCommandSchemaVersion': deliveryCommandSchemaVersion,
  'scheduleId': request.scheduleId,
  'ownerType': request.owner.type.name,
  'ownerId': request.owner.id,
  'title': request.title,
  'body': request.body,
  'scheduledAtUtc': request.scheduledAtUtc.toIso8601String(),
  'privacyMode': request.privacyMode.name,
  'payload': sortedPayload,
});
```

Hash with:

```dart
final digest = await Sha256().hash(utf8.encode(canonical));
return digest.bytes
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join();
```

Reject `deliveryCommandSchemaVersion <= 0` in the constructor.

- [ ] **Step 5: Verify and commit Gate 10.4.3**

```bash
dart format \
  lib/core/notifications/linux_notification_request_fingerprint.dart \
  test/core/notifications/linux_notification_request_fingerprint_test.dart

python3 tool/verify_phase1_task10_4_3_green.py

flutter test \
  test/core/notifications/linux_notification_request_fingerprint_test.dart

flutter analyze
git diff --check

git add \
  lib/core/notifications/linux_notification_request_fingerprint.dart \
  test/core/notifications/linux_notification_request_fingerprint_test.dart \
  tool/verify_phase1_task10_4_3_green.py

git commit -m "feat: fingerprint Linux notification requests"
git push
```

---

# Gate 10.4.4 — Registry Filesystem Extensions

**Files:**
- Modify: `lib/core/notifications/linux_systemd_file_system.dart`
- Modify: `lib/core/notifications/dart_io_linux_systemd_file_system.dart`
- Modify: `test/support/fake_linux_systemd_file_system.dart`
- Create: `test/core/notifications/linux_systemd_file_system_registry_extensions_test.dart`
- Create: `tool/verify_phase1_task10_4_4_green.py`

**Extended interface:**

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

- [ ] **Step 1: Write RED adapter tests**

Using `Directory.systemTemp`, verify:

```text
fileLength returns exact bytes for a regular file
fileLength rejects missing, directory, symlink, and special entries
listNames returns only direct child basenames
listNames returns names sorted ascending
listNames does not recurse
listNames does not follow a symlinked directory
listNames returns an empty list for a missing directory
listNames rejects a file, symlink, or special entry as the directory root
```

A direct child symlink name may appear in the returned names; the listing operation must not follow it. Callers validate the child with `typeOf`.

- [ ] **Step 2: Write RED fake-filesystem tests**

Seed nested paths and verify deterministic operation records:

```dart
expect(
  await fake.listNames('/config/systemd/user'),
  orderedEquals(<String>[
    'a.service',
    'b.timer',
    'nested',
  ]),
);

expect(
  fake.operations,
  contains('listNames:/config/systemd/user'),
);
```

Add injectable failure keys:

```text
fileLength:<path>
listNames:<directory>
```

- [ ] **Step 3: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_file_system_registry_extensions_test.dart
```

Expected: all implementers are missing the new interface members.

- [ ] **Step 4: Implement production methods**

`fileLength`:

```dart
final type = await typeOf(path);
if (type != LinuxSystemdEntryType.regularFile) {
  throw LinuxSystemdUnsafeEntryException(
    path: path,
    entryType: type,
    operation: 'read length from',
  );
}
return File(path).length();
```

`listNames`:

1. Inspect the root with `typeOf`.
2. Return `const <String>[]` when missing.
3. Reject every type except directory.
4. Use `Directory(directoryPath).list(followLinks: false)`.
5. Collect only direct entity basenames.
6. Sort ascending.
7. Never call recursive listing.

Extract basename without a new dependency:

```dart
String _baseName(String path) {
  final index = path.lastIndexOf('/');
  return index < 0 ? path : path.substring(index + 1);
}
```

- [ ] **Step 5: Implement fake methods**

The fake `listNames` must derive direct children from `_entries.keys` using the exact directory prefix and discard descendants containing another slash. It must return sorted unique names.

- [ ] **Step 6: Verify and commit Gate 10.4.4**

```bash
dart format \
  lib/core/notifications/linux_systemd_file_system.dart \
  lib/core/notifications/dart_io_linux_systemd_file_system.dart \
  test/support/fake_linux_systemd_file_system.dart \
  test/core/notifications/linux_systemd_file_system_registry_extensions_test.dart

python3 tool/verify_phase1_task10_4_4_green.py

flutter test \
  test/core/notifications/dart_io_linux_systemd_file_system_test.dart \
  test/core/notifications/linux_systemd_file_system_registry_extensions_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_install_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_rollback_test.dart \
  test/core/notifications/linux_systemd_user_unit_store_remove_test.dart

flutter analyze
flutter test
flutter build linux --debug
git diff --check

git add \
  lib/core/notifications/linux_systemd_file_system.dart \
  lib/core/notifications/dart_io_linux_systemd_file_system.dart \
  test/support/fake_linux_systemd_file_system.dart \
  test/core/notifications/linux_systemd_file_system_registry_extensions_test.dart \
  tool/verify_phase1_task10_4_4_green.py

git commit -m "feat: extend Linux systemd filesystem inventory"
git push
```

---

# Gate 10.4.5 — Registry Store Contract and Safe Load

**Files:**
- Create: `lib/core/notifications/linux_systemd_schedule_registry_store.dart`
- Create: `lib/core/notifications/linux_systemd_schedule_registry_file_store.dart`
- Test: `test/core/notifications/linux_systemd_schedule_registry_store_load_test.dart`
- Create: `tool/verify_phase1_task10_4_5_green.py`

**Interfaces:**

```dart
typedef LinuxSystemdRegistryTransactionIdFactory = String Function();

abstract interface class LinuxSystemdScheduleRegistryStore {
  Future<LinuxSystemdScheduleRegistry> load();
  Future<void> replace(LinuxSystemdScheduleRegistry next);
  Future<void> quarantineCorruptRegistry();
  Future<LinuxSystemdUnitDiscovery> discoverAppUnitPairs();
}
```

```dart
final class LinuxSystemdScheduleRegistryFileStore
    implements LinuxSystemdScheduleRegistryStore {
  LinuxSystemdScheduleRegistryFileStore({
    required LinuxSystemdUserUnitPathResolver pathResolver,
    required LinuxSystemdFileSystem fileSystem,
    required LinuxSystemdScheduleRegistryCodec codec,
    required LinuxSystemdRegistryTransactionIdFactory transactionIdFactory,
  });
}
```

Constants:

```dart
static const String registryFileName =
    'dashboard-shakhsi-notification-registry.json';
static const int registryFileMode = 0x180;
```

- [ ] **Step 1: Write RED tests for missing and valid load**

Verify missing registry:

```dart
final loaded = await store.load();

expect(loaded.schemaVersion, 1);
expect(loaded.generation, 0);
expect(loaded.entries, isEmpty);
```

Verify a valid file causes this operation order:

```text
typeOf:<registry>
fileLength:<registry>
read:<registry>
readMode:<registry>
```

The store must check length before reading bytes.

- [ ] **Step 2: Add load failure tests**

Cover:

```text
final path is a symlink
final path is a directory
final path is other/special
file length exactly 1 MiB
file length above 1 MiB without readBytes being called
mode is 0644 instead of 0600
codec reports malformed UTF-8
codec reports malformed JSON
codec reports unsupported version
filesystem fileLength/read/readMode failure
```

Require typed `LinuxSystemdScheduleRegistryException` with operation `load`, path set to the final registry path, and the most specific failure.

Do not include bytes, JSON text, title, body, or payload in `toString()`.

- [ ] **Step 3: Run RED**

```bash
flutter test \
  test/core/notifications/linux_systemd_schedule_registry_store_load_test.dart
```

Expected: missing store files.

- [ ] **Step 4: Implement safe load**

Path construction:

```dart
String get _directory => _pathResolver.resolve();
String get _registryPath => '$_directory/$registryFileName';
```

Algorithm:

```text
typeOf final
missing -> empty registry
non-regular -> unsafeRegistryPath
fileLength final
length > maximumFileBytes -> oversizedRegistry
readBytes final
readMode final
mode != 0600 -> insecureRegistryMode
codec.decodeBytes(bytes)
```

Wrap filesystem failures with operation `load` and preserve codec failure categories instead of collapsing all corruption into one enum.

- [ ] **Step 5: Verify and commit Gate 10.4.5**

```bash
dart format \
  lib/core/notifications/linux_systemd_schedule_registry_store.dart \
  lib/core/notifications/linux_systemd_schedule_registry_file_store.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_load_test.dart

python3 tool/verify_phase1_task10_4_5_green.py

flutter test \
  test/core/notifications/linux_systemd_schedule_registry_store_load_test.dart

flutter analyze
git diff --check

git add \
  lib/core/notifications/linux_systemd_schedule_registry_store.dart \
  lib/core/notifications/linux_systemd_schedule_registry_file_store.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_load_test.dart \
  tool/verify_phase1_task10_4_5_green.py

git commit -m "feat: load Linux schedule registry safely"
git push
```

---

# Gate 10.4.6 — Atomic Replace, Generation Transition, and Rollback

**Files:**
- Modify: `lib/core/notifications/linux_systemd_schedule_registry_file_store.dart`
- Test: `test/core/notifications/linux_systemd_schedule_registry_store_replace_test.dart`
- Create: `tool/verify_phase1_task10_4_6_green.py`

**Transaction paths:**

For transaction ID `txn-1`:

```text
<directory>/dashboard-shakhsi-notification-registry.json
<directory>/.dashboard-shakhsi-notification-registry.txn-1.tmp
<directory>/.dashboard-shakhsi-notification-registry.txn-1.bak
```

Transaction IDs accept only:

```text
^[A-Za-z0-9_-]{1,64}$
```

- [ ] **Step 1: Write RED success tests**

For missing previous registry and `next.generation == 1`, verify exact order:

```text
createDirectory:<directory>
typeOf:<final>
typeOf:<temp>
typeOf:<backup>
write:<temp>
chmod:<temp>:384
rename:<temp>-><final>
chmod:<final>:384
```

For existing generation `7` and `next.generation == 8`, verify:

```text
type/length/read/mode current
createDirectory
validate final/temp/backup
write temp
chmod temp 0600
rename final -> backup
rename temp -> final
chmod final 0600
delete backup
```

Assert canonical bytes and final mode `0x180`.

- [ ] **Step 2: Add generation and safety RED tests**

Reject:

```text
next generation is not current generation + 1
invalid transaction ID
temp already exists
backup already exists
final is symlink/directory/other
temp is symlink/directory/regular/other
backup is symlink/directory/regular/other
```

- [ ] **Step 3: Add one RED test for every failure step**

Inject failures at:

```text
createDirectory
typeOf final
typeOf temp
typeOf backup
write temp
chmod temp
rename final to backup
rename temp to final
chmod final
delete backup
```

For each case verify:

- previous bytes and mode are restored exactly;
- no transaction temp remains when cleanup succeeds;
- no backup remains when cleanup succeeds;
- the primary injected error is `exception.cause`;
- operation is `replace`;
- failure is `atomicReplacementFailed`.

- [ ] **Step 4: Add rollback-failure aggregation tests**

Example:

1. Inject primary failure on `chmod:<final>:384`.
2. Inject rollback failure on `rename:<backup>-><final>`.
3. Verify primary cause remains the chmod error.
4. Verify one rollback failure with step `restore-registry-backup`.
5. Verify `toString()` contains only operation, failure, path, and rollback count.

- [ ] **Step 5: Implement replacement state machine**

Use explicit state:

```dart
final class _RegistryReplaceState {
  bool tempExists = false;
  bool backupExists = false;
  bool newFinalExists = false;
}
```

Before mutation:

- call `load()` to validate current state and generation;
- encode next before touching disk;
- validate transaction ID;
- create directory;
- validate final as missing or regular;
- require temp and backup missing.

Rollback order:

```text
delete new final
restore backup by rename
if backup rename fails, rewrite previous snapshot and chmod previous mode
delete temp
delete leftover backup after successful snapshot restore
```

Keep helper:

```dart
Future<bool> _attemptRollback({
  required String step,
  required Future<void> Function() action,
  required List<LinuxSystemdRegistryRollbackFailure> failures,
})
```

- [ ] **Step 6: Verify Gate 10.4.6**

```bash
dart format \
  lib/core/notifications/linux_systemd_schedule_registry_file_store.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_replace_test.dart

python3 tool/verify_phase1_task10_4_6_green.py

flutter test \
  test/core/notifications/linux_systemd_schedule_registry_store_load_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_replace_test.dart

flutter analyze
flutter test
flutter build linux --debug
git diff --check
```

- [ ] **Step 7: Commit Gate 10.4.6**

```bash
git add \
  lib/core/notifications/linux_systemd_schedule_registry_file_store.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_replace_test.dart \
  tool/verify_phase1_task10_4_6_green.py

git commit -m "feat: replace Linux schedule registry atomically"
git push
```

---

# Gate 10.4.7 — Corrupt Registry Quarantine and App Unit Discovery

**Files:**
- Modify: `lib/core/notifications/linux_systemd_schedule_registry_file_store.dart`
- Test: `test/core/notifications/linux_systemd_schedule_registry_store_recovery_test.dart`
- Create: `tool/verify_phase1_task10_4_7_green.py`

**Quarantine path:**

```text
<directory>/.dashboard-shakhsi-notification-registry.<transaction-id>.corrupt
```

- [ ] **Step 1: Write quarantine RED tests**

Cover:

```text
missing registry is idempotent
regular registry is renamed byte-for-byte
quarantine destination must be missing
registry symlink is rejected
registry directory is rejected
registry special entry is rejected
invalid transaction ID is rejected
rename failure is typed quarantineFailed
existing quarantine file is never overwritten
```

Verify quarantine does not decode the bytes and does not call `deleteFile`.

- [ ] **Step 2: Write exact discovery RED tests**

Seed direct children:

```text
dashboard-shakhsi-notification-aaaaaaaaaaaaaaaa.service
dashboard-shakhsi-notification-aaaaaaaaaaaaaaaa.timer
dashboard-shakhsi-notification-bbbbbbbbbbbbbbbb.service
unrelated.service
dashboard-shakhsi-notification-CCCCCCCCCCCCCCCC.timer
dashboard-shakhsi-notification-cccc.timer
.dashboard-shakhsi-notification-registry.txn.tmp
nested/dashboard-shakhsi-notification-dddddddddddddddd.timer
```

Expected:

- one complete `aaaaaaaaaaaaaaaa` pair;
- one partial `bbbbbbbbbbbbbbbb` service-only pair;
- unrelated, uppercase, short, transaction, and nested names ignored.

- [ ] **Step 3: Add unsafe matched-path tests**

If an exact app-owned matched service or timer name is a symlink, directory, or special entry, discovery must throw `unsafeAppUnitPath`.

An unrelated symlink must be ignored because it is outside the exact app-owned pattern.

- [ ] **Step 4: Add deterministic and failure tests**

Verify:

- complete pairs sorted by base name;
- partial pairs sorted by base name;
- `listNames` called exactly once;
- each exact matched name inspected exactly once with `typeOf`;
- a listing failure maps to `discoveryFailed`;
- a child inspection failure preserves the path.

- [ ] **Step 5: Implement quarantine and one-pass discovery**

Use exact patterns:

```dart
static final RegExp _servicePattern = RegExp(
  r'^(dashboard-shakhsi-notification-[0-9a-f]{16})\.service$',
);
static final RegExp _timerPattern = RegExp(
  r'^(dashboard-shakhsi-notification-[0-9a-f]{16})\.timer$',
);
```

Group with a sorted map keyed by base name. After validation:

```dart
if (hasService && hasTimer) {
  complete.add(LinuxSystemdUnitNames.parseBaseName(baseName));
} else {
  partial.add(
    LinuxSystemdPartialUnitPair(
      baseName: baseName,
      hasService: hasService,
      hasTimer: hasTimer,
    ),
  );
}
```

- [ ] **Step 6: Verify and commit Gate 10.4.7**

```bash
dart format \
  lib/core/notifications/linux_systemd_schedule_registry_file_store.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_recovery_test.dart

python3 tool/verify_phase1_task10_4_7_green.py

flutter test \
  test/core/notifications/linux_systemd_schedule_registry_store_load_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_replace_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_recovery_test.dart

flutter analyze
flutter test
flutter build linux --debug
git diff --check

git add \
  lib/core/notifications/linux_systemd_schedule_registry_file_store.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_recovery_test.dart \
  tool/verify_phase1_task10_4_7_green.py

git commit -m "feat: recover Linux schedule registry inventory"
git push
```

---

# Gate 10.4.8 — Final Task 10.4 Checkpoint

**Files:**
- Create: `test/core/notifications/linux_systemd_schedule_registry_final_checkpoint_test.dart`
- Create: `tool/verify_phase1_task10_4_complete.py`
- Create: `docs/superpowers/checkpoints/2026-07-29-linux-systemd-schedule-registry-checkpoint.md`
- Modify: `docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md`

- [ ] **Step 1: Add a fake-filesystem lifecycle checkpoint**

One test must perform:

```text
load missing generation 0
replace generation 1 with one entry
load exact generation 1
replace generation 2 with changed fingerprint
load exact generation 2
discover one complete pair and one partial pair
quarantine deliberately corrupt registry
verify corrupt bytes preserved
load after quarantine returns empty generation 0
```

The test must assert no registry bytes contain title, body, or payload values.

- [ ] **Step 2: Add a real temporary-directory adapter checkpoint**

Using `Directory.systemTemp` only:

```text
create registry through file store
verify final mode 0600
load exact model
list exact direct unit names
verify symlinked exact app-owned unit is rejected
```

Skip this test when `!Platform.isLinux` with a clear reason. Never use the actual HOME or XDG directory; inject a resolver backed by a temporary absolute XDG path.

- [ ] **Step 3: Add the completion verifier**

`tool/verify_phase1_task10_4_complete.py` checks:

```text
all new production files exist
all Task 10.4 tests exist
strict decoder rejects duplicate keys
codec contains 1 MiB and 10,000 constants
fingerprint uses Sha256
filesystem exposes fileLength and listNames
store final filename and mode are exact
store contains load, replace, quarantine, and discover
no Task 10.4 production file imports process runner or systemctl driver
no title/body/payload field exists in registry model
```

- [ ] **Step 4: Write the checkpoint document**

Record:

- eight Gate commit hashes;
- focused and full test counts;
- analyze result;
- Linux build result;
- exact final interfaces;
- durability boundary: no cross-resource power-loss atomicity claim;
- deferred Task 10.5 scheduler integration.

Change only Task 10.4 status in the design spec to `Implemented`; leave Tasks 10.5 and 10.6 pending.

- [ ] **Step 5: Run final verification**

```bash
python3 tool/verify_phase1_task10_4_complete.py

flutter test \
  test/core/notifications/linux_systemd_schedule_registry_model_test.dart \
  test/core/notifications/linux_systemd_registry_json_decoder_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_codec_test.dart \
  test/core/notifications/linux_notification_request_fingerprint_test.dart \
  test/core/notifications/linux_systemd_file_system_registry_extensions_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_load_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_replace_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_store_recovery_test.dart \
  test/core/notifications/linux_systemd_schedule_registry_final_checkpoint_test.dart

flutter analyze
flutter test
flutter build linux --debug
git diff --check
git status --short
```

Expected:

```text
Task 10.4 focused tests: all pass
Full project tests: all pass
Analyze: No issues found
Linux debug build: succeeds
Completion verifier: OK
git diff --check: no output
```

- [ ] **Step 6: Commit final checkpoint**

```bash
git add \
  test/core/notifications/linux_systemd_schedule_registry_final_checkpoint_test.dart \
  tool/verify_phase1_task10_4_complete.py \
  docs/superpowers/checkpoints/2026-07-29-linux-systemd-schedule-registry-checkpoint.md \
  docs/superpowers/specs/2026-07-29-linux-systemd-notification-pipeline-design.md

git commit -m "test: checkpoint Linux schedule registry"
git push
```

---

## Self-Review Results

### Spec coverage

- Versioned immutable registry: Gate 10.4.1
- Strict duplicate-aware JSON and canonical encoding: Gate 10.4.2
- SHA-256 privacy-preserving fingerprint: Gate 10.4.3
- `fileLength` and `listNames`: Gate 10.4.4
- Missing, valid, unsafe, oversized, corrupt, and insecure-mode load behavior: Gate 10.4.5
- Atomic replacement, generation transition, full rollback, and primary-error preservation: Gate 10.4.6
- Corrupt quarantine, exact complete/partial discovery, and symlink safety: Gate 10.4.7
- Fake-only lifecycle, temporary-directory adapter verification, docs, and final checkpoint: Gate 10.4.8

No Task 10.5 scheduler behavior and no Task 10.6 delivery-entrypoint behavior is included.

### Placeholder scan

The plan contains no placeholders, deferred implementation instructions, unspecified error handling, or unnamed test requirements.

### Type consistency

- Store interface and implementation use the same four method signatures.
- Discovery returns one `LinuxSystemdUnitDiscovery` containing complete and partial sets.
- Fingerprint returns `Future<String>`.
- Codec exchanges registry models and UTF-8 byte lists.
- Filesystem extensions are implemented by both production and fake adapters.
- Every later Gate consumes names and types defined in an earlier Gate.
