import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ecommerce_app_huma_volve/core/constants/api_constants.dart';
import 'package:ecommerce_app_huma_volve/core/constants/api_endpoints.dart';
import 'package:ecommerce_app_huma_volve/core/network/api_client.dart';
import 'package:ecommerce_app_huma_volve/core/storage/token_storage.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/auth_exception.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/login_request.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/signup_request.dart';
import 'package:ecommerce_app_huma_volve/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test HTTP Adapter to mock Dio responses and capture requests
class MockHttpClientAdapter implements HttpClientAdapter {
  late Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}

  static ResponseBody jsonResponse(
    dynamic data, {
    int statusCode = 200,
    Map<String, List<String>>? headers,
  }) {
    final bodyString = jsonEncode(data);
    return ResponseBody.fromString(
      bodyString,
      statusCode,
      headers: {
        'content-type': ['application/json; charset=utf-8'],
        ...?headers,
      },
    );
  }
}

void main() {
  late MockHttpClientAdapter mockAdapter;
  late Dio dio;
  late ApiClient apiClient;
  late InMemoryTokenStorage tokenStorage;
  late AuthService authService;

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    dio.httpClientAdapter = mockAdapter;
    apiClient = ApiClient(customDio: dio);
    tokenStorage = InMemoryTokenStorage();
    authService = AuthService(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
  });

  group('AuthService - Login', () {
    test('1. Successful login and token parsing with persistence', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.login);
        expect(options.method, 'POST');
        final data = options.data as Map<String, dynamic>;
        expect(data['email'], 'john@mail.com');
        expect(data['password'], 'changeme');

        return MockHttpClientAdapter.jsonResponse({
          'access_token': 'test_access_jwt_token',
          'refresh_token': 'test_refresh_jwt_token',
        });
      };

      final tokens = await authService.login(
        const LoginRequest(email: 'john@mail.com', password: 'changeme'),
      );

      expect(tokens.accessToken, 'test_access_jwt_token');
      expect(tokens.refreshToken, 'test_refresh_jwt_token');

      // Verify token persistence
      expect(await tokenStorage.getAccessToken(), 'test_access_jwt_token');
      expect(await tokenStorage.getRefreshToken(), 'test_refresh_jwt_token');
      expect(await tokenStorage.hasAccessToken(), isTrue);
    });

    test('2. Rejected login credentials (401 Unauthorized)', () async {
      mockAdapter.handler = (options) async {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {'message': 'Unauthorized', 'statusCode': 401},
          ),
          type: DioExceptionType.badResponse,
        );
      };

      expect(
        () => authService.login(
          const LoginRequest(email: 'john@mail.com', password: 'wrongpassword'),
        ),
        throwsA(
          isA<AuthException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having(
                (e) => e.message,
                'message',
                'Invalid email or password. Please try again.',
              ),
        ),
      );

      // Verify no token was saved
      expect(await tokenStorage.hasAccessToken(), isFalse);
    });

    test('3. Network failure and connection timeout handling', () async {
      mockAdapter.handler = (options) async {
        throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 5),
          requestOptions: options,
        );
      };

      expect(
        () => authService.login(
          const LoginRequest(email: 'user@test.com', password: 'password123'),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Connection timed out'),
          ),
        ),
      );
    });

    test('4. Malformed authentication response (missing access_token)', () async {
      mockAdapter.handler = (options) async {
        return MockHttpClientAdapter.jsonResponse({
          'unexpected_field': 'no_token_here',
        });
      };

      expect(
        () => authService.login(
          const LoginRequest(email: 'user@test.com', password: 'password123'),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('missing valid access_token'),
          ),
        ),
      );
    });
  });

  group('AuthService - Profile', () {
    test('5. Successful profile retrieval with Authorization header', () async {
      await tokenStorage.saveTokens(accessToken: 'valid_bearer_token');

      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.profile);
        expect(options.method, 'GET');
        expect(options.headers['Authorization'], 'Bearer valid_bearer_token');

        return MockHttpClientAdapter.jsonResponse({
          'id': 1,
          'email': 'john@mail.com',
          'name': 'Jhon Doe',
          'role': 'customer',
          'avatar': 'https://i.imgur.com/LDOO4Qs.jpg',
          'creationAt': '2026-10-23T16:35:16.000Z',
          'updatedAt': '2026-10-23T16:35:16.000Z',
        });
      };

      final profile = await authService.getProfile();

      expect(profile.id, 1);
      expect(profile.email, 'john@mail.com');
      expect(profile.name, 'Jhon Doe');
      expect(profile.role, 'customer');
      expect(profile.avatar, 'https://i.imgur.com/LDOO4Qs.jpg');
      expect(profile.creationAt, isNotNull);
    });

    test('6. Failed profile retrieval without authenticated session or 401 response', () async {
      // Test A: No token present in storage
      expect(
        () => authService.getProfile(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('No valid session token found'),
          ),
        ),
      );

      // Test B: Token present but expired/rejected by server
      await tokenStorage.saveTokens(accessToken: 'expired_token');
      mockAdapter.handler = (options) async {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        );
      };

      expect(
        () => authService.getProfile(),
        throwsA(isA<AuthException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });

  group('AuthService - Registration', () {
    test('7. Registration request mapping, payload structure, and fallback avatar', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.users);
        expect(options.method, 'POST');
        final data = options.data as Map<String, dynamic>;
        expect(data['name'], 'New Customer');
        expect(data['email'], 'newuser@example.com');
        expect(data['password'], 'securePass123');
        // Crucial requirement: default fallback avatar injected when omitted
        expect(data['avatar'], ApiConstants.defaultAvatarUrl);

        return MockHttpClientAdapter.jsonResponse({
          'id': 10,
          'email': 'newuser@example.com',
          'name': 'New Customer',
          'role': 'customer',
          'avatar': ApiConstants.defaultAvatarUrl,
          'creationAt': '2026-10-24T06:00:00.000Z',
        }, statusCode: 201);
      };

      final user = await authService.register(
        const SignUpRequest(
          name: 'New Customer',
          email: 'newuser@example.com',
          password: 'securePass123',
        ),
      );

      expect(user.id, 10);
      expect(user.email, 'newuser@example.com');
      expect(user.avatar, ApiConstants.defaultAvatarUrl);

      // Verify registration does NOT automatically log in or set session tokens
      expect(await tokenStorage.hasAccessToken(), isFalse);
    });

    test('Registration handles duplicate email error (400 Bad Request)', () async {
      mockAdapter.handler = (options) async {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {'message': 'email already exists'},
          ),
          type: DioExceptionType.badResponse,
        );
      };

      expect(
        () => authService.register(
          const SignUpRequest(
            name: 'User',
            email: 'existing@example.com',
            password: 'password123',
          ),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('An account with this email already exists'),
          ),
        ),
      );
    });
  });

  group('Token Persistence Behavior', () {
    test('8. Token persistence lifecycle: save, retrieve, check, and clear on logout', () async {
      expect(await authService.hasSession(), isFalse);
      expect(await tokenStorage.getAccessToken(), isNull);

      await tokenStorage.saveTokens(
        accessToken: 'persistent_token_123',
        refreshToken: 'refresh_token_456',
      );

      expect(await authService.hasSession(), isTrue);
      expect(await tokenStorage.getAccessToken(), 'persistent_token_123');
      expect(await tokenStorage.getRefreshToken(), 'refresh_token_456');

      await authService.logout();

      expect(await authService.hasSession(), isFalse);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });
  });
}

