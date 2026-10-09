/// Exceções e Falhas de Domínio com tradução amigável em português.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

class DomainFailure extends Failure {
  const DomainFailure(super.message, {super.code});

  factory DomainFailure.fromCode(String code) {
    switch (code) {
      case 'PERMISSION_DENIED':
        return const DomainFailure(
          'Acesso negado. Você não possui permissão para executar esta ação.',
          code: 'PERMISSION_DENIED',
        );
      case 'EVENT_NOT_FOUND':
        return const DomainFailure(
          'Evento não localizado ou desativado.',
          code: 'EVENT_NOT_FOUND',
        );
      case 'PASSENGER_NOT_FOUND':
        return const DomainFailure(
          'Passageiro não encontrado.',
          code: 'PASSENGER_NOT_FOUND',
        );
      case 'VEHICLE_FULL':
        return const DomainFailure(
          'O veículo atingiu a sua capacidade máxima autorizada para este dia.',
          code: 'VEHICLE_FULL',
        );
      case 'PASSENGER_ALREADY_ALLOCATED':
        return const DomainFailure(
          'Este passageiro já está alocado em um veículo para este dia.',
          code: 'PASSENGER_ALREADY_ALLOCATED',
        );
      case 'DEADLINE_REQUIRES_BYPASS':
        return const DomainFailure(
          'O prazo limite de passagens foi ultrapassado. É necessária autorização do coordenador.',
          code: 'DEADLINE_REQUIRES_BYPASS',
        );
      case 'CHECKIN_NOT_ALLOWED':
        return const DomainFailure(
          'Você não possui permissão para realizar o check-in neste evento.',
          code: 'CHECKIN_NOT_ALLOWED',
        );
      case 'CHECKIN_NOT_ALLOWED_INACTIVE_ALLOCATION':
        return const DomainFailure(
          'Não é possível realizar check-in para uma alocação inativa ou já transferida.',
          code: 'CHECKIN_NOT_ALLOWED_INACTIVE_ALLOCATION',
        );
      case 'CANNOT_RELOCATE_TO_SAME_VEHICLE':
        return const DomainFailure(
          'O passageiro já se encontra neste mesmo veículo.',
          code: 'CANNOT_RELOCATE_TO_SAME_VEHICLE',
        );
      default:
        return DomainFailure(
          'Ocorreu uma falha na operação ($code). Tente novamente.',
          code: code,
        );
    }
  }
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Dispositivo sem conexão com a internet. Verifique sua rede.'])
      : super(code: 'NETWORK_ERROR');
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Falha na autenticação. Faça login novamente.'])
      : super(code: 'AUTH_ERROR');
}
