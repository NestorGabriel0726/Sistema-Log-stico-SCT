import 'package:flutter_test/flutter_test.dart';
import 'package:transport_logistics/core/formatters.dart';
import 'package:transport_logistics/core/utils/domain_calculations.dart';

void main() {
  group('Cálculos de domínio - Idade e Isenção', () {
    final eventDate = DateTime(2026, 10, 15);
    const minAge = 6;
    const eventTheme = 'Assembleia de Circuito';

    test('cálculo de idade: antes do aniversário (ainda não completou)', () {
      // Nasceu em 20 de outubro de 2020 -> em 15/10/2026 tem 5 anos
      final birth = DateTime(2020, 10, 20);
      final age = DomainCalculations.calculateAgeOnDate(
        birthDate: birth,
        targetDate: eventDate,
      );
      expect(age, 5);
      expect(
        DomainCalculations.isExemptByAge(
          birthDate: birth,
          eventDate: eventDate,
          minimumPayingAge: minAge,
        ),
        isTrue,
      );
    });

    test('cálculo de idade: exatamente no dia do aniversário', () {
      // Nasceu em 15 de outubro de 2020 -> em 15/10/2026 completa 6 anos
      final birth = DateTime(2020, 10, 15);
      final age = DomainCalculations.calculateAgeOnDate(
        birthDate: birth,
        targetDate: eventDate,
      );
      expect(age, 6);
      expect(
        DomainCalculations.isExemptByAge(
          birthDate: birth,
          eventDate: eventDate,
          minimumPayingAge: minAge,
        ),
        isFalse, // Tem 6 anos completos, igual à mínima -> pagante
      );
    });

    test('cálculo de idade: após o aniversário', () {
      // Nasceu em 10 de outubro de 2020 -> em 15/10/2026 já fez 6 anos
      final birth = DateTime(2020, 10, 10);
      final age = DomainCalculations.calculateAgeOnDate(
        birthDate: birth,
        targetDate: eventDate,
      );
      expect(age, 6);
      expect(
        DomainCalculations.isExemptByAge(
          birthDate: birth,
          eventDate: eventDate,
          minimumPayingAge: minAge,
        ),
        isFalse,
      );
    });

    test('mensagens de elegibilidade conforme especificação', () {
      // Sem data de nascimento
      final msgSemData = DomainCalculations.ageEligibilityMessage(
        birthDate: null,
        eventDate: eventDate,
        minimumPayingAge: minAge,
        eventTheme: eventTheme,
      );
      expect(msgSemData, contains('o cálculo da isenção ainda não pode ser realizado'));

      // Abaixo da idade mínima (isento)
      final msgIsento = DomainCalculations.ageEligibilityMessage(
        birthDate: DateTime(2021, 5, 1),
        eventDate: eventDate,
        minimumPayingAge: minAge,
        eventTheme: eventTheme,
      );
      expect(msgIsento, 'Isento de pagamento: a idade na data do Assembleia de Circuito será de 5 anos, inferior à idade mínima para cobrança de 6 anos.');

      // Igual ou superior à idade mínima (pagante)
      final msgPagante = DomainCalculations.ageEligibilityMessage(
        birthDate: DateTime(2020, 10, 15),
        eventDate: eventDate,
        minimumPayingAge: minAge,
        eventTheme: eventTheme,
      );
      expect(msgPagante, 'A idade na data do Assembleia de Circuito será de 6 anos. Como é igual ou superior à idade mínima para cobrança de 6 anos, o valor da passagem deve ser cobrado.');
    });

    test('valor da passagem em centavos respeita isenção', () {
      final duePagante = DomainCalculations.calculatePassengerDueCents(
        selectedDaysCount: 3,
        dailyFareCents: 5000,
        isExempt: false,
      );
      expect(duePagante, 15000);
      expect(AppFormatters.cents(duePagante), contains('150,00'));

      final dueIsento = DomainCalculations.calculatePassengerDueCents(
        selectedDaysCount: 3,
        dailyFareCents: 5000,
        isExempt: true,
      );
      expect(dueIsento, 0);
      expect(AppFormatters.cents(dueIsento), contains('0,00'));
    });
  });
}
