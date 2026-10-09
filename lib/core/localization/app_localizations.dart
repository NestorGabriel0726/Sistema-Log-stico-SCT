import 'package:intl/intl.dart';

/// Utilitários de internacionalização e formatação oficial do sistema.
abstract class AppFormatters {
  static final NumberFormat _currencyFormatBrl = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormatBr = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormatBr = DateFormat('dd/MM/yyyy HH:mm');

  /// Formata centavos inteiros para moeda (Ex: 3550 -> "R$ 35,50")
  static String formatCents(int cents, {String currencyCode = 'BRL'}) {
    final double value = cents / 100.0;
    if (currencyCode == 'BRL') {
      return _currencyFormatBrl.format(value);
    }
    return NumberFormat.simpleCurrency(name: currencyCode).format(value);
  }

  /// Formata data civil (YYYY-MM-DD) para exibição amigável
  static String formatDate(DateTime date) {
    return _dateFormatBr.format(date);
  }

  /// Formata data e hora
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatBr.format(dateTime.toLocal());
  }

  /// Mascara CPF para exibição segura (Ex: "123.***.***-00")
  static String maskCpf(String? cpf) {
    if (cpf == null || cpf.trim().isEmpty) return '-';
    final cleaned = cpf.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 11) return cpf;
    return '${cleaned.substring(0, 3)}.***.***-${cleaned.substring(9)}';
  }
}
