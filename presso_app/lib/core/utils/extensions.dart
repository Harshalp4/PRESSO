import 'package:flutter/material.dart';
import 'date_utils.dart';
import 'currency_utils.dart';

// =============================================================================
// String extensions
// =============================================================================

extension StringExtensions on String {
  /// Capitalizes the first letter of a string. e.g. "hello" → "Hello"
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalizes the first letter of every word. e.g. "hello world" → "Hello World"
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.isEmpty ? word : word.capitalize).join(' ');
  }

  /// Returns null if the string is empty, otherwise the string itself.
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Truncates the string to [maxLength] chars, appending [ellipsis] if needed.
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Returns true if the string is a valid email address.
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  /// Returns true if the string is a valid Indian mobile number.
  bool get isValidPhone =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(replaceAll('+91', '').trim());

  /// Returns true if the string is a valid 6-digit pincode.
  bool get isValidPincode => RegExp(r'^\d{6}$').hasMatch(trim());

  /// Removes all whitespace from the string.
  String get stripWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Converts an ISO 8601 date string to a formatted date. Returns empty on failure.
  String get asFormattedDate => AppDateUtils.formatIsoDate(this);

  /// Converts an ISO 8601 date-time string to a formatted date-time. Returns empty on failure.
  String get asFormattedDateTime => AppDateUtils.formatIsoDateTime(this);

  /// Tries to parse this string as a [DateTime]. Returns null on failure.
  DateTime? get asDateTime => DateTime.tryParse(this);

  /// Converts snake_case or kebab-case to a readable label. e.g. "order_placed" → "Order Placed"
  String get toReadableLabel =>
      replaceAll(RegExp(r'[_\-]'), ' ').titleCase;
}

extension NullableStringExtensions on String? {
  /// Returns true if null or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if not null and not empty.
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  /// Returns empty string if null.
  String get orEmpty => this ?? '';

  /// Returns the string or a fallback.
  String orElse(String fallback) => isNullOrEmpty ? fallback : this!;
}

// =============================================================================
// DateTime extensions
// =============================================================================

extension DateTimeExtensions on DateTime {
  /// Returns "15 Mar 2026"
  String get formatted => AppDateUtils.formatDate(this);

  /// Returns "Tuesday, 15 March 2026"
  String get fullFormatted => AppDateUtils.formatFullDate(this);

  /// Returns "02:30 PM"
  String get formattedTime => AppDateUtils.formatTime(this);

  /// Returns "15 Mar 2026, 02:30 PM"
  String get formattedDateTime => AppDateUtils.formatDateTime(this);

  /// Returns "15 Mar"
  String get shortFormatted => AppDateUtils.formatShortDate(this);

  /// Returns a human-readable relative time (e.g. "2 hours ago").
  String get timeAgo => AppDateUtils.timeAgo(this);

  /// Returns "Today", "Tomorrow", or the formatted date.
  String get smartDate => AppDateUtils.smartDate(this);

  /// Returns true if this date is today.
  bool get isToday => AppDateUtils.isToday(this);

  /// Returns true if this date is tomorrow.
  bool get isTomorrow => AppDateUtils.isTomorrow(this);

  /// Returns true if this date is in the past.
  bool get isPast => isBefore(DateTime.now());

  /// Returns true if this date is in the future.
  bool get isFuture => isAfter(DateTime.now());

  /// Returns the start of the day (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the end of the day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns true if this date is the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension NullableDateTimeExtensions on DateTime? {
  /// Returns formatted date or empty string if null.
  String get formattedOrEmpty => this == null ? '' : this!.formatted;

  /// Returns formatted date-time or empty string if null.
  String get formattedDateTimeOrEmpty => this == null ? '' : this!.formattedDateTime;

  /// Returns time ago string or empty string if null.
  String get timeAgoOrEmpty => this == null ? '' : this!.timeAgo;
}

// =============================================================================
// int extensions
// =============================================================================

extension IntExtensions on int {
  /// Formats as Presso coins label. e.g. 250 → "250 coins"
  String get coinsLabel => CurrencyUtils.formatCoins(this);

  /// Formats as compact Presso coins. e.g. 1500 → "1.5K PC"
  String get coinsShort => CurrencyUtils.formatCoinsShort(this);

  /// Formats as Indian rupees. e.g. 1250 → "₹1,250"
  String get rupees => CurrencyUtils.formatCurrency(this);

  /// Creates a [Duration] in seconds.
  Duration get seconds => Duration(seconds: this);

  /// Creates a [Duration] in milliseconds.
  Duration get milliseconds => Duration(milliseconds: this);

  /// Creates a [Duration] in minutes.
  Duration get minutes => Duration(minutes: this);
}

// =============================================================================
// double extensions
// =============================================================================

extension DoubleExtensions on double {
  /// Formats as Indian rupees. e.g. 1250.5 → "₹1,250.50"
  String get rupeesDecimal => CurrencyUtils.formatCurrencyDecimal(this);

  /// Formats as Indian rupees without decimals.
  String get rupees => CurrencyUtils.formatCurrency(this);
}

// =============================================================================
// BuildContext extensions
// =============================================================================

extension BuildContextExtensions on BuildContext {
  /// Returns the current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Returns the current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Returns the current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Returns the current [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Returns the screen size.
  Size get screenSize => MediaQuery.of(this).size;

  /// Returns the screen width.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Returns the screen height.
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Returns the bottom padding (safe area).
  double get bottomPadding => MediaQuery.of(this).padding.bottom;

  /// Returns the top padding (status bar / notch).
  double get topPadding => MediaQuery.of(this).padding.top;

  /// Shows a [SnackBar] with the given message.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dismisses the keyboard.
  void unfocus() => FocusScope.of(this).unfocus();

  /// Returns true if the keyboard is visible.
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;
}

// =============================================================================
// List extensions
// =============================================================================

extension ListExtensions<T> on List<T> {
  /// Returns null if the list is empty, otherwise the list.
  List<T>? get nullIfEmpty => isEmpty ? null : this;

  /// Returns the element at [index] or null if out of bounds.
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
