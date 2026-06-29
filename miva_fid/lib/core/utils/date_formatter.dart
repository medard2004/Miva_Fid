import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _fullDate = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
  static final _shortDate = DateFormat('d MMM yyyy', 'fr_FR');
  static final _time = DateFormat('HH:mm', 'fr_FR');
  static final _dayMonth = DateFormat('d MMM', 'fr_FR');

  /// "lundi 23 juin 2026"
  static String full(DateTime date) => _fullDate.format(date);

  /// "23 juin 2026"
  static String short(DateTime date) => _shortDate.format(date);

  /// "23 juin"
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// "14:30"
  static String time(DateTime date) => _time.format(date);

  /// "il y a 2 jours" / "aujourd'hui" / "hier"
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return "aujourd'hui";
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return 'il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return 'il y a $months mois';
    }
    final years = (diff.inDays / 365).floor();
    return 'il y a $years an${years > 1 ? 's' : ''}';
  }

  /// "membre depuis 3 mois"
  static String memberSince(DateTime date) {
    return 'membre depuis ${relative(date)}';
  }
}
