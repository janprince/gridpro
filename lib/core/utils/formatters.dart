import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'en_GH',
  symbol: 'GH₵ ',
  decimalDigits: 2,
);
final _date = DateFormat('EEE, d MMM');
final _time = DateFormat('h:mm a');

String formatCurrency(num value) => _currency.format(value);
String formatDate(DateTime value) => _date.format(value);
String formatTime(DateTime value) => _time.format(value);

String? requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;
