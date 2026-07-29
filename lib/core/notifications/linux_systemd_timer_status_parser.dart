import 'linux_systemd_timer_name.dart';
import 'linux_systemd_timer_status.dart';

enum LinuxSystemdTimerStatusParseFailure {
  emptyOutput,
  controlCharacter,
  malformedLine,
  unknownProperty,
  duplicateProperty,
  missingProperty,
  invalidTimerName,
  unexpectedTimerName,
  invalidValue,
}

final class LinuxSystemdTimerStatusParseException implements Exception {
  const LinuxSystemdTimerStatusParseException({
    required this.failure,
    required this.message,
    this.property,
    this.value,
    this.lineNumber,
  });

  final LinuxSystemdTimerStatusParseFailure failure;
  final String message;
  final String? property;
  final String? value;
  final int? lineNumber;

  @override
  String toString() {
    final details = <String>[
      if (property != null) 'property=$property',
      if (value != null) 'value=$value',
      if (lineNumber != null) 'line=$lineNumber',
    ];

    return details.isEmpty
        ? 'LinuxSystemdTimerStatusParseException: $message'
        : 'LinuxSystemdTimerStatusParseException: '
              '$message (${details.join(', ')})';
  }
}

final class LinuxSystemdTimerStatusParser {
  const LinuxSystemdTimerStatusParser();

  static const Set<String> _requiredProperties = <String>{
    'Id',
    'LoadState',
    'ActiveState',
    'SubState',
    'UnitFileState',
    'Result',
  };

  LinuxSystemdTimerStatus parse({
    required LinuxSystemdTimerName expectedName,
    required String output,
  }) {
    if (output.isEmpty) {
      throw const LinuxSystemdTimerStatusParseException(
        failure: LinuxSystemdTimerStatusParseFailure.emptyOutput,
        message: 'systemctl show output is empty.',
      );
    }

    if (_containsForbiddenControlCharacter(output)) {
      throw const LinuxSystemdTimerStatusParseException(
        failure: LinuxSystemdTimerStatusParseFailure.controlCharacter,
        message: 'systemctl show output contains a control character.',
      );
    }

    final normalized = output.replaceAll('\r\n', '\n');

    if (normalized.contains('\r')) {
      throw const LinuxSystemdTimerStatusParseException(
        failure: LinuxSystemdTimerStatusParseFailure.controlCharacter,
        message: 'systemctl show output contains an invalid carriage return.',
      );
    }

    final lines = normalized.split('\n');

    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }

    if (lines.isEmpty) {
      throw const LinuxSystemdTimerStatusParseException(
        failure: LinuxSystemdTimerStatusParseFailure.emptyOutput,
        message: 'systemctl show output is empty.',
      );
    }

    final properties = <String, String>{};

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final lineNumber = index + 1;

      if (line.isEmpty) {
        throw LinuxSystemdTimerStatusParseException(
          failure: LinuxSystemdTimerStatusParseFailure.malformedLine,
          message: 'Blank lines are not allowed.',
          lineNumber: lineNumber,
        );
      }

      final delimiterIndex = line.indexOf('=');

      if (delimiterIndex <= 0) {
        throw LinuxSystemdTimerStatusParseException(
          failure: LinuxSystemdTimerStatusParseFailure.malformedLine,
          message: 'Expected a key=value line.',
          property: line,
          lineNumber: lineNumber,
        );
      }

      final key = line.substring(0, delimiterIndex);
      final value = line.substring(delimiterIndex + 1);

      if (!_requiredProperties.contains(key)) {
        throw LinuxSystemdTimerStatusParseException(
          failure: LinuxSystemdTimerStatusParseFailure.unknownProperty,
          message: 'Unexpected systemctl property.',
          property: key,
          value: value,
          lineNumber: lineNumber,
        );
      }

      if (properties.containsKey(key)) {
        throw LinuxSystemdTimerStatusParseException(
          failure: LinuxSystemdTimerStatusParseFailure.duplicateProperty,
          message: 'Duplicate systemctl property.',
          property: key,
          value: value,
          lineNumber: lineNumber,
        );
      }

      if (value.isEmpty || value.trim() != value) {
        throw LinuxSystemdTimerStatusParseException(
          failure: LinuxSystemdTimerStatusParseFailure.invalidValue,
          message: 'Property values must be non-empty and exact.',
          property: key,
          value: value,
          lineNumber: lineNumber,
        );
      }

