import 'package:dio/dio.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AuthException(this.message, {this.statusCode, this.details});

  factory AuthException.fromDioException(DioException e) {
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
        return const AuthException(
          'Connection timed out. Please check your internet connection.',
          statusCode: 408,
        );

      case DioExceptionType.badResponse:
        if (status == 401) {
          return const AuthException(
            'Invalid email or password. Please try again.',
            statusCode: 401,
          );
        }
        if (status == 400) {
          if (extractedMessage != null) {
            final lower = extractedMessage.toLowerCase();
            if (lower.contains('email already') || lower.contains('unique') || lower.contains('exists')) {
              return const AuthException(
                'An account with this email already exists. Please login.',
                statusCode: 400,
              );
            }
            if (lower.contains('avatar')) {
              return const AuthException(
                'Invalid avatar URL provided.',
                statusCode: 400,
              );
            }
            return AuthException(
              extractedMessage,
              statusCode: 400,
              details: data,
            );
          }
          return const AuthException(
            'Invalid request. Please check the entered information.',
            statusCode: 400,
          );
        }
        if (status != null && status >= 500) {
          return AuthException(
            'Server error ($status). Please try again later.',
            statusCode: status,
          );
        }
        return AuthException(
          extractedMessage ?? 'Request failed with status $status.',
          statusCode: status,
        );

      case DioExceptionType.connectionError:
        return const AuthException(
          'Unable to connect to the authentication server. Please check your internet.',
        );

      case DioExceptionType.cancel:
        return const AuthException('Request was cancelled.');

      default:
        return AuthException(
          extractedMessage ?? 'An unexpected network error occurred.',
          details: e.error,
        );
    }
  }

  @override
  String toString() => message;
}

