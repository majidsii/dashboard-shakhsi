import 'package:dashboard_shakhsi/core/errors/app_failure.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_annual_date.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_calendar.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_end.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_frequency.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_invalid_date_policy.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_local_date_time.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_month_selector.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_rule.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_time_zone.dart';
import 'package:dashboard_shakhsi/core/recurrence/recurrence_weekday.dart';
import 'package:dashboard_shakhsi/features/tasks/domain/task_recurrence_rule.dart';
import 'package:shamsi_date/shamsi_date.dart';

final class TaskRecurrenceDraft {
  TaskRecurrenceDraft({
    required this.enabled,
    required this.frequency,
    required this.interval,
    required this.calendar,
    required this.timeZoneMode,
    required this.fixedTimeZoneId,
    required Set<RecurrenceWeekday> weeklyDays,
    required this.monthlyDaysText,
    required this.includeLastDay,
    required this.annualDatesText,
    required this.invalidDatePolicy,
    required this.endKind,
    required this.untilLocal,
    required this.afterCount,
    this.existingId,
    this.existingCreatedAtUtc,
  }) : weeklyDays = Set<RecurrenceWeekday>.from(weeklyDays);

  factory TaskRecurrenceDraft.disabled() {
    return TaskRecurrenceDraft(
      enabled: false,
      frequency: RecurrenceFrequency.daily,
      interval: 1,
      calendar: RecurrenceCalendar.jalali,
      timeZoneMode: RecurrenceTimeZoneMode.floating,
      fixedTimeZoneId: 'Asia/Tehran',
      weeklyDays: const <RecurrenceWeekday>{},
      monthlyDaysText: '',
      includeLastDay: false,
      annualDatesText: '',
      invalidDatePolicy: RecurrenceInvalidDatePolicy.skipPeriod,
      endKind: RecurrenceEndKind.never,
      untilLocal: null,
      afterCount: 10,
    );
  }

  factory TaskRecurrenceDraft.fromRule(TaskRecurrenceRule? source) {
    if (source == null) return TaskRecurrenceDraft.disabled();
    final rule = source.rule;
    return TaskRecurrenceDraft(
      enabled: true,
      frequency: rule.frequency,
      interval: rule.interval,
      calendar: rule.calendar,
      timeZoneMode: rule.timeZone.mode,
      fixedTimeZoneId: rule.timeZone.fixedTimeZoneId ?? 'Asia/Tehran',
      weeklyDays: rule.weeklyDays,
      monthlyDaysText: rule.monthlySelectors
          .where((item) => item.kind == RecurrenceMonthSelectorKind.dayOfMonth)
          .map((item) => item.day.toString())
          .join(', '),
      includeLastDay: rule.monthlySelectors.any(
        (item) => item.kind == RecurrenceMonthSelectorKind.lastDay,
      ),
      annualDatesText: rule.annualDates
          .map((item) => '${item.month}/${item.day}')
          .join(', '),
      invalidDatePolicy: rule.invalidDatePolicy,
      endKind: rule.end.kind,
      untilLocal: rule.end.untilUtc?.toLocal(),
      afterCount: rule.end.count ?? 10,
      existingId: source.id,
      existingCreatedAtUtc: source.createdAtUtc,
    );
  }

  bool enabled;
  RecurrenceFrequency frequency;
  int interval;
  RecurrenceCalendar calendar;
  RecurrenceTimeZoneMode timeZoneMode;
  String fixedTimeZoneId;
  final Set<RecurrenceWeekday> weeklyDays;
  String monthlyDaysText;
  bool includeLastDay;
  String annualDatesText;
  RecurrenceInvalidDatePolicy invalidDatePolicy;
  RecurrenceEndKind endKind;
  DateTime? untilLocal;
  int afterCount;
  final String? existingId;
  final DateTime? existingCreatedAtUtc;

  TaskRecurrenceDraft copy() {
    return TaskRecurrenceDraft(
      enabled: enabled,
      frequency: frequency,
      interval: interval,
      calendar: calendar,
      timeZoneMode: timeZoneMode,
      fixedTimeZoneId: fixedTimeZoneId,
      weeklyDays: weeklyDays,
      monthlyDaysText: monthlyDaysText,
      includeLastDay: includeLastDay,
      annualDatesText: annualDatesText,
      invalidDatePolicy: invalidDatePolicy,
      endKind: endKind,
      untilLocal: untilLocal,
      afterCount: afterCount,
      existingId: existingId,
      existingCreatedAtUtc: existingCreatedAtUtc,
    );
  }

