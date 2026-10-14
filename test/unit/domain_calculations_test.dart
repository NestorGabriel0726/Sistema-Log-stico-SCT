import 'package:flutter_test/flutter_test.dart';
import 'package:transport_logistics/core/formatters.dart';
import 'package:transport_logistics/core/utils/domain_calculations.dart';

void main() {
  group('Cálculos de domínio', () {
    test('isenção por idade', () {
      final eventDate = DateTime(2026, 10, 10);
      expect(
        DomainCalculations.isExemptByAge(
          birthDate: DateTime(2020, 10, 11),
          eventDate: eventDate,
          minimumPayingAge: 6,
        ),
        isTrue,
      );
    });

    test('valor da passagem em centavos', () {
      final due = DomainCalculations.calculatePassengerDueCents(
        selectedDaysCount: 3,
        dailyFareCents: 5000,
        isExempt: false,
      );
      expect(due, 15000);
      expect(AppFormatters.cents(due), contains('150,00'));
    });
  });
}
