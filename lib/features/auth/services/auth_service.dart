import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_exception.dart';
import '../models/auth_tokens.dart';
import '../models/login_request.dart';
import '../models/signup_request.dart';
import '../models/user_profile.dart';

class AuthService {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : apiClient = apiClient ?? ApiClient(),
        tokenStorage = tokenStorage ?? SecureTokenStorage();

  /// Authenticates user credentials via POST /auth/login.
  /// On success, parses and securely persists the access token.
  Future<AuthTokens> login(LoginRequest request) async {
    if (request.email.trim().isEmpty || request.password.isEmpty) {
      throw const AuthException('Email and password must not be empty.');
    }

    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw const AuthException('Invalid or malformed response received from login server.');
      }

      final tokens = AuthTokens.fromJson(data);
      await tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      return tokens;
    } on DioException catch (e) {
      throw AuthException.fromDioException(e);
    } on FormatException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Login failed: $e');
    }
  }

  /// Registers a new user via POST /users/.
  /// Does NOT automatically persist session or log the user in.
  Future<UserProfile> register(SignUpRequest request) async {
    if (request.name.trim().isEmpty) {
      throw const AuthException('Full name is required.');
    }
    if (request.email.trim().isEmpty) {
      throw const AuthException('Email address is required.');
    }
    if (request.password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.users,
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw const AuthException('Malformed response received from registration server.');
      }

      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      throw AuthException.fromDioException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed: $e');
    }
  }

  /// Retrieves authenticated user profile via GET /auth/profile.
  /// Uses [explicitToken] if provided, otherwise reads stored access token.
  Future<UserProfile> getProfile({String? explicitToken}) async {
    final token = explicitToken ?? await tokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const AuthException(
        'Authentication required: No valid session token found.',
        statusCode: 401,
      );
    }

    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.profile,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw const AuthException('Malformed response received from profile server.');
      }

      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      throw AuthException.fromDioException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to retrieve profile: $e');
    }
  }

  /// Checks whether an authenticated session exists in secure storage.
  Future<bool> hasSession() async {
    return tokenStorage.hasAccessToken();
  }

  /// Clears stored tokens upon logout.
  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }
}

