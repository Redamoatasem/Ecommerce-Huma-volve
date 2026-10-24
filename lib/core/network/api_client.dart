import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';

class ApiClient {
  final Dio dio;

  ApiClient({Dio? customDio})
      : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                sendTimeout: ApiConstants.sendTimeout,
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    if (customDio == null && kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false, // Prevents logging Authorization Bearer tokens
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
          filter: (options, args) {
            // Security: suppress logging request bodies on auth endpoints to prevent password exposure
            final path = options.path.toLowerCase();
            if (path.contains('login') || path.contains('users')) {
              return false;
            }
            return true;
          },
        ),
      );
    }
  }
}

