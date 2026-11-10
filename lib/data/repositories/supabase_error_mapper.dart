import '../../domain/models.dart';

StoreResult mapSupabaseError(Object error) {
  final text = error.toString();
  const codes = <String, String>{
    'PERMISSION_DENIED': 'Sem permissão para esta operação.',
    'VEHICLE_FULL': 'Veículo lotado neste dia.',
    'PASSENGER_ALREADY_ALLOCATED': 'Passageiro já alocado neste dia.',
    'PASSENGER_NOT_FOUND': 'Passageiro não encontrado.',
    'VEHICLE_NOT_FOUND': 'Veículo não encontrado.',
    'ALLOCATION_NOT_FOUND_OR_INACTIVE': 'Alocação não encontrada ou inativa.',
    'CANNOT_RELOCATE_TO_SAME_VEHICLE': 'O passageiro já está neste veículo.',
    'CHECKIN_NOT_ALLOWED_INACTIVE_ALLOCATION':
        'Check-in permitido apenas para alocações ativas.',
    'CHECKIN_NOT_ALLOWED': 'Check-in não autorizado para o seu perfil.',
    'PASSAGE_NOT_FOUND': 'Passagem não encontrada.',
    'INVALID_AMOUNT': 'Valor inválido.',
    'STOP_NOT_IN_VEHICLE': 'O ponto de parada não pertence a este veículo.',
    'STOP_REQUIRED': 'Selecione um ponto de parada válido.',
    'EVENT_NOT_FOUND': 'Evento não encontrado.',
    'CHECKIN_NOT_FOUND': 'Check-in não encontrado.',
  };
  for (final entry in codes.entries) {
    if (text.contains(entry.key)) {
      return StoreResult.error(entry.value);
    }
  }
  return StoreResult.error('Falha de comunicação com o servidor.');
}
