import 'package:dio/dio.dart';
import 'package:ecommerce_app_huma_volve/core/error/exceptions.dart';
import 'package:ecommerce_app_huma_volve/core/error/failures.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/auth_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exception and Failure Tests', () {
    test('ServerException.fromDioException handles timeout', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final ex = ServerException.fromDioException(dioEx);
      expect(ex.statusCode, 408);
      expect(ex.message, contains('timed out'));
    });

    test('ServerException.fromDioException handles 401 unauthorized', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
        ),
      );

      final ex = ServerException.fromDioException(dioEx);
      expect(ex.statusCode, 401);
      expect(ex.message, contains('Invalid email or password'));
    });

    test('ServerException.fromDioException handles duplicate email 400', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/users/'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/users/'),
          statusCode: 400,
          data: {
            'message': ['email already exists'],
          },
        ),
      );

      final ex = ServerException.fromDioException(dioEx);
      expect(ex.statusCode, 400);
      expect(ex.message, contains('already exists'));
    });

    test('AuthException is backward compatible with ServerException and AppException', () {
      const authEx = AuthException('Authentication error', statusCode: 403);
      expect(authEx, isA<ServerException>());
      expect(authEx, isA<AppException>());
      expect(authEx.message, 'Authentication error');
      expect(authEx.statusCode, 403);
    });

    test('Domain Failures verify equality and formatting', () {
      const f1 = ServerFailure('Server failure', statusCode: 500);
      const f2 = ServerFailure('Server failure', statusCode: 500);
      const f3 = CacheFailure('Cache error');

      expect(f1, equals(f2));
      expect(f1 == f3, isFalse);
      expect(f1.toString(), 'Server failure');
    });
  });
}
