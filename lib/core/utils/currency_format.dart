import 'package:intl/intl.dart';

String formatCurrency(num amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);
}

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}

String formatDateShort(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatTime(DateTime date) {
  return DateFormat('HH:mm').format(date);
}

String formatMonth(DateTime date) {
  return DateFormat('MMMM yyyy', 'id_ID').format(date);
}

String getGreeting(String name, bool isIndonesian) {
  final hour = DateTime.now().hour;
  String greeting;
  if (hour < 11) {
    greeting = isIndonesian ? 'Selamat Pagi' : 'Good Morning';
  } else if (hour < 15) {
    greeting = isIndonesian ? 'Selamat Siang' : 'Good Afternoon';
  } else if (hour < 19) {
    greeting = isIndonesian ? 'Selamat Sore' : 'Good Evening';
  } else {
    greeting = isIndonesian ? 'Selamat Malam' : 'Good Night';
  }
  return '$greeting, $name';
}
