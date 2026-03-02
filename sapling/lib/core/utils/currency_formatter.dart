import 'package:intl/intl.dart';

String formatCurrency(double amount, {String symbol = '\$'}) {
  final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
  return formatter.format(amount);
}

String formatCurrencyCompact(double amount, {String symbol = '\$'}) {
  if (amount.abs() >= 1000) {
    return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
  }
  return formatCurrency(amount, symbol: symbol);
}
