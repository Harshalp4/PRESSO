import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static final NumberFormat _rupeeFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _rupeeDecimalFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'en_IN',
  );

  // -------------------------------------------------------------------------
  // Currency formatting
  // -------------------------------------------------------------------------

  /// Formats a number as Indian rupees without decimals. e.g. "₹1,250"
  static String formatCurrency(num amount) {
    return _rupeeFormat.format(amount);
  }

  /// Formats a number as Indian rupees with 2 decimal places. e.g. "₹1,250.50"
  static String formatCurrencyDecimal(num amount) {
    return _rupeeDecimalFormat.format(amount);
  }

  /// Formats a number as Indian rupees with compact notation. e.g. "₹1.2K"
  static String formatCurrencyCompact(num amount) {
    return '₹${_compactFormat.format(amount)}';
  }

  /// Returns the currency symbol with amount, e.g. "₹500"
  static String rupee(num amount) => '₹${_formatNumber(amount)}';

  /// Formats just the number part with Indian locale (no symbol). e.g. "1,250"
  static String _formatNumber(num amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##,###', 'en_IN').format(amount.toInt());
    }
    return NumberFormat('#,##,###.##', 'en_IN').format(amount);
  }

  // -------------------------------------------------------------------------
  // Coin formatting
  // -------------------------------------------------------------------------

  /// Formats a coin count. e.g. "250 coins", "1,500 coins"
  static String formatCoins(int coins) {
    final formatted = NumberFormat('#,##,###', 'en_IN').format(coins);
    return '$formatted ${coins == 1 ? 'coin' : 'coins'}';
  }

  /// Formats coins as a short label. e.g. "250 PC" (Presso Coins)
  static String formatCoinsShort(int coins) {
    if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K PC';
    }
    return '$coins PC';
  }

  /// Converts coins to equivalent rupee value (1 coin = ₹0.10 by default).
  static String coinsToRupees(int coins, {double conversionRate = 0.10}) {
    final amount = coins * conversionRate;
    return formatCurrency(amount);
  }

  // -------------------------------------------------------------------------
  // Discount helpers
  // -------------------------------------------------------------------------

  /// Formats a discount percentage. e.g. "15% off"
  static String formatDiscount(num percentage) {
    final formatted = percentage == percentage.roundToDouble()
        ? percentage.toInt().toString()
        : percentage.toStringAsFixed(1);
    return '$formatted% off';
  }

  /// Calculates discounted price and returns formatted string.
  static String discountedPrice(num originalPrice, num discountPercent) {
    final discounted = originalPrice * (1 - discountPercent / 100);
    return formatCurrency(discounted);
  }

  /// Calculates savings amount.
  static num savingsAmount(num originalPrice, num discountPercent) {
    return originalPrice * (discountPercent / 100);
  }
}
