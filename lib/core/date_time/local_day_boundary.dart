import 'local_date.dart';

final class LocalDayBoundary {
  factory LocalDayBoundary({required int startHour, int startMinute = 0}) {
    if (startHour < 0 || startHour > 23) {
      throw ArgumentError.value(
        startHour,
        'startHour',
        'Start hour must be between 0 and 23.',
      );
    }
    if (startMinute < 0 || startMinute > 59) {
      throw ArgumentError.value(
        startMinute,
        'startMinute',
        'Start minute must be between 0 and 59.',
      );
    }

    return LocalDayBoundary._(startHour: startHour, startMinute: startMinute);
  }

  const LocalDayBoundary._({
    required this.startHour,
    required this.startMinute,
  });

  final int startHour;
  final int startMinute;

  LocalDate dateFor(DateTime localInstant) {
    final boundary = DateTime(
      localInstant.year,
      localInstant.month,
      localInstant.day,
      startHour,
      startMinute,
    );

    if (localInstant.isBefore(boundary)) {
      return LocalDate.fromDateTime(
        DateTime(localInstant.year, localInstant.month, localInstant.day - 1),
      );
    }

    return LocalDate.fromDateTime(localInstant);
  }

  DateTime nextBoundaryAfter(DateTime localInstant) {
    final todayBoundary = DateTime(
      localInstant.year,
      localInstant.month,
      localInstant.day,
      startHour,
      startMinute,
    );

    if (localInstant.isBefore(todayBoundary)) {
      return todayBoundary;
    }

    return DateTime(
      localInstant.year,
      localInstant.month,
      localInstant.day + 1,
      startHour,
      startMinute,
    );
  }
}
