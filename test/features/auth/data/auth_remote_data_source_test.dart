import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ecommerce_app_huma_volve/core/constants/api_constants.dart';
import 'package:ecommerce_app_huma_volve/core/constants/api_endpoints.dart';
import 'package:ecommerce_app_huma_volve/core/network/api_client.dart';
import 'package:ecommerce_app_huma_volve/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/auth_exception.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/login_request.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/signup_request.dart';
import 'package:flutter_test/flutter_test.dart';

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

  static ResponseBody jsonResponse(dynamic data, {int statusCode = 200}) {
    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        'content-type': ['application/json; charset=utf-8'],
      },
    );
  }
}

void main() {
  late MockHttpClientAdapter mockAdapter;
  late Dio dio;
  late ApiClient apiClient;
  late AuthRemoteDataSourceImpl remoteDataSource;

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    dio.httpClientAdapter = mockAdapter;
    apiClient = ApiClient(customDio: dio);
    remoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  });

  group('AuthRemoteDataSourceImpl', () {
    test('login sends credentials and parses AuthTokens', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.login);
        return MockHttpClientAdapter.jsonResponse({
          'access_token': 'test_access_jwt',
          'refresh_token': 'test_refresh_jwt',
        });
      };

      final tokens = await remoteDataSource.login(
        const LoginRequest(email: 'test@mail.com', password: 'password123'),
      );

      expect(tokens.accessToken, 'test_access_jwt');
      expect(tokens.refreshToken, 'test_refresh_jwt');
    });

    test('register sends user data and parses UserProfile', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.users);
        return MockHttpClientAdapter.jsonResponse({
          'id': 7,
          'email': 'newuser@mail.com',
          'name': 'New User',
          'role': 'customer',
          'avatar': 'https://api.lorem.space/image/face?w=640&h=640',
        });
      };

      final profile = await remoteDataSource.register(
        const SignUpRequest(
          name: 'New User',
          email: 'newuser@mail.com',
          password: 'password123',
        ),
      );

      expect(profile.id, 7);
      expect(profile.email, 'newuser@mail.com');
      expect(profile.name, 'New User');
    });

    test('getProfile sends Authorization header and parses profile', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.profile);
        expect(options.headers['Authorization'], 'Bearer my_token');
        return MockHttpClientAdapter.jsonResponse({
          'id': 7,
          'email': 'newuser@mail.com',
          'name': 'New User',
          'role': 'customer',
          'avatar': 'https://api.lorem.space/image/face?w=640&h=640',
        });
      };

      final profile = await remoteDataSource.getProfile('my_token');
      expect(profile.id, 7);
      expect(profile.email, 'newuser@mail.com');
    });

    test('login throws AuthException on malformed response', () async {
      mockAdapter.handler = (options) async {
        return MockHttpClientAdapter.jsonResponse('not-a-map');
      };

      expect(
        () => remoteDataSource.login(
          const LoginRequest(email: 'test@mail.com', password: 'password123'),
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
