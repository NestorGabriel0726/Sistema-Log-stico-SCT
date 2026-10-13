import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/invitation.dart';
import '../models/invitation_model.dart';

abstract class InvitationsRemoteDataSource {
  Future<List<InvitationModel>> getMyPendingInvitations();
  Future<void> acceptInvitation(String invitationId);
  Future<InvitationModel> createInvitation({
    required String email,
    required String congregationId,
    String? eventId,
    required InvitationRole role,
    String? assignedVehicleId,
    int expiresInDays,
  });
  Future<void> revokeInvitation(String invitationId);
}

class InvitationsRemoteDataSourceImpl implements InvitationsRemoteDataSource {
  final SupabaseClient _client;

  InvitationsRemoteDataSourceImpl({required this._client});

  @override
  Future<List<InvitationModel>> getMyPendingInvitations() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // 1. Tentar via Database RPC
      final rpcRes = await _client.rpc('get_my_pending_invitations');
      if (rpcRes is List) {
        return rpcRes
            .map((item) => InvitationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback para query direta via RLS
    }

    try {
      final email = (user.email ?? '').toLowerCase().trim();
      final res = await _client
          .from('invitations')
          .select('*, congregations(name), events(theme), vehicles(name)')
          .eq('status', 'PENDING')
          .gt('expires_at', DateTime.now().toIso8601String())
          .ilike('email', email)
          .order('created_at', ascending: false);

      return (res as List)
          .map((item) => InvitationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DomainFailure('Erro ao listar convites pendentes: $e');
    }
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    try {
      final res = await _client.rpc(
        'accept_invitation',
        params: {'p_invitation_id': invitationId},
      );
      if (res is Map && res['success'] == true) {
        return;
      }
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg.contains('EMAIL_MISMATCH')) {
        throw DomainFailure.fromCode('EMAIL_MISMATCH');
      } else if (msg.contains('INVITATION_EXPIRED')) {
        throw DomainFailure.fromCode('INVITATION_EXPIRED');
      } else if (msg.contains('INVITATION_NOT_PENDING')) {
        throw DomainFailure.fromCode('INVITATION_NOT_PENDING');
      } else if (msg.contains('INVITATION_NOT_FOUND')) {
        throw DomainFailure.fromCode('INVITATION_NOT_FOUND');
      } else if (msg.contains('PERMISSION_DENIED')) {
        throw DomainFailure.fromCode('PERMISSION_DENIED');
      }
      throw DomainFailure('Falha ao aceitar convite: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw DomainFailure('Não foi possível aceitar o convite: $e');
    }
  }

  @override
  Future<InvitationModel> createInvitation({
    required String email,
    required String congregationId,
    String? eventId,
    required InvitationRole role,
    String? assignedVehicleId,
    int expiresInDays = 7,
  }) async {
    try {
      final res = await _client.rpc(
        'create_invitation',
        params: {
          'p_email': email,
          'p_congregation_id': congregationId,
          'p_event_id': eventId,
          'p_role': invitationRoleToString(role),
          'p_assigned_vehicle_id': assignedVehicleId,
          'p_expires_in_days': expiresInDays,
        },
      );

      final invId = (res as Map)['invitation_id'] as String;
      // Carregar convite com joins
      final fullRes = await _client
          .from('invitations')
          .select('*, congregations(name), events(theme), vehicles(name)')
          .eq('id', invId)
          .single();

      return InvitationModel.fromJson(fullRes);
    } on PostgrestException catch (e) {
      if (e.message.contains('PERMISSION_DENIED')) {
        throw DomainFailure.fromCode('PERMISSION_DENIED');
      } else if (e.message.contains('INVALID_EMAIL')) {
        throw DomainFailure.fromCode('INVALID_EMAIL');
      } else if (e.message.contains('CONGREGATION_NOT_FOUND')) {
        throw DomainFailure.fromCode('CONGREGATION_NOT_FOUND');
      }
      throw DomainFailure('Falha ao criar convite: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw DomainFailure('Erro ao enviar convite: $e');
    }
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    try {
      await _client.rpc(
        'revoke_invitation',
        params: {'p_invitation_id': invitationId},
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('PERMISSION_DENIED')) {
        throw DomainFailure.fromCode('PERMISSION_DENIED');
      }
      throw DomainFailure('Falha ao revogar convite: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw DomainFailure('Erro ao revogar convite: $e');
    }
  }
}
