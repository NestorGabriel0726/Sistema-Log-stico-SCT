import 'package:flutter/foundation.dart';

enum InvitationRole {
  coordinator,
  coordinatorHelper,
  busCaptain,
  captainHelper,
}

InvitationRole invitationRoleFromString(String? role) {
  switch (role?.toUpperCase()) {
    case 'COORDINATOR':
      return InvitationRole.coordinator;
    case 'COORDINATOR_HELPER':
      return InvitationRole.coordinatorHelper;
    case 'BUS_CAPTAIN':
      return InvitationRole.busCaptain;
    case 'CAPTAIN_HELPER':
      return InvitationRole.captainHelper;
    default:
      return InvitationRole.busCaptain;
  }
}

String invitationRoleToString(InvitationRole role) {
  switch (role) {
    case InvitationRole.coordinator:
      return 'COORDINATOR';
    case InvitationRole.coordinatorHelper:
      return 'COORDINATOR_HELPER';
    case InvitationRole.busCaptain:
      return 'BUS_CAPTAIN';
    case InvitationRole.captainHelper:
      return 'CAPTAIN_HELPER';
  }
}

String invitationRoleDisplayName(InvitationRole role) {
  switch (role) {
    case InvitationRole.coordinator:
      return 'Coordenador do Evento';
    case InvitationRole.coordinatorHelper:
      return 'Ajudante do Coordenador';
    case InvitationRole.busCaptain:
      return 'Capitão de Veículo';
    case InvitationRole.captainHelper:
      return 'Ajudante de Capitão';
  }
}

enum InvitationStatus {
  pending,
  accepted,
  expired,
  revoked,
}

InvitationStatus invitationStatusFromString(String? status) {
  switch (status?.toUpperCase()) {
    case 'ACCEPTED':
      return InvitationStatus.accepted;
    case 'EXPIRED':
      return InvitationStatus.expired;
    case 'REVOKED':
      return InvitationStatus.revoked;
    default:
      return InvitationStatus.pending;
  }
}

@immutable
class Invitation {
  final String id;
  final String email;
  final String congregationId;
  final String congregationName;
  final String? eventId;
  final String? eventTheme;
  final InvitationRole role;
  final String? assignedVehicleId;
  final String? vehicleName;
  final InvitationStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const Invitation({
    required this.id,
    required this.email,
    required this.congregationId,
    required this.congregationName,
    this.eventId,
    this.eventTheme,
    required this.role,
    this.assignedVehicleId,
    this.vehicleName,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.acceptedAt,
  });

  bool get isPending => status == InvitationStatus.pending;
  bool get isExpired => status == InvitationStatus.expired || DateTime.now().isAfter(expiresAt);

  String get roleDisplay => invitationRoleDisplayName(role);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invitation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, email, status);
}
