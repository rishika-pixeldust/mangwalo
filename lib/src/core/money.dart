import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// "₹2,500" — Indian digit grouping, no paise.
String formatInr(int amount) => _inr.format(amount);

/// "₹2,500/day" — the card price line.
String formatInrPerDay(int amount) => '${formatInr(amount)}/day';
