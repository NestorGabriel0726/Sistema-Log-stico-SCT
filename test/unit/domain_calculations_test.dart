import 'package:flutter_test/flutter_test.dart';
import 'package:transport_logistics/core/utils/domain_calculations.dart';
import 'package:transport_logistics/core/localization/app_localizations.dart';

void main() {
  group('Regra 22 & 138: Cálculo de Idade na Data do Evento e Isenção', () {
    final eventDate = DateTime(2026, 10, 10);
    const minimumPayingAge = 6;

    test('Criança nascida um dia após a data do evento (2020-10-11) tem 5 anos -> ISENTA', () {
      final birthDate = DateTime(2020, 10, 11);

      final age = DomainCalculations.calculateAgeOnDate(
        birthDate: birthDate,
        targetDate: eventDate,
      );

      final isExempt = DomainCalculations.isExemptByAge(
        birthDate: birthDate,
        eventDate: eventDate,
        minimumPayingAge: minimumPayingAge,
      );

      expect(age, equals(5));
      expect(isExempt, isTrue);
    });

    test('Criança nascida exatamente no dia correspondente (2020-10-10) completa 6 anos -> PAGANTE', () {
      final birthDate = DateTime(2020, 10, 10);

      final age = DomainCalculations.calculateAgeOnDate(
        birthDate: birthDate,
        targetDate: eventDate,
      );

      final isExempt = DomainCalculations.isExemptByAge(
        birthDate: birthDate,
        eventDate: eventDate,
        minimumPayingAge: minimumPayingAge,
      );

      expect(age, equals(6));
      expect(isExempt, isFalse);
    });

    test('Criança nascida antes do evento (2020-10-09) já possui 6 anos -> PAGANTE', () {
      final birthDate = DateTime(2020, 10, 9);

      final age = DomainCalculations.calculateAgeOnDate(
        birthDate: birthDate,
        targetDate: eventDate,
      );

      final isExempt = DomainCalculations.isExemptByAge(
        birthDate: birthDate,
        eventDate: eventDate,
        minimumPayingAge: minimumPayingAge,
      );

      expect(age, equals(6));
      expect(isExempt, isFalse);
    });
  });

  group('Regras 30, 33 & 34: Cálculos Financeiros e Status de Pagamento', () {
    const dailyFareCents = 5000; // R$ 50,00 por dia

    test('Cálculo de passageiro individual (3 dias = R\$ 150,00)', () {
      final due = DomainCalculations.calculatePassengerDueCents(
        selectedDaysCount: 3,
        dailyFareCents: dailyFareCents,
        isExempt: false,
      );

      expect(due, equals(15000));
      expect(AppFormatters.formatCents(due), equals('R\$\u00a0150,00'));
    });

    test('Passageiro isento deve ter valor devido zerado (0 centavos)', () {
      final due = DomainCalculations.calculatePassengerDueCents(
        selectedDaysCount: 3,
        dailyFareCents: dailyFareCents,
        isExempt: true,
      );

      expect(due, equals(0));
      expect(AppFormatters.formatCents(due), equals('R\$\u00a00,00'));
    });

    test('Transição de status de pagamento (Esperado: R\$ 250,00)', () {
      const expectedCents = 25000;

      // 1. Não pago
      expect(
        DomainCalculations.calculateFinancialStatus(expectedCents: expectedCents, paidCents: 0),
        equals('UNPAID'),
      );

      // 2. Parcialmente pago (R$ 100,00)
      expect(
        DomainCalculations.calculateFinancialStatus(expectedCents: expectedCents, paidCents: 10000),
        equals('PARTIALLY_PAID'),
      );

      // 3. Pago integralmente (R$ 250,00)
      expect(
        DomainCalculations.calculateFinancialStatus(expectedCents: expectedCents, paidCents: 25000),
        equals('PAID'),
      );

      // 4. Pago a maior (R$ 300,00)
      expect(
        DomainCalculations.calculateFinancialStatus(expectedCents: expectedCents, paidCents: 30000),
        equals('OVERPAID'),
      );
    });
  });

  group('Segurança & Formatação: Mascaramento de CPF (Seção 94)', () {
    test('CPF deve ser mascarado nas visualizações padrão', () {
      final masked = AppFormatters.maskCpf('111.222.333-44');
      expect(masked, equals('111.***.***-44'));
    });
  });
}
