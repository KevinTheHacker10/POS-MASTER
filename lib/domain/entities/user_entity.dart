import 'package:pos_master/core/constants.dart';

/// User entity - Domain layer
class UserEntity {
  final String id;
  final String username;
  final String password;
  final UserRole role;
  final String fullName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.fullName,
    required this.createdAt,
    required this.updatedAt,
  });

  UserEntity copyWith({
    String? id,
    String? username,
    String? password,
    UserRole? role,
    String? fullName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
