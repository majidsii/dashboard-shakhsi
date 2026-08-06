enum RecurrenceWeekday {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  const RecurrenceWeekday(this.isoNumber);

  final int isoNumber;

  static RecurrenceWeekday fromIsoNumber(int value) {
    return RecurrenceWeekday.values.firstWhere(
      (weekday) => weekday.isoNumber == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'ISO weekday must be between 1 and 7.',
      ),
    );
  }
}
