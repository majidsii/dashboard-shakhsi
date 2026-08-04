enum TaskReminderTrigger {
  atDue(
    storageValue: 'atDue',
    offsetMinutes: 0,
    label: 'سر موعد',
    compactLabel: 'سر موعد',
  ),
  fifteenMinutesBefore(
    storageValue: 'fifteenMinutesBefore',
    offsetMinutes: 15,
    label: '۱۵ دقیقه قبل',
    compactLabel: '۱۵ دقیقه',
  ),
  oneHourBefore(
    storageValue: 'oneHourBefore',
    offsetMinutes: 60,
    label: '۱ ساعت قبل',
    compactLabel: '۱ ساعت',
  ),
  oneDayBefore(
    storageValue: 'oneDayBefore',
    offsetMinutes: 1440,
    label: '۱ روز قبل',
    compactLabel: '۱ روز',
  );

  const TaskReminderTrigger({
    required this.storageValue,
    required this.offsetMinutes,
    required this.label,
    required this.compactLabel,
  });

  final String storageValue;
  final int offsetMinutes;
  final String label;
  final String compactLabel;

  DateTime scheduledAtUtc(DateTime dueAtUtc) {
    if (!dueAtUtc.isUtc) {
      throw ArgumentError.value(
        dueAtUtc,
        'dueAtUtc',
        'Reminder due time must use UTC.',
      );
    }
    return dueAtUtc.subtract(Duration(minutes: offsetMinutes));
  }

  static TaskReminderTrigger parseStorage(String value) {
    return TaskReminderTrigger.values.firstWhere(
      (trigger) => trigger.storageValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unknown task reminder trigger.',
      ),
    );
  }
}