  String? validate({required DateTime? anchorLocal}) {
    if (!enabled) return null;
    if (anchorLocal == null) {
      return 'برای تکرار باید زمان شروع یا سررسید مشخص شود.';
    }
    if (anchorLocal.isUtc) {
      return 'زمان مبنای تکرار باید محلی باشد.';
    }
    if (interval < 1) {
      return 'فاصله تکرار باید حداقل یک باشد.';
    }
    if (timeZoneMode == RecurrenceTimeZoneMode.fixed &&
        fixedTimeZoneId.trim().isEmpty) {
      return 'منطقه زمانی ثابت نمی‌تواند خالی باشد.';
    }
    if (frequency == RecurrenceFrequency.weekly && weeklyDays.isEmpty) {
      return 'حداقل یک روز هفته را انتخاب کنید.';
    }
    if (frequency == RecurrenceFrequency.monthly &&
        _monthlySelectors().isEmpty) {
      return 'حداقل یک روز ماه یا آخرین روز ماه را وارد کنید.';
    }
    if (frequency == RecurrenceFrequency.yearly && _annualDates().isEmpty) {
      return 'حداقل یک تاریخ سالانه مانند 1/1 وارد کنید.';
    }
    if (endKind == RecurrenceEndKind.until && untilLocal == null) {
      return 'تاریخ پایان تکرار را مشخص کنید.';
    }
    if (endKind == RecurrenceEndKind.afterCount && afterCount < 1) {
      return 'تعداد رخدادها باید حداقل یک باشد.';
    }
    return null;
  }

  TaskRecurrenceRule? build({
    required String taskId,
    required DateTime? anchorLocal,
    required DateTime savedAtUtc,
    required String Function() nextId,
  }) {
    final error = validate(anchorLocal: anchorLocal);
    if (error != null) throw ValidationFailure(error);
    if (!enabled) return null;

    final anchor = _toRecurrenceLocal(anchorLocal!);
    final timeZone = switch (timeZoneMode) {
      RecurrenceTimeZoneMode.floating => const RecurrenceTimeZone.floating(),
      RecurrenceTimeZoneMode.fixed => RecurrenceTimeZone.fixed(fixedTimeZoneId),
    };
    final end = switch (endKind) {
      RecurrenceEndKind.never => const RecurrenceEnd.never(),
      RecurrenceEndKind.until => RecurrenceEnd.until(untilLocal!.toUtc()),
      RecurrenceEndKind.afterCount => RecurrenceEnd.afterCount(afterCount),
    };

    final rule = switch (frequency) {
      RecurrenceFrequency.daily => RecurrenceRule.daily(
        anchorLocalDateTime: anchor,
        interval: interval,
        calendar: calendar,
        timeZone: timeZone,
        end: end,
      ),
      RecurrenceFrequency.weekly => RecurrenceRule.weekly(
        anchorLocalDateTime: anchor,
        weeklyDays: weeklyDays,
        interval: interval,
        calendar: calendar,
        timeZone: timeZone,
        end: end,
      ),
      RecurrenceFrequency.monthly => RecurrenceRule.monthly(
        anchorLocalDateTime: anchor,
        monthlySelectors: _monthlySelectors(),
        interval: interval,
        calendar: calendar,
        timeZone: timeZone,
        end: end,
        invalidDatePolicy: invalidDatePolicy,
      ),
      RecurrenceFrequency.yearly => RecurrenceRule.yearly(
        anchorLocalDateTime: anchor,
        annualDates: _annualDates(),
        interval: interval,
        calendar: calendar,
        timeZone: timeZone,
        end: end,
        invalidDatePolicy: invalidDatePolicy,
      ),
    };

    return TaskRecurrenceRule(
      id: existingId ?? nextId(),
      taskId: taskId,
      rule: rule,
      createdAtUtc: existingCreatedAtUtc ?? savedAtUtc,
      updatedAtUtc: savedAtUtc,
    );
  }

  RecurrenceLocalDateTime _toRecurrenceLocal(DateTime value) {
    if (calendar == RecurrenceCalendar.gregorian) {
      return RecurrenceLocalDateTime(
        year: value.year,
        month: value.month,
        day: value.day,
        hour: value.hour,
        minute: value.minute,
      );
    }
    final jalali = Jalali.fromDateTime(value);
    return RecurrenceLocalDateTime(
      year: jalali.year,
      month: jalali.month,
      day: jalali.day,
      hour: value.hour,
      minute: value.minute,
    );
  }

  List<RecurrenceMonthSelector> _monthlySelectors() {
    final output = <RecurrenceMonthSelector>[];
    final seen = <int>{};
    for (final token in monthlyDaysText.split(',')) {
      final value = int.tryParse(token.trim());
      if (value != null && value >= 1 && value <= 31 && seen.add(value)) {
        output.add(RecurrenceMonthSelector.dayOfMonth(value));
      }
    }
    if (includeLastDay) {
      output.add(const RecurrenceMonthSelector.lastDay());
    }
    return output;
  }

  List<RecurrenceAnnualDate> _annualDates() {
    final output = <RecurrenceAnnualDate>[];
    final seen = <String>{};
    for (final token in annualDatesText.split(',')) {
      final parts = token.trim().split('/');
      if (parts.length != 2) continue;
      final month = int.tryParse(parts[0].trim());
      final day = int.tryParse(parts[1].trim());
      if (month == null || day == null) continue;
      final key = '$month/$day';
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && seen.add(key)) {
        output.add(RecurrenceAnnualDate(month: month, day: day));
      }
    }
    return output;
  }
}
