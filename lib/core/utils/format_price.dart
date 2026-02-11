import 'package:intl/intl.dart';

String formatPrice(double price) {
  // format price currency with 2 decimal places in $ 12,345.67

  return NumberFormat.currency(symbol: '', decimalDigits: 2).format(price);
}
