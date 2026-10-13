import '../entities/invitation.dart';

abstract class InvitationsRepository {
  /// Retorna os convites pendentes e não-expirados destinados ao e-mail autenticado
  Future<List<Invitation>> getMyPendingInvitations();

  /// Aceita um convite atômico validado pelo backend
  Future<void> acceptInvitation(String invitationId);

  /// Cria um novo convite (Apenas Coordenadores ou Admins autorizados)
  Future<Invitation> createInvitation({
    required String email,
    required String congregationId,
    String? eventId,
    required InvitationRole role,
    String? assignedVehicleId,
    int expiresInDays = 7,
  });

  /// Revoga um convite existente (Apenas autorizados)
  Future<void> revokeInvitation(String invitationId);
}
