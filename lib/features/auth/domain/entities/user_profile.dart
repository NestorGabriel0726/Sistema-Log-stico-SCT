import 'package:flutter/foundation.dart';

/// Entidade de domínio representando o perfil de usuário autenticado.
@immutable
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Retorna um nome para exibição amigável
  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return 'Usuário';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode => Object.hash(id, email, fullName, avatarUrl);

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
