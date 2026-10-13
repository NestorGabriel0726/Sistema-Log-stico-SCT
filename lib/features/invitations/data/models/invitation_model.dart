import '../../domain/entities/invitation.dart';

class InvitationModel extends Invitation {
  const InvitationModel({
    required super.id,
    required super.email,
    required super.congregationId,
    required super.congregationName,
    super.eventId,
    super.eventTheme,
    required super.role,
    super.assignedVehicleId,
    super.vehicleName,
    required super.status,
    required super.expiresAt,
    required super.createdAt,
    super.acceptedAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: (json['invitation_id'] ?? json['id']) as String,
      email: json['email'] as String? ?? '',
      congregationId: json['congregation_id'] as String,
      congregationName: json['congregation_name'] as String? ??
          (json['congregations']?['name'] as String?) ??
          'Congregação',
      eventId: json['event_id'] as String?,
      eventTheme: json['event_theme'] as String? ??
          (json['events']?['theme'] as String?),
      role: invitationRoleFromString(json['role'] as String?),
      assignedVehicleId: json['assigned_vehicle_id'] as String?,
      vehicleName: json['vehicle_name'] as String? ??
          (json['vehicles']?['name'] as String?),
      status: invitationStatusFromString(json['status'] as String?),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'congregation_id': congregationId,
      'congregation_name': congregationName,
      'event_id': eventId,
      'event_theme': eventTheme,
      'role': invitationRoleToString(role),
      'assigned_vehicle_id': assignedVehicleId,
      'vehicle_name': vehicleName,
      'status': status.name.toUpperCase(),
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
    };
  }
}
