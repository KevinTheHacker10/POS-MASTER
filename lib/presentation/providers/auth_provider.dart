import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matcha_lovers_506/data/repositories/auth_repository.dart';
import 'package:matcha_lovers_506/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(prefs);
});

/// State notifier for authentication
class AuthNotifier extends Notifier<AsyncValue<UserEntity?>> {
  late final AuthRepository _repository;

  @override
  AsyncValue<UserEntity?> build() {
    _repository = ref.watch(authRepositoryProvider);
    _loadCurrentUser();
    return const AsyncValue.loading();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      debugPrint('Load current user error: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await _repository.login(username, password);

      if (user != null) {
        state = AsyncValue.data(user);
        return true;
      } else {
        state = const AsyncValue.data(null);
        return false;
      }
    } catch (e, stack) {
      debugPrint('Login error: $e');
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Starts a temporary session for a customer using a self-service device.
  void startSelfService() {
    final now = DateTime.now();
    state = AsyncValue.data(
      UserEntity(
        id: 'self-service',
        username: 'autoservicio',
        password: '',
        role: UserRole.customer,
        fullName: 'Cliente Autoservicio',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Logout error: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> initializeSampleData() async {
    await _repository.initializeSampleData();
  }
}

/// Provider for authentication state
final authProvider =
    NotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>(() {
  return AuthNotifier();
});

/// Provider to check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// Provider to get current user
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
});
