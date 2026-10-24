import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';

class AuthException extends ServerException {
  const AuthException(super.message, {super.statusCode, super.details});

  factory AuthException.fromDioException(DioException e) {
    final serverEx = ServerException.fromDioException(e);
    return AuthException(
      serverEx.message,
      statusCode: serverEx.statusCode,
      details: serverEx.details,
    );
  }
}
