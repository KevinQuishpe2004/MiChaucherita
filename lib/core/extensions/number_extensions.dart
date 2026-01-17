import 'package:intl/intl.dart';

/// Extensiones útiles para formateo de números y moneda
extension NumberExtension on num {
  /// Formatea el número como moneda
  String toCurrency({String symbol = '\$', int decimals = 2}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimals,
    );
    return formatter.format(this);
  }

  /// Formatea el número con separadores de miles
  String toFormatted({int decimals = 0}) {
    final pattern = decimals > 0 ? '#,##0.${'0' * decimals}' : '#,##0';
    final formatter = NumberFormat(pattern);
    return formatter.format(this);
  }

  /// Formatea como porcentaje
  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Retorna el valor absoluto formateado como moneda
  String toAbsCurrency({String symbol = '\$', int decimals = 2}) {
    return abs().toCurrency(symbol: symbol, decimals: decimals);
  }
}

extension DoubleExtension on double {
  /// Redondea a n decimales
  double roundTo(int decimals) {
    final mod = 1.0;
    for (int i = 0; i < decimals; i++) {
      mod * 10;
    }
    return (this * mod).round() / mod;
  }
}
