import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../models/auth_exception.dart';
import '../../models/auth_tokens.dart';
import '../../models/login_request.dart';
import '../../models/signup_request.dart';
import '../../models/user_profile.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokens> login(LoginRequest request);
  Future<UserProfile> register(SignUpRequest request);
  Future<UserProfile> getProfile(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({ApiClient? apiClient})
    : apiClient = apiClient ?? ApiClient();

  @override
  Future<AuthTokens> login(LoginRequest request) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw const AuthException(
          'Invalid or malformed response received from login server.',
        );
      }

      return AuthTokens.fromJson(data);
    } on DioException catch (e) {
      throw AuthException.fromDioException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Login failed: $e');
    }
  }

  @override
  Future<UserProfile> register(SignUpRequest request) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.users,
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw const AuthException(
          'Malformed response received from registration server.',
        );
      }

      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      throw AuthException.fromDioException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed: $e');
    }
  }

  @override
  Future<UserProfile> getProfile(String token) async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.profile,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw const AuthException(
          'Malformed response received from profile server.',
        );
      }

      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      throw AuthException.fromDioException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to retrieve profile: $e');
    }
  }
}
