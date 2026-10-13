import 'package:flutter_test/flutter_test.dart';
import 'package:transport_logistics/features/invitations/domain/entities/invitation.dart';

void main() {
  group('Entidade Invitation e Enums de Convite (Fase 1)', () {
    test('Conversão e display do papel de convite (InvitationRole)', () {
      expect(invitationRoleFromString('COORDINATOR'), InvitationRole.coordinator);
      expect(invitationRoleFromString('COORDINATOR_HELPER'), InvitationRole.coordinatorHelper);
      expect(invitationRoleFromString('BUS_CAPTAIN'), InvitationRole.busCaptain);
      expect(invitationRoleFromString('CAPTAIN_HELPER'), InvitationRole.captainHelper);
      expect(invitationRoleFromString('DESCONHECIDO'), InvitationRole.busCaptain);

      expect(invitationRoleToString(InvitationRole.coordinator), 'COORDINATOR');
      expect(invitationRoleToString(InvitationRole.busCaptain), 'BUS_CAPTAIN');

      expect(invitationRoleDisplayName(InvitationRole.coordinator), 'Coordenador do Evento');
      expect(invitationRoleDisplayName(InvitationRole.busCaptain), 'Capitão de Veículo');
    });

    test('Conversão de InvitationStatus', () {
      expect(invitationStatusFromString('PENDING'), InvitationStatus.pending);
      expect(invitationStatusFromString('ACCEPTED'), InvitationStatus.accepted);
      expect(invitationStatusFromString('EXPIRED'), InvitationStatus.expired);
      expect(invitationStatusFromString('REVOKED'), InvitationStatus.revoked);
      expect(invitationStatusFromString('OUTRO'), InvitationStatus.pending);
    });

    test('Validação de expiração e status pendente na entidade Invitation', () {
      final now = DateTime.now();

      final activeInvitation = Invitation(
        id: 'inv-1',
        email: 'irmao@exemplo.com',
        congregationId: 'cong-1',
        congregationName: 'Congregação Central',
        role: InvitationRole.busCaptain,
        status: InvitationStatus.pending,
        expiresAt: now.add(const Duration(days: 7)),
        createdAt: now,
      );

      expect(activeInvitation.isPending, isTrue);
      expect(activeInvitation.isExpired, isFalse);
      expect(activeInvitation.roleDisplay, 'Capitão de Veículo');

      final expiredInvitation = Invitation(
        id: 'inv-2',
        email: 'irmao@exemplo.com',
        congregationId: 'cong-1',
        congregationName: 'Congregação Central',
        role: InvitationRole.captainHelper,
        status: InvitationStatus.pending,
        expiresAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 8)),
      );

      expect(expiredInvitation.isExpired, isTrue);
    });
  });
}
