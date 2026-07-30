import 'dart:collection';

import 'linux_systemd_notification_unit.dart';
import 'linux_systemd_schedule_registry_exception.dart';
import 'linux_systemd_timer_name.dart';
import 'notification_owner.dart';

final class LinuxSystemdScheduleRegistryEntry {
  factory LinuxSystemdScheduleRegistryEntry({
    required String scheduleId,
    required NotificationOwner owner,
    required LinuxSystemdTimerName timerName,
    required String serviceFileName,
    required DateTime scheduledAtUtc,
    required String requestFingerprint,
  }) {
    final normalizedScheduleId = scheduleId.trim();

    if (normalizedScheduleId.isEmpty || normalizedScheduleId != scheduleId) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.invalidScheduleId,
        field: 'scheduleId',
      );
    }

    if (!scheduledAtUtc.isUtc) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.invalidTimestamp,
        field: 'scheduledAtUtc',
      );
    }

    if (!_fingerprintPattern.hasMatch(requestFingerprint)) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.invalidFingerprint,
        field: 'requestFingerprint',
      );
    }

    final expected = LinuxSystemdUnitNames.forScheduleKey(normalizedScheduleId);

    if (timerName.value != expected.timerFileName) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
        field: 'timerName',
      );
    }

    if (serviceFileName != expected.serviceFileName) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
        field: 'serviceFileName',
      );
    }

    return LinuxSystemdScheduleRegistryEntry._(
      scheduleId: normalizedScheduleId,
      owner: owner,
      timerName: timerName,
      serviceFileName: serviceFileName,
      scheduledAtUtc: scheduledAtUtc,
      requestFingerprint: requestFingerprint,
    );
  }

  const LinuxSystemdScheduleRegistryEntry._({
    required this.scheduleId,
    required this.owner,
    required this.timerName,
    required this.serviceFileName,
    required this.scheduledAtUtc,
    required this.requestFingerprint,
  });

  static final RegExp _fingerprintPattern = RegExp(r'^[0-9a-f]{64}$');

  final String scheduleId;
  final NotificationOwner owner;
  final LinuxSystemdTimerName timerName;
  final String serviceFileName;
  final DateTime scheduledAtUtc;
  final String requestFingerprint;

  @override
  bool operator ==(Object other) {
    return other is LinuxSystemdScheduleRegistryEntry &&
        other.scheduleId == scheduleId &&
        other.owner == owner &&
        other.timerName == timerName &&
        other.serviceFileName == serviceFileName &&
        other.scheduledAtUtc == scheduledAtUtc &&
        other.requestFingerprint == requestFingerprint;
  }

  @override
  int get hashCode {
    return Object.hash(
      scheduleId,
      owner,
      timerName,
      serviceFileName,
      scheduledAtUtc,
      requestFingerprint,
    );
  }
}

final class LinuxSystemdScheduleRegistry {
  factory LinuxSystemdScheduleRegistry({
    required int schemaVersion,
    required int generation,
    required Iterable<LinuxSystemdScheduleRegistryEntry> entries,
  }) {
    if (schemaVersion != currentSchemaVersion) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.unsupportedSchemaVersion,
        field: 'schemaVersion',
      );
    }

    if (generation < 0) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.invalidGeneration,
        field: 'generation',
      );
    }

    final sortedEntries = entries.toList()
      ..sort((first, second) => first.scheduleId.compareTo(second.scheduleId));
    final scheduleIds = <String>{};
    final timerNames = <String>{};
    final serviceNames = <String>{};

    for (final entry in sortedEntries) {
      if (!scheduleIds.add(entry.scheduleId)) {
        throw LinuxSystemdScheduleRegistryException(
          operation: LinuxSystemdScheduleRegistryOperation.validate,
          failure: LinuxSystemdScheduleRegistryFailure.duplicateScheduleId,
          field: 'scheduleId',
        );
      }

      if (!timerNames.add(entry.timerName.value)) {
        throw LinuxSystemdScheduleRegistryException(
          operation: LinuxSystemdScheduleRegistryOperation.validate,
          failure: LinuxSystemdScheduleRegistryFailure.duplicateTimerName,
          field: 'timerName',
        );
      }

      if (!serviceNames.add(entry.serviceFileName)) {
        throw LinuxSystemdScheduleRegistryException(
          operation: LinuxSystemdScheduleRegistryOperation.validate,
          failure: LinuxSystemdScheduleRegistryFailure.duplicateServiceName,
          field: 'serviceFileName',
        );
      }
    }

    return LinuxSystemdScheduleRegistry._(
      schemaVersion: schemaVersion,
      generation: generation,
      entries: List<LinuxSystemdScheduleRegistryEntry>.unmodifiable(
        sortedEntries,
      ),
    );
  }

  const LinuxSystemdScheduleRegistry._({
    required this.schemaVersion,
    required this.generation,
    required this.entries,
  });

  factory LinuxSystemdScheduleRegistry.empty() {
    return LinuxSystemdScheduleRegistry(
      schemaVersion: currentSchemaVersion,
      generation: 0,
      entries: const <LinuxSystemdScheduleRegistryEntry>[],
    );
  }

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final int generation;
  final List<LinuxSystemdScheduleRegistryEntry> entries;

  LinuxSystemdScheduleRegistryEntry? entryForScheduleId(String scheduleId) {
    for (final entry in entries) {
      if (entry.scheduleId == scheduleId) {
        return entry;
      }
    }

    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is LinuxSystemdScheduleRegistry &&
        other.schemaVersion == schemaVersion &&
        other.generation == generation &&
        _iterableEquals(other.entries, entries);
  }

  @override
  int get hashCode {
    return Object.hash(schemaVersion, generation, Object.hashAll(entries));
  }
}

