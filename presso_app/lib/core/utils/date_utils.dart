import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  // -------------------------------------------------------------------------
  // Formatters
  // -------------------------------------------------------------------------

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');
  static final DateFormat _dayMonthYear = DateFormat('EEEE, dd MMMM yyyy');
  static final DateFormat _slotTimeFormat = DateFormat('hh:mm a');

  // -------------------------------------------------------------------------
  // Date formatting
  // -------------------------------------------------------------------------

  /// Returns "15 Mar 2026"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Returns "Tuesday, 15 March 2026"
  static String formatFullDate(DateTime date) => _dayMonthYear.format(date);

  /// Returns "15 Mar"
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  /// Returns "15 Mar 2026, 02:30 PM"
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  // -------------------------------------------------------------------------
  // Time formatting
  // -------------------------------------------------------------------------

  /// Returns "02:30 PM"
  static String formatTime(DateTime time) => _timeFormat.format(time);

  /// Formats a slot time range, e.g. "09:00 AM – 12:00 PM"
  static String formatSlotTime(DateTime start, DateTime end) {
    return '${_slotTimeFormat.format(start)} – ${_slotTimeFormat.format(end)}';
  }

  /// Formats a slot time range from time-only strings (HH:mm), e.g. "09:00 – 12:00"
  static String formatSlotTimeString(String startTime, String endTime) {
    try {
      final now = DateTime.now();
      final start = _parseTimeString(startTime, now);
      final end = _parseTimeString(endTime, now);
      return formatSlotTime(start, end);
    } catch (_) {
      return '$startTime – $endTime';
    }
  }

  static DateTime _parseTimeString(String time, DateTime base) {
    final parts = time.split(':');
    return DateTime(
      base.year,
      base.month,
      base.day,
      int.parse(parts[0]),
      parts.length > 1 ? int.parse(parts[1]) : 0,
    );
  }

  // -------------------------------------------------------------------------
  // Relative time
  // -------------------------------------------------------------------------

  /// Returns a human-readable relative time, e.g. "2 hours ago", "just now".
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // -------------------------------------------------------------------------
  // Greeting
  // -------------------------------------------------------------------------

  /// Returns a greeting string based on the current hour.
  /// 5-11 → Good Morning, 12-16 → Good Afternoon, 17-20 → Good Evening, else → Good Night
  static String greetingByTime([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Returns true if [date] is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Returns true if [date] is tomorrow.
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Returns "Today", "Tomorrow", or the formatted date.
  static String smartDate(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    return formatDate(date);
  }

  /// Parses an ISO 8601 string and returns a [DateTime]. Returns null on failure.
  static DateTime? tryParseIso(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    return DateTime.tryParse(isoString);
  }

  /// Formats an ISO 8601 string to a readable date. Returns empty string on failure.
  static String formatIsoDate(String? isoString) {
    final date = tryParseIso(isoString);
    if (date == null) return '';
    return formatDate(date.toLocal());
  }

  /// Formats an ISO 8601 string to a readable date-time. Returns empty string on failure.
  static String formatIsoDateTime(String? isoString) {
    final date = tryParseIso(isoString);
    if (date == null) return '';
    return formatDateTime(date.toLocal());
  }
}
