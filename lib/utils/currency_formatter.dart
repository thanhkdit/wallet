
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0);

  static String format(double amount) {
    // 1. Format with en_US (1,000,000)
    String formatted = _formatter.format(amount);
    
    // 2. Replace commas with dots (1.000.000)
    formatted = formatted.replaceAll(',', '.');
    
    // 3. Append symbol (1.000.000 đ)
    return '$formatted đ';
  }
}
