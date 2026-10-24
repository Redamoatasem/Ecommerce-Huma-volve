import '../entities/auth_tokens_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Authenticates user credentials via POST /auth/login and persists tokens.
  Future<AuthTokensEntity> login({
    required String email,
    required String password,
  });

  /// Registers a new user via POST /users/.
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    String? avatar,
  });

  /// Retrieves authenticated user profile via GET /auth/profile.
  Future<UserEntity> getProfile({String? explicitToken});

  /// Checks if an active session exists in secure storage.
  Future<bool> hasSession();

  /// Clears stored tokens upon user logout.
  Future<void> logout();
}
