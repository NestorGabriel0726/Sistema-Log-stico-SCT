import 'package:flutter_test/flutter_test.dart';
import 'package:transport_logistics/core/error/failures.dart';

void main() {
  group('Regra 89: Tratamento e Tradução Amigável de Erros de Domínio', () {
    test('Código PERMISSION_DENIED deve gerar mensagem amigável de autorização', () {
      final failure = DomainFailure.fromCode('PERMISSION_DENIED');
      expect(failure.message, contains('Acesso negado'));
    });

    test('Código VEHICLE_FULL deve informar capacidade atingida', () {
      final failure = DomainFailure.fromCode('VEHICLE_FULL');
      expect(failure.message, contains('capacidade máxima autorizada'));
    });

    test('Código DEADLINE_REQUIRES_BYPASS deve informar necessidade de autorização', () {
      final failure = DomainFailure.fromCode('DEADLINE_REQUIRES_BYPASS');
      expect(failure.message, contains('prazo limite'));
    });
  });
}
