import 'package:intl/intl.dart';

class AppFormatters {
  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  static String currency(num value) => _currency.format(value);

  static String dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String brDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}
