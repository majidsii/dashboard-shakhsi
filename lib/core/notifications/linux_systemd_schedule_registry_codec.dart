import 'dart:convert';

import 'linux_systemd_registry_json_decoder.dart';
import 'linux_systemd_schedule_registry.dart';
import 'linux_systemd_schedule_registry_exception.dart';
import 'linux_systemd_timer_name.dart';
import 'notification_owner.dart';

final class LinuxSystemdScheduleRegistryCodec {
  const LinuxSystemdScheduleRegistryCodec({
    this.jsonDecoder = const LinuxSystemdRegistryJsonDecoder(),
  });

  static const int maximumFileBytes = 1 << 20;
  static const int maximumEntries = 10000;

  static const Set<String> _topLevelKeys = <String>{
    'schemaVersion',
    'generation',
    'entries',
  };

  static const Set<String> _entryKeys = <String>{
    'scheduleId',
    'ownerType',
    'ownerId',
    'timerName',
    'serviceFileName',
    'scheduledAtUtc',
    'requestFingerprint',
  };

  final LinuxSystemdRegistryJsonDecoder jsonDecoder;

  LinuxSystemdScheduleRegistry decodeBytes(List<int> bytes) {
    if (bytes.length > maximumFileBytes) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.decode,
        failure: LinuxSystemdScheduleRegistryFailure.oversizedRegistry,
      );
    }

    late final String source;

    try {
      source = utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (error, stackTrace) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.decode,
        failure: LinuxSystemdScheduleRegistryFailure.malformedUtf8,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }

    final decoded = jsonDecoder.decode(source);
    if (decoded is! Map<String, Object?>) {
      _malformed(field: 'registry');
    }

    _requireExactKeys(decoded, _topLevelKeys, field: 'registry');

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int) {
      _malformed(field: 'schemaVersion');
    }

    if (schemaVersion != LinuxSystemdScheduleRegistry.currentSchemaVersion) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.decode,
        failure: LinuxSystemdScheduleRegistryFailure.unsupportedSchemaVersion,
        field: 'schemaVersion',
      );
    }

    final generation = decoded['generation'];
    if (generation is! int) {
      _malformed(field: 'generation');
    }

    if (generation < 0) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.decode,
        failure: LinuxSystemdScheduleRegistryFailure.invalidGeneration,
        field: 'generation',
      );
    }

    final encodedEntries = decoded['entries'];
    if (encodedEntries is! List<Object?>) {
      _malformed(field: 'entries');
    }

    if (encodedEntries.length > maximumEntries) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.decode,
        failure: LinuxSystemdScheduleRegistryFailure.excessiveEntryCount,
        field: 'entries',
      );
    }

    final entries = <LinuxSystemdScheduleRegistryEntry>[];

    for (var index = 0; index < encodedEntries.length; index += 1) {
      entries.add(
        _decodeEntry(encodedEntries[index], field: 'entries[$index]'),
      );
    }

    try {
      return LinuxSystemdScheduleRegistry(
        schemaVersion: schemaVersion,
        generation: generation,
        entries: entries,
      );
    } on LinuxSystemdScheduleRegistryException catch (error, stackTrace) {
      _rethrowAsDecode(error, stackTrace);
    }
  }

  List<int> encodeBytes(LinuxSystemdScheduleRegistry registry) {
    if (registry.entries.length > maximumEntries) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.excessiveEntryCount,
        field: 'entries',
      );
    }

    final encoded = jsonEncode(<String, Object?>{
      'schemaVersion': registry.schemaVersion,
      'generation': registry.generation,
      'entries': registry.entries
          .map(
            (entry) => <String, Object?>{
              'scheduleId': entry.scheduleId,
              'ownerType': entry.owner.type.name,
              'ownerId': entry.owner.id,
              'timerName': entry.timerName.value,
              'serviceFileName': entry.serviceFileName,
              'scheduledAtUtc': entry.scheduledAtUtc.toIso8601String(),
              'requestFingerprint': entry.requestFingerprint,
            },
          )
          .toList(growable: false),
    });
    final bytes = utf8.encode('$encoded\n');

    if (bytes.length > maximumFileBytes) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.oversizedRegistry,
      );
    }

    return List<int>.unmodifiable(bytes);
  }

  LinuxSystemdScheduleRegistryEntry _decodeEntry(
    Object? encoded, {
    required String field,
  }) {
    if (encoded is! Map<String, Object?>) {
      _malformed(field: field);
    }

    _requireExactKeys(encoded, _entryKeys, field: field);

    final scheduleId = _requireString(
      encoded,
      'scheduleId',
      parentField: field,
    );
    final ownerTypeValue = _requireString(
      encoded,
      'ownerType',
      parentField: field,
    );
    final ownerId = _requireString(encoded, 'ownerId', parentField: field);
    final timerNameValue = _requireString(
      encoded,
      'timerName',
      parentField: field,
    );
    final serviceFileName = _requireString(
      encoded,
      'serviceFileName',
      parentField: field,
    );
    final scheduledAtUtcValue = _requireString(
      encoded,
      'scheduledAtUtc',
      parentField: field,
    );
    final requestFingerprint = _requireString(
      encoded,
      'requestFingerprint',
      parentField: field,
    );

    final ownerType = _parseOwnerType(ownerTypeValue);

    if (ownerId.isEmpty || ownerId.trim() != ownerId) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.decode,
        failure: LinuxSystemdScheduleRegistryFailure.invalidOwner,
        field: 'ownerId',
      );
    }

    final owner = NotificationOwner(type: ownerType, id: ownerId);
    final scheduledAtUtc = _parseCanonicalUtc(scheduledAtUtcValue);
    final timerName = _parseTimerName(timerNameValue);

    try {
      return LinuxSystemdScheduleRegistryEntry(
        scheduleId: scheduleId,
        owner: owner,
        timerName: timerName,
        serviceFileName: serviceFileName,
        scheduledAtUtc: scheduledAtUtc,
        requestFingerprint: requestFingerprint,
      );
    } on LinuxSystemdScheduleRegistryException catch (error, stackTrace) {
      _rethrowAsDecode(error, stackTrace);
    }
  }

  NotificationOwnerType _parseOwnerType(String value) {
    for (final type in NotificationOwnerType.values) {
      if (type.name == value) {
        return type;
      }
    }

    throw LinuxSystemdScheduleRegistryException(
      operation: LinuxSystemdScheduleRegistryOperation.decode,
      failure: LinuxSystemdScheduleRegistryFailure.invalidOwner,
      field: 'ownerType',
    );
  }

  DateTime _parseCanonicalUtc(String value) {
    if (!value.endsWith('Z')) {
      _invalidTimestamp();
    }

    late final DateTime parsed;

    try {
      parsed = DateTime.parse(value);
    } on FormatException {
      _invalidTimestamp();
    }

    if (!parsed.isUtc || parsed.toIso8601String() != value) {
      _invalidTimestamp();
    }

    return parsed;
  }

  LinuxSystemdTimerName _parseTimerName(String value) {
    try {
      return LinuxSystemdTimerName.parse(value);
    } on FormatException catch (error, stackTrace) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.decode,
        failure: LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
        field: 'timerName',
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  void _requireExactKeys(
    Map<String, Object?> object,
    Set<String> expected, {
    required String field,
  }) {
    if (object.length != expected.length ||
        !expected.every(object.containsKey)) {
      _malformed(field: field);
    }
  }

  String _requireString(
    Map<String, Object?> object,
    String key, {
    required String parentField,
  }) {
    final value = object[key];

    if (value is! String) {
      _malformed(field: '$parentField.$key');
    }

    return value;
  }

  Never _invalidTimestamp() {
    throw LinuxSystemdScheduleRegistryException(
      operation: LinuxSystemdScheduleRegistryOperation.decode,
      failure: LinuxSystemdScheduleRegistryFailure.invalidTimestamp,
      field: 'scheduledAtUtc',
    );
  }

  Never _malformed({required String field}) {
    throw LinuxSystemdScheduleRegistryException(
      operation: LinuxSystemdScheduleRegistryOperation.decode,
      failure: LinuxSystemdScheduleRegistryFailure.malformedJson,
      field: field,
    );
  }

  Never _rethrowAsDecode(
    LinuxSystemdScheduleRegistryException error,
    StackTrace stackTrace,
  ) {
    if (error.operation == LinuxSystemdScheduleRegistryOperation.decode) {
      Error.throwWithStackTrace(error, stackTrace);
    }

    throw LinuxSystemdScheduleRegistryException(
      operation: LinuxSystemdScheduleRegistryOperation.decode,
      failure: error.failure,
      path: error.path,
      field: error.field,
      cause: error,
      causeStackTrace: stackTrace,
      rollbackFailures: error.rollbackFailures,
    );
  }
}
