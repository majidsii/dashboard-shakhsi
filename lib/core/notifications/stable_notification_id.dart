final class StableNotificationId {
  const StableNotificationId._();

  static int fromScheduleId(String scheduleId) {
    final normalized = scheduleId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        scheduleId,
        'scheduleId',
        'Notification schedule id cannot be blank.',
      );
    }

    const offsetBasis = 0x811c9dc5;
    const prime = 0x01000193;
    var hash = offsetBasis;

    for (final byte in normalized.codeUnits) {
      hash ^= byte;
      hash = (hash * prime) & 0xffffffff;
    }

    final positive31Bit = hash & 0x7fffffff;
    return positive31Bit == 0 ? 1 : positive31Bit;
  }
}
