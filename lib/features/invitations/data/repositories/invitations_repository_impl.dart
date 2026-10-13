import '../../domain/entities/invitation.dart';
import '../../domain/repositories/invitations_repository.dart';
import '../datasources/invitations_remote_data_source.dart';

class InvitationsRepositoryImpl implements InvitationsRepository {
  final InvitationsRemoteDataSource _remoteDataSource;

  InvitationsRepositoryImpl({required this._remoteDataSource});

  @override
  Future<List<Invitation>> getMyPendingInvitations() {
    return _remoteDataSource.getMyPendingInvitations();
  }

  @override
  Future<void> acceptInvitation(String invitationId) {
    return _remoteDataSource.acceptInvitation(invitationId);
  }

  @override
  Future<Invitation> createInvitation({
    required String email,
    required String congregationId,
    String? eventId,
    required InvitationRole role,
    String? assignedVehicleId,
    int expiresInDays = 7,
  }) {
    return _remoteDataSource.createInvitation(
      email: email,
      congregationId: congregationId,
      eventId: eventId,
      role: role,
      assignedVehicleId: assignedVehicleId,
      expiresInDays: expiresInDays,
    );
  }

  @override
  Future<void> revokeInvitation(String invitationId) {
    return _remoteDataSource.revokeInvitation(invitationId);
  }
}
