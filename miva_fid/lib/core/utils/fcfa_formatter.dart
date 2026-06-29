import 'package:intl/intl.dart';

class FcfaFormatter {
  FcfaFormatter._();

  static final _formatter = NumberFormat('#,##0', 'fr_FR');

  /// Retourne "2 500 FCFA"
  static String format(int amount) {
    return '${_formatter.format(amount).replaceAll(',', '\u202F')} FCFA';
  }

  /// Retourne "2 500" sans le suffixe FCFA
  static String formatRaw(int amount) {
    return _formatter.format(amount).replaceAll(',', '\u202F');
  }

  /// Parse "2 500 FCFA" → 2500
  static int parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}
