import 'package:flutter_test/flutter_test.dart';
import 'package:transport_logistics/features/congregations/domain/entities/congregation.dart';

void main() {
  group('Entidade Congregation e Papéis de Membro (Fase 1)', () {
    test('Conversão e display de MemberRole', () {
      expect(memberRoleFromString('ADMIN'), MemberRole.admin);
      expect(memberRoleFromString('COORDINATOR'), MemberRole.coordinator);
      expect(memberRoleFromString('CAPTAIN'), MemberRole.captain);
      expect(memberRoleFromString('MEMBER'), MemberRole.member);
      expect(memberRoleFromString('QUALQUER'), MemberRole.member);

      expect(memberRoleToString(MemberRole.admin), 'ADMIN');
      expect(memberRoleToString(MemberRole.coordinator), 'COORDINATOR');
      expect(memberRoleToString(MemberRole.captain), 'CAPTAIN');
      expect(memberRoleToString(MemberRole.member), 'MEMBER');

      expect(memberRoleDisplayName(MemberRole.coordinator), 'Coordenador');
      expect(memberRoleDisplayName(MemberRole.captain), 'Capitão');
    });

    test('Instanciação da entidade Congregation com papel ativo', () {
      const cong = Congregation(
        id: 'cong-1',
        name: 'Congregação Jardim das Flores',
        code: 'SP-012',
        city: 'São Paulo',
        state: 'SP',
        countryCode: 'BR',
        currentUserRole: MemberRole.coordinator,
      );

      expect(cong.id, 'cong-1');
      expect(cong.name, 'Congregação Jardim das Flores');
      expect(cong.currentUserRole, MemberRole.coordinator);
      expect(cong.status, 'ACTIVE');
    });
  });
}
