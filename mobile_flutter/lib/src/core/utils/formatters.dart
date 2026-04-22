import 'package:intl/intl.dart';

String onlyDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

String normalizeWhatsappPhone(String rawPhone) {
  var digits = onlyDigits(rawPhone);
  while (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (digits.startsWith('55')) {
    return digits;
  }
  if (digits.length == 10 || digits.length == 11) {
    return '55$digits';
  }
  return digits;
}

String formatShortDate(DateTime date) {
  final now = DateTime.now();
  final sameYear = now.year == date.year;
  return DateFormat(sameYear ? 'dd/MM' : 'dd/MM/yyyy').format(date);
}

String truncateText(String value, {int maxChars = 36}) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= maxChars) {
    return normalized;
  }
  return '${normalized.substring(0, maxChars - 3)}...';
}
