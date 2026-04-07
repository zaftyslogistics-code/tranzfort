import 'package:intl/intl.dart';

/// India Standard Time helpers (UTC+05:30) for consistent user-facing timestamps.
class IstTime {
  static const Duration _offset = Duration(hours: 5, minutes: 30);

  static DateTime toIst(DateTime dateTime) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    return utc.add(_offset);
  }

  static DateTime nowIst() => DateTime.now().toUtc().add(_offset);

  static String formatTime(DateTime dateTime) {
    return DateFormat.jm().format(toIst(dateTime));
  }

  static String formatMonthDay(DateTime dateTime) {
    return DateFormat.MMMd().format(toIst(dateTime));
  }

  static String formatDayMonth(DateTime dateTime) {
    return DateFormat('d MMM').format(toIst(dateTime));
  }

  static Duration age(DateTime dateTime) {
    return nowIst().difference(toIst(dateTime));
  }
}
