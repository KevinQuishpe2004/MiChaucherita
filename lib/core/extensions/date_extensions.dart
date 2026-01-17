import 'package:intl/intl.dart';

/// Extensiones útiles para manejo de fechas
extension DateTimeExtension on DateTime {
  /// Formatea la fecha como "dd/MM/yyyy"
  String toShortDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Formatea la fecha como "dd MMM yyyy"
  String toMediumDate() {
    return DateFormat('dd MMM yyyy', 'es').format(this);
  }

  /// Formatea la fecha como "dd de MMMM de yyyy"
  String toLongDate() {
    return DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(this);
  }

  /// Formatea como "Hoy", "Ayer" o fecha corta
  String toRelativeDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);

    if (date == today) {
      return 'Hoy';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE', 'es').format(this);
    } else {
      return toShortDate();
    }
  }

  /// Formatea como hora "HH:mm"
  String toTime() {
    return DateFormat('HH:mm').format(this);
  }

  /// Formatea fecha y hora
  String toDateTime() {
    return '${toShortDate()} ${toTime()}';
  }

  /// Obtiene el nombre del mes
  String get monthName {
    return DateFormat('MMMM', 'es').format(this);
  }

  /// Obtiene el nombre corto del mes
  String get shortMonthName {
    return DateFormat('MMM', 'es').format(this);
  }

  /// Verifica si es el mismo día
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Verifica si es el mismo mes
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Obtiene el primer día del mes
  DateTime get firstDayOfMonth {
    return DateTime(year, month, 1);
  }

  /// Obtiene el último día del mes
  DateTime get lastDayOfMonth {
    return DateTime(year, month + 1, 0);
  }

  /// Obtiene el inicio del día
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Obtiene el fin del día
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }
}
