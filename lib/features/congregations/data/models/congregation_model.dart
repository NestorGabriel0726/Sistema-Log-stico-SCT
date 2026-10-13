import '../../domain/entities/congregation.dart';

class CongregationModel extends Congregation {
  const CongregationModel({
    required super.id,
    required super.name,
    super.code,
    required super.city,
    required super.state,
    super.countryCode = 'BR',
    super.currentUserRole,
    super.status = 'ACTIVE',
  });

  factory CongregationModel.fromJson(Map<String, dynamic> json) {
    return CongregationModel(
      id: (json['congregation_id'] ?? json['id']) as String,
      name: json['name'] as String? ?? 'Congregação',
      code: json['code'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? 'BR',
      currentUserRole: json['member_role'] != null
          ? memberRoleFromString(json['member_role'] as String)
          : (json['role'] != null ? memberRoleFromString(json['role'] as String) : null),
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'city': city,
      'state': state,
      'country_code': countryCode,
      if (currentUserRole != null) 'member_role': memberRoleToString(currentUserRole!),
      'status': status,
    };
  }
}
