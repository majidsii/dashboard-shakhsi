import 'package:shamsi_date/shamsi_date.dart';

abstract final class PersianDateLabel {
  static const List<String> _weekdays = <String>[
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنج‌شنبه',
    'جمعه',
    'شنبه',
    'یک‌شنبه',
  ];

  static const List<String> _months = <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static String full(DateTime dateTime) {
    final jalali = Jalali.fromDateTime(dateTime);
    final weekday = _weekdays[dateTime.weekday - 1];
    return '$weekday، ${_fa(jalali.day)} ${_months[jalali.month - 1]} ${_fa(jalali.year)}';
  }

  static String _fa(Object value) {
    const latin = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    return value.toString().split('').map((character) {
      final index = latin.indexOf(character);
      return index < 0 ? character : persian[index];
    }).join();
  }
}
