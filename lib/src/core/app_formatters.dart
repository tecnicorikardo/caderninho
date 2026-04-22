import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  static String currency(num value) => _brl.format(value);

  static String date(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

  static String time(DateTime value) => DateFormat('HH:mm').format(value);
}
