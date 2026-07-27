import 'dart:convert';

import 'notification_owner.dart';
import 'notification_request.dart';

final class NotificationPayload {
  NotificationPayload({
    required this.scheduleId,
    required this.owner,
    required Map<String, String> values,
  }) : values = Map<String, String>.unmodifiable(values);

  final String scheduleId;
  final NotificationOwner owner;
  final Map<String, String> values;
}

final class NotificationPayloadCodec {
  const NotificationPayloadCodec._();

  static const int _version = 1;

  static String encode(NotificationRequest request) {
    final sortedPayload = Map<String, String>.fromEntries(
      request.payload.entries.toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key)),
    );

    return jsonEncode(<String, Object>{
      'version': _version,
      'scheduleId': request.scheduleId,
      'ownerType': request.owner.type.name,
      'ownerId': request.owner.id,
      'values': sortedPayload,
    });
  }

  static NotificationPayload decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Notification payload is not valid JSON.', error);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Notification payload must be a JSON object.',
      );
    }

    final version = decoded['version'];
    final scheduleId = decoded['scheduleId'];
    final ownerType = decoded['ownerType'];
    final ownerId = decoded['ownerId'];
    final values = decoded['values'];

    if (version != _version ||
        scheduleId is! String ||
        ownerType is! String ||
        ownerId is! String ||
        values is! Map<String, dynamic>) {
      throw const FormatException(
        'Notification payload is incomplete or unsupported.',
      );
    }

    final NotificationOwnerType parsedOwnerType;
    try {
      parsedOwnerType = NotificationOwnerType.values.byName(ownerType);
    } on ArgumentError {
      throw FormatException('Unknown notification owner type: $ownerType');
    }

    final parsedValues = <String, String>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value is! String) {
        throw const FormatException(
          'Notification payload values must be strings.',
        );
      }
      parsedValues[entry.key] = value;
    }

    return NotificationPayload(
      scheduleId: scheduleId,
      owner: NotificationOwner(type: parsedOwnerType, id: ownerId),
      values: parsedValues,
    );
  }
}
