import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'en_GH',
  symbol: 'GH₵ ',
  decimalDigits: 2,
);
final _date = DateFormat('EEE, d MMM');
final _longDate = DateFormat('EEEE, d MMMM');
final _time = DateFormat('h:mm a');

String formatCurrency(num value) => _currency.format(value);
String formatDate(DateTime value) => _date.format(value);
String formatLongDate(DateTime value) => _longDate.format(value);
String formatTime(DateTime value) => _time.format(value);

/// "Today", "Tomorrow", "Yesterday", or a short date.
String formatDay(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  return switch (day.difference(today).inDays) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    _ => _date.format(value),
  };
}

/// "Today · 1:30 PM".
String formatWhen(DateTime value) =>
    '${formatDay(value)} · ${formatTime(value)}';

/// Time of day greeting for the home screen.
String greeting([DateTime? at]) {
  final hour = (at ?? DateTime.now()).hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String? requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;
