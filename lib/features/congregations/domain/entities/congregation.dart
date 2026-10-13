import 'package:flutter/foundation.dart';

enum MemberRole {
  admin,
  coordinator,
  captain,
  member,
}

MemberRole memberRoleFromString(String? role) {
  switch (role?.toUpperCase()) {
    case 'ADMIN':
      return MemberRole.admin;
    case 'COORDINATOR':
      return MemberRole.coordinator;
    case 'CAPTAIN':
      return MemberRole.captain;
    default:
      return MemberRole.member;
  }
}

String memberRoleToString(MemberRole role) {
  switch (role) {
    case MemberRole.admin:
      return 'ADMIN';
    case MemberRole.coordinator:
      return 'COORDINATOR';
    case MemberRole.captain:
      return 'CAPTAIN';
    case MemberRole.member:
      return 'MEMBER';
  }
}

String memberRoleDisplayName(MemberRole role) {
  switch (role) {
    case MemberRole.admin:
      return 'Administrador';
    case MemberRole.coordinator:
      return 'Coordenador';
    case MemberRole.captain:
      return 'Capitão';
    case MemberRole.member:
      return 'Membro';
  }
}

@immutable
class Congregation {
  final String id;
  final String name;
  final String? code;
  final String city;
  final String state;
  final String countryCode;
  final MemberRole? currentUserRole;
  final String status;

  const Congregation({
    required this.id,
    required this.name,
    this.code,
    required this.city,
    required this.state,
    this.countryCode = 'BR',
    this.currentUserRole,
    this.status = 'ACTIVE',
  });

  String get locationDescription => '$city, $state';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Congregation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          city == other.city &&
          state == other.state;

  @override
  int get hashCode => Object.hash(id, name, city, state);
}
