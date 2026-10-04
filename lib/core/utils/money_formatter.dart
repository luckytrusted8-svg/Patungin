import 'package:intl/intl.dart';
import '../../domain/parser/number_parser.dart';

class MoneyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format int rupiah menjadi string dengan format mata uang Indonesia: "Rp 172.500"
  static String format(int amount) {
    return _formatter.format(amount).replaceAll('Rp', 'Rp ').replaceAll('  ', ' ');
  }

  /// Format angka tanpa prefix simbol "Rp": "172.500"
  static String formatRaw(int amount) {
    return NumberFormat.decimalPattern('id_ID').format(amount);
  }

  /// Parse string harga menjadi int rupiah
  static int? parse(String? input) {
    return NumberParser.parse(input);
  }
}