final class LinuxSystemdPartialUnitPair {
  factory LinuxSystemdPartialUnitPair({
    required String baseName,
    required bool hasService,
    required bool hasTimer,
  }) {
    LinuxSystemdUnitNames.parseBaseName(baseName);

    if (hasService == hasTimer) {
      throw LinuxSystemdScheduleRegistryException(
        operation: LinuxSystemdScheduleRegistryOperation.validate,
        failure: LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
        field: 'unitPair',
      );
    }

    return LinuxSystemdPartialUnitPair._(
      baseName: baseName,
      hasService: hasService,
      hasTimer: hasTimer,
    );
  }

  const LinuxSystemdPartialUnitPair._({
    required this.baseName,
    required this.hasService,
    required this.hasTimer,
  });

  final String baseName;
  final bool hasService;
  final bool hasTimer;

  @override
  bool operator ==(Object other) {
    return other is LinuxSystemdPartialUnitPair &&
        other.baseName == baseName &&
        other.hasService == hasService &&
        other.hasTimer == hasTimer;
  }

  @override
  int get hashCode => Object.hash(baseName, hasService, hasTimer);
}

final class LinuxSystemdUnitDiscovery {
  factory LinuxSystemdUnitDiscovery({
    required Iterable<LinuxSystemdUnitNames> completePairs,
    required Iterable<LinuxSystemdPartialUnitPair> partialPairs,
  }) {
    final sortedComplete = completePairs.toSet().toList()
      ..sort((first, second) => first.baseName.compareTo(second.baseName));
    final sortedPartial = partialPairs.toSet().toList()
      ..sort((first, second) => first.baseName.compareTo(second.baseName));
    final completeBaseNames = sortedComplete
        .map((item) => item.baseName)
        .toSet();

    for (final partial in sortedPartial) {
      if (completeBaseNames.contains(partial.baseName)) {
        throw LinuxSystemdScheduleRegistryException(
          operation: LinuxSystemdScheduleRegistryOperation.validate,
          failure: LinuxSystemdScheduleRegistryFailure.invalidUnitIdentity,
          field: 'unitPair',
        );
      }
    }

    return LinuxSystemdUnitDiscovery._(
      completePairs: Set<LinuxSystemdUnitNames>.unmodifiable(
        LinkedHashSet<LinuxSystemdUnitNames>.from(sortedComplete),
      ),
      partialPairs: Set<LinuxSystemdPartialUnitPair>.unmodifiable(
        LinkedHashSet<LinuxSystemdPartialUnitPair>.from(sortedPartial),
      ),
    );
  }

  const LinuxSystemdUnitDiscovery._({
    required this.completePairs,
    required this.partialPairs,
  });

  final Set<LinuxSystemdUnitNames> completePairs;
  final Set<LinuxSystemdPartialUnitPair> partialPairs;

  @override
  bool operator ==(Object other) {
    return other is LinuxSystemdUnitDiscovery &&
        _iterableEquals(other.completePairs, completePairs) &&
        _iterableEquals(other.partialPairs, partialPairs);
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(completePairs),
      Object.hashAll(partialPairs),
    );
  }
}

bool _iterableEquals<T>(Iterable<T> first, Iterable<T> second) {
  final firstIterator = first.iterator;
  final secondIterator = second.iterator;

  while (true) {
    final firstMoved = firstIterator.moveNext();
    final secondMoved = secondIterator.moveNext();

    if (firstMoved != secondMoved) {
      return false;
    }

    if (!firstMoved) {
      return true;
    }

    if (firstIterator.current != secondIterator.current) {
      return false;
    }
  }
}