      properties[key] = value;
    }

    for (final property in _requiredProperties) {
      if (!properties.containsKey(property)) {
        throw LinuxSystemdTimerStatusParseException(
          failure: LinuxSystemdTimerStatusParseFailure.missingProperty,
          message: 'Required systemctl property is missing.',
          property: property,
        );
      }
    }

    late final LinuxSystemdTimerName parsedName;

    try {
      parsedName = LinuxSystemdTimerName.parse(properties['Id']!);
    } on FormatException {
      throw LinuxSystemdTimerStatusParseException(
        failure: LinuxSystemdTimerStatusParseFailure.invalidTimerName,
        message: 'The Id property is not an app-generated timer name.',
        property: 'Id',
        value: properties['Id'],
      );
    }

    if (parsedName != expectedName) {
      throw LinuxSystemdTimerStatusParseException(
        failure: LinuxSystemdTimerStatusParseFailure.unexpectedTimerName,
        message: 'The Id property does not match the requested timer.',
        property: 'Id',
        value: parsedName.value,
      );
    }

    return LinuxSystemdTimerStatus(
      name: parsedName,
      loadState: _parseLoadState(properties['LoadState']!),
      activeState: _parseActiveState(properties['ActiveState']!),
      subState: _parseSubState(properties['SubState']!),
      unitFileState: _parseUnitFileState(properties['UnitFileState']!),
      result: _parseResult(properties['Result']!),
    );
  }

  static bool _containsForbiddenControlCharacter(String value) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit == 0 ||
          codeUnit == 0x7f ||
          (codeUnit < 0x20 &&
              codeUnit != 0x09 &&
              codeUnit != 0x0a &&
              codeUnit != 0x0d)) {
        return true;
      }
    }

    return false;
  }

  static LinuxSystemdLoadState _parseLoadState(String value) {
    return switch (value) {
      'loaded' => LinuxSystemdLoadState.loaded,
      'not-found' => LinuxSystemdLoadState.notFound,
      'masked' => LinuxSystemdLoadState.masked,
      'error' => LinuxSystemdLoadState.error,
      'bad-setting' => LinuxSystemdLoadState.badSetting,
      'stub' => LinuxSystemdLoadState.stub,
      'merged' => LinuxSystemdLoadState.merged,
      _ => _invalidValue('LoadState', value),
    };
  }

  static LinuxSystemdActiveState _parseActiveState(String value) {
    return switch (value) {
      'active' => LinuxSystemdActiveState.active,
      'reloading' => LinuxSystemdActiveState.reloading,
      'inactive' => LinuxSystemdActiveState.inactive,
      'failed' => LinuxSystemdActiveState.failed,
      'activating' => LinuxSystemdActiveState.activating,
      'deactivating' => LinuxSystemdActiveState.deactivating,
      'maintenance' => LinuxSystemdActiveState.maintenance,
      'refreshing' => LinuxSystemdActiveState.refreshing,
      _ => _invalidValue('ActiveState', value),
    };
  }

  static LinuxSystemdTimerSubState _parseSubState(String value) {
    return switch (value) {
      'dead' => LinuxSystemdTimerSubState.dead,
      'waiting' => LinuxSystemdTimerSubState.waiting,
      'running' => LinuxSystemdTimerSubState.running,
      'elapsed' => LinuxSystemdTimerSubState.elapsed,
      'failed' => LinuxSystemdTimerSubState.failed,
      _ => _invalidValue('SubState', value),
    };
  }

  static LinuxSystemdUnitFileState _parseUnitFileState(String value) {
    return switch (value) {
      'enabled' => LinuxSystemdUnitFileState.enabled,
      'enabled-runtime' => LinuxSystemdUnitFileState.enabledRuntime,
      'linked' => LinuxSystemdUnitFileState.linked,
      'linked-runtime' => LinuxSystemdUnitFileState.linkedRuntime,
      'alias' => LinuxSystemdUnitFileState.alias,
      'masked' => LinuxSystemdUnitFileState.masked,
      'masked-runtime' => LinuxSystemdUnitFileState.maskedRuntime,
      'static' => LinuxSystemdUnitFileState.staticState,
      'disabled' => LinuxSystemdUnitFileState.disabled,
      'indirect' => LinuxSystemdUnitFileState.indirect,
      'generated' => LinuxSystemdUnitFileState.generated,
      'transient' => LinuxSystemdUnitFileState.transient,
      'bad' => LinuxSystemdUnitFileState.bad,
      _ => _invalidValue('UnitFileState', value),
    };
  }

  static LinuxSystemdUnitResult _parseResult(String value) {
    return switch (value) {
      'success' => LinuxSystemdUnitResult.success,
      'resources' => LinuxSystemdUnitResult.resources,
      'timeout' => LinuxSystemdUnitResult.timeout,
      'exit-code' => LinuxSystemdUnitResult.exitCode,
      'signal' => LinuxSystemdUnitResult.signal,
      'core-dump' => LinuxSystemdUnitResult.coreDump,
      'watchdog' => LinuxSystemdUnitResult.watchdog,
      'start-limit-hit' => LinuxSystemdUnitResult.startLimitHit,
      _ => _invalidValue('Result', value),
    };
  }

  static Never _invalidValue(String property, String value) {
    throw LinuxSystemdTimerStatusParseException(
      failure: LinuxSystemdTimerStatusParseFailure.invalidValue,
      message: 'Unknown systemd property value.',
      property: property,
      value: value,
    );
  }
}
