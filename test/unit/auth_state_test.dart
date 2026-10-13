import 'package:flutter_test/flutter_test.dart';
import 'package:transport_logistics/features/auth/domain/entities/user_profile.dart';
import 'package:transport_logistics/features/auth/presentation/providers/auth_state.dart';
import 'package:transport_logistics/features/congregations/domain/entities/congregation.dart';
import 'package:transport_logistics/features/invitations/domain/entities/invitation.dart';

void main() {
  group('Hierarquia e Estados de Autenticação (AuthState - Fase 1)', () {
    final testProfile = UserProfile(
      id: 'usr-1',
      email: 'coordenador@exemplo.com',
      fullName: 'Irmão Coordenador',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const testCongregation = Congregation(
      id: 'cong-1',
      name: 'Congregação Central',
      city: 'Curitiba',
      state: 'PR',
      countryCode: 'BR',
      currentUserRole: MemberRole.coordinator,
    );

    test('Instanciação de estados básicos', () {
      expect(const AuthStateInitializing(), isA<AuthState>());
      expect(const AuthStateUnauthenticated(), isA<AuthState>());
      expect(const AuthStateSessionExpired(), isA<AuthState>());
      expect(const AuthStateLoadingProfile(email: 'teste@exemplo.com'), isA<AuthState>());
    });

    test('Estado AuthStatePendingAuthorization carrega perfil sem congregações', () {
      final state = AuthStatePendingAuthorization(profile: testProfile);
      expect(state.profile.email, 'coordenador@exemplo.com');
      expect(state.profile.fullName, 'Irmão Coordenador');
    });

    test('Estado AuthStateHasPendingInvitations carrega perfil e lista de convites', () {
      final invitation = Invitation(
        id: 'inv-1',
        email: 'coordenador@exemplo.com',
        congregationId: 'cong-1',
        congregationName: 'Congregação Central',
        role: InvitationRole.busCaptain,
        status: InvitationStatus.pending,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      final state = AuthStateHasPendingInvitations(
        profile: testProfile,
        invitations: [invitation],
      );

      expect(state.invitations.length, 1);
      expect(state.invitations.first.congregationName, 'Congregação Central');
    });

    test('Estado AuthStateSelectCongregation carrega múltiplas congregações', () {
      const cong2 = Congregation(
        id: 'cong-2',
        name: 'Congregação Norte',
        city: 'Curitiba',
        state: 'PR',
        countryCode: 'BR',
      );

      final state = AuthStateSelectCongregation(
        profile: testProfile,
        congregations: [testCongregation, cong2],
      );

      expect(state.congregations.length, 2);
    });

    test('Estado AuthStateAuthorized define congregação ativa', () {
      final state = AuthStateAuthorized(
        profile: testProfile,
        activeCongregation: testCongregation,
      );

      expect(state.activeCongregation.name, 'Congregação Central');
      expect(state.profile.id, 'usr-1');
    });

    test('Estado AuthStateRecoverableError preserva mensagem e estado anterior', () {
      const previous = AuthStateUnauthenticated();
      const state = AuthStateRecoverableError(
        message: 'Falha de conexão com a internet',
        code: 'NETWORK_ERROR',
        previousState: previous,
      );

      expect(state.message, contains('Falha de conexão'));
      expect(state.code, 'NETWORK_ERROR');
      expect(state.previousState, isA<AuthStateUnauthenticated>());
    });
  });
}
