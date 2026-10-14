import 'package:intl/intl.dart';

import '../domain/models.dart';

abstract class AppFormatters {
  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  static final _date = DateFormat('dd/MM/yyyy');
  static final _dateShort = DateFormat('dd/MM');

  static String cents(int value) => _currency.format(value / 100);

  static String date(DateTime d) => _date.format(d);

  static String dateRange(DateTime start, DateTime end) =>
      '${_dateShort.format(start)} – ${_dateShort.format(end)}';

  static String weekday(DateTime d) => switch (d.weekday) {
        DateTime.monday => 'Segunda-feira',
        DateTime.tuesday => 'Terça-feira',
        DateTime.wednesday => 'Quarta-feira',
        DateTime.thursday => 'Quinta-feira',
        DateTime.friday => 'Sexta-feira',
        DateTime.saturday => 'Sábado',
        _ => 'Domingo',
      };

  static FinancialStatus fromCode(String code) => switch (code) {
        'NOT_APPLICABLE' => FinancialStatus.notApplicable,
        'UNPAID' => FinancialStatus.unpaid,
        'PARTIALLY_PAID' => FinancialStatus.partial,
        'PAID' => FinancialStatus.paid,
        _ => FinancialStatus.overpaid,
      };
}
