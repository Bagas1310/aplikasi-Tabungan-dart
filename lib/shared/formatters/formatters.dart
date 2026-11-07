import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _format = NumberFormat('#,###', 'id_ID');

  static String format(int amount) => 'Rp${_format.format(amount)}';

  static int? parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
}

class DateFormatter {
  static final _full = DateFormat('dd MMM yyyy', 'id_ID');
  static final _monthYear = DateFormat('MMM yyyy', 'id_ID');
  static final _dateTime = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

  static String full(DateTime date) => _full.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String dateTime(DateTime date) => _dateTime.format(date);
}
