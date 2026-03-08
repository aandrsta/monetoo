// lib/utils/currency_formatter.dart

import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return _compact.format(amount);
    }
    return _formatter.format(amount);
  }

  static String formatWithSign(double amount, {bool isExpense = false}) {
    final sign = isExpense ? '- ' : '+ ';
    return '$sign${_formatter.format(amount)}';
  }
}

class DateFormatter {
  static String formatDay(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatDayShort(DateTime date) {
    return DateFormat('d MMM', 'id_ID').format(date);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
