const String linuxNotificationDeliveryFlag = '--deliver-notification';

enum LinuxNotificationDeliveryArgumentFailure {
  invalidShape,
  invalidScheduleId,
}

final class LinuxNotificationDeliveryArgumentException implements Exception {
  const LinuxNotificationDeliveryArgumentException(this.failure);

  final LinuxNotificationDeliveryArgumentFailure failure;

  @override
  String toString() {
    return 'LinuxNotificationDeliveryArgumentException('
        'failure=${failure.name})';
  }
}

sealed class LinuxNotificationDeliveryInvocation {
  const LinuxNotificationDeliveryInvocation();

  factory LinuxNotificationDeliveryInvocation.parse(List<String> arguments) {
    if (!arguments.contains(linuxNotificationDeliveryFlag)) {
      return const LinuxNormalApplicationInvocation();
    }

    if (arguments.length != 2 ||
        arguments.first != linuxNotificationDeliveryFlag ||
        arguments.last == linuxNotificationDeliveryFlag) {
      throw const LinuxNotificationDeliveryArgumentException(
        LinuxNotificationDeliveryArgumentFailure.invalidShape,
      );
    }

    final scheduleId = arguments.last;
    if (!_isSafeScheduleId(scheduleId)) {
      throw const LinuxNotificationDeliveryArgumentException(
        LinuxNotificationDeliveryArgumentFailure.invalidScheduleId,
      );
    }

    return LinuxHiddenNotificationDeliveryInvocation(scheduleId: scheduleId);
  }

  static bool _isSafeScheduleId(String value) {
    if (value.isEmpty || value.trim() != value) {
      return false;
    }

    for (final rune in value.runes) {
      final isC0Control = rune <= 0x1f;
      final isDeleteOrC1Control = rune >= 0x7f && rune <= 0x9f;
      if (isC0Control || isDeleteOrC1Control) {
        return false;
      }
    }

    return true;
  }
}

final class LinuxNormalApplicationInvocation
    extends LinuxNotificationDeliveryInvocation {
  const LinuxNormalApplicationInvocation();
}

final class LinuxHiddenNotificationDeliveryInvocation
    extends LinuxNotificationDeliveryInvocation {
  const LinuxHiddenNotificationDeliveryInvocation({required this.scheduleId});

  final String scheduleId;
}
