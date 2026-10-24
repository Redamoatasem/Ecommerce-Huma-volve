import 'package:dio/dio.dart';

/// Base exception for the entire application.
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

/// Server/API exceptions occurring during network operations.
class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode, super.details});

  factory ServerException.fromDioException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String? extractedMessage;
    if (data is Map) {
      final msg = data['message'];
      if (msg is List && msg.isNotEmpty) {
        extractedMessage = msg.first.toString();
      } else if (msg is String) {
        extractedMessage = msg;
      }
    } else if (data is String && data.isNotEmpty) {
      extractedMessage = data;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerException(
          'Connection timed out. Please check your internet connection.',
          statusCode: 408,
        );

      case DioExceptionType.badResponse:
        if (status == 401) {
          return const ServerException(
            'Invalid email or password. Please try again.',
            statusCode: 401,
          );
        }
        if (status == 400) {
          if (extractedMessage != null) {
            final lower = extractedMessage.toLowerCase();
            if (lower.contains('email already') ||
                lower.contains('unique') ||
                lower.contains('exists')) {
              return const ServerException(
                'An account with this email already exists. Please login.',
                statusCode: 400,
              );
            }
            if (lower.contains('avatar')) {
              return const ServerException(
                'Invalid avatar URL provided.',
                statusCode: 400,
              );
            }
            return ServerException(
              extractedMessage,
              statusCode: 400,
              details: data,
            );
          }
          return const ServerException(
            'Invalid request. Please check the entered information.',
            statusCode: 400,
          );
        }
        if (status != null && status >= 500) {
          return ServerException(
            'Server error ($status). Please try again later.',
            statusCode: status,
          );
        }
        return ServerException(
          extractedMessage ?? 'Request failed with status $status.',
          statusCode: status,
        );

      case DioExceptionType.connectionError:
        return const ServerException(
          'Unable to connect to the server. Please check your internet.',
        );

      case DioExceptionType.cancel:
        return const ServerException('Request was cancelled.');

      default:
        return ServerException(
          extractedMessage ?? 'An unexpected network error occurred.',
          details: e.error,
        );
    }
  }
}

/// Cache or local storage exceptions.
class CacheException extends AppException {
  const CacheException(super.message, {super.statusCode, super.details});
}
