final class LocalDate implements Comparable<LocalDate> {
  const LocalDate._({
    required this.year,
    required this.month,
    required this.day,
  });

  factory LocalDate({required int year, required int month, required int day}) {
    _validate(year, month, day);
    return LocalDate._(year: year, month: month, day: day);
  }

  factory LocalDate.fromDateTime(DateTime value) {
    return LocalDate(year: value.year, month: value.month, day: value.day);
  }

  factory LocalDate.parseIso(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const FormatException('Date must use YYYY-MM-DD format.');
    }

    return LocalDate(
      year: int.parse(match.group(1)!),
      month: int.parse(match.group(2)!),
      day: int.parse(match.group(3)!),
    );
  }

  final int year;
  final int month;
  final int day;

  String toIso() {
    final paddedMonth = month.toString().padLeft(2, '0');
    final paddedDay = day.toString().padLeft(2, '0');
    return '${year.toString().padLeft(4, '0')}-$paddedMonth-$paddedDay';
  }

  DateTime toUtcStart() => DateTime.utc(year, month, day);

  LocalDate addDays(int days) {
    return LocalDate.fromDateTime(toUtcStart().add(Duration(days: days)));
  }

  @override
  int compareTo(LocalDate other) => toIso().compareTo(other.toIso());

  static void _validate(int year, int month, int day) {
    final value = DateTime.utc(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      throw ArgumentError.value(
        '$year-$month-$day',
        'date',
        'Date components do not form a valid Gregorian date.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    return other is LocalDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
