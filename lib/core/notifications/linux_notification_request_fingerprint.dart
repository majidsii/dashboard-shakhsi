import 'dart:collection';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'notification_request.dart';

final class LinuxNotificationRequestFingerprint {
  factory LinuxNotificationRequestFingerprint({
    int deliveryCommandSchemaVersion = 1,
  }) {
    if (deliveryCommandSchemaVersion <= 0) {
      throw ArgumentError.value(
        deliveryCommandSchemaVersion,
        'deliveryCommandSchemaVersion',
        'Delivery command schema version must be positive.',
      );
    }

    return LinuxNotificationRequestFingerprint._(
      deliveryCommandSchemaVersion: deliveryCommandSchemaVersion,
    );
  }

  const LinuxNotificationRequestFingerprint._({
    required this.deliveryCommandSchemaVersion,
  });

  static const int fingerprintSchemaVersion = 1;

  final int deliveryCommandSchemaVersion;

  Future<String> compute(NotificationRequest request) async {
    final sortedPayload = SplayTreeMap<String, String>.from(request.payload);
    final canonical = jsonEncode(<String, Object?>{
      'fingerprintSchemaVersion': fingerprintSchemaVersion,
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
    final digest = await Sha256().hash(utf8.encode(canonical));

    return digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
