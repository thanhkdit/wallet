
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);

  static String format(double amount) {
    String formatted = _formatter.format(amount);

    formatted = formatted.replaceAll(',', '.');

    return '$formatted đ';
  }
}
