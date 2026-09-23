import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pos_master/core/constants.dart';
import 'package:pos_master/data/models/user_model.dart';
import 'package:pos_master/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Repository for authentication operations
class AuthRepository {
  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  AuthRepository(this._prefs);

  /// Initialize with sample users
  Future<void> initializeSampleData() async {
    final users = await getAllUsers();
    if (users.isEmpty) {
      final now = DateTime.now();
      final sampleUsers = [
        UserModel(
          id: _uuid.v4(),
          username: 'admin',
          password: 'admin123',
          role: UserRole.admin,
          fullName: 'Administrador Principal',
          createdAt: now,
          updatedAt: now,
        ),
        UserModel(
          id: _uuid.v4(),
          username: 'mesero',
          password: 'mesero123',
          role: UserRole.waiter,
          fullName: 'Mesero Demo',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (var user in sampleUsers) {
        await _saveUser(user);
      }
      debugPrint('Sample users initialized');
    }
  }

  /// Login user
  Future<UserEntity?> login(String username, String password) async {
    try {
      final users = await getAllUsers();
      final user = users.firstWhere(
        (u) => u.username == username && u.password == password,
        orElse: () => throw Exception('Invalid credentials'),
      );
      await _prefs.setString(AppConstants.storageKeyCurrentUser, user.id);
      return user;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _prefs.remove(AppConstants.storageKeyCurrentUser);
  }

  /// Get current logged-in user
  Future<UserEntity?> getCurrentUser() async {
    try {
      final userId = _prefs.getString(AppConstants.storageKeyCurrentUser);
      if (userId == null) return null;
      final users = await getAllUsers();
      return users.firstWhere(
        (u) => u.id == userId,
        orElse: () => throw Exception('User not found'),
      );
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final usersJson =
          _prefs.getStringList(AppConstants.storageKeyUsers) ?? [];
      return usersJson
          .map((json) =>
              UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Get all users error: $e');
      return [];
    }
  }

  /// Save entire user list (overwrites)
  Future<void> _saveAllUsers(List<UserModel> users) async {
    final usersJson = users.map((u) => jsonEncode(u.toJson())).toList();
    await _prefs.setStringList(AppConstants.storageKeyUsers, usersJson);
  }

  /// Append a new user
  Future<void> _saveUser(UserModel user) async {
    final users = await getAllUsers();
    users.add(user);
    await _saveAllUsers(users);
  }

  /// Create new user
  Future<UserEntity?> createUser({
    required String username,
    required String password,
    required UserRole role,
    required String fullName,
  }) async {
    try {
      final now = DateTime.now();
      final user = UserModel(
        id: _uuid.v4(),
        username: username,
        password: password,
        role: role,
        fullName: fullName,
        createdAt: now,
        updatedAt: now,
      );
      await _saveUser(user);
      return user;
    } catch (e) {
      debugPrint('Create user error: $e');
      return null;
    }
  }

  /// Update an existing user — fixes the empty stub
  Future<void> updateUser(UserEntity user, {String? newPassword}) async {
    try {
      final users = await getAllUsers();
      final idx = users.indexWhere((u) => u.id == user.id);
      if (idx == -1) {
        debugPrint('updateUser: user ${user.id} not found');
        return;
      }

      // Keep existing password if caller didn't supply a new one
      final passwordToSave =
          (newPassword != null && newPassword.isNotEmpty)
              ? newPassword
              : users[idx].password;

      users[idx] = UserModel(
        id: user.id,
        username: user.username,
        password: passwordToSave,
        fullName: user.fullName,
        role: user.role,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );

      await _saveAllUsers(users);
      debugPrint('User updated: ${user.id}');
    } catch (e) {
      debugPrint('updateUser error: $e');
    }
  }

  /// Delete a user by ID — fixes the empty stub
  Future<void> deleteUser(String userId) async {
    try {
      final users = await getAllUsers();
      final filtered = users.where((u) => u.id != userId).toList();
      await _saveAllUsers(filtered);
      debugPrint('User deleted: $userId');
    } catch (e) {
      debugPrint('deleteUser error: $e');
    }
  }
}
