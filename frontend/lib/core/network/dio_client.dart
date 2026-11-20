import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'network_exception.dart';

class DioClient {
  late final Dio dio;

  DioClient({String? baseUrl}) {
    String effectiveBaseUrl = baseUrl ?? AppConstants.apiBaseUrl;
    if (kIsWeb) {
      final currentOrigin = Uri.base.origin;
      // If served from a tunnel, reverse proxy, or same port, dynamically bind to current host
      if (currentOrigin.isNotEmpty && !currentOrigin.contains('localhost:3000') && !currentOrigin.contains('localhost:59604')) {
        effectiveBaseUrl = currentOrigin;
      }
    }

    dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 180),
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (err, handler) {
          final exception = switch (err.type) {
            DioExceptionType.connectionTimeout => const TimeoutException(),
            DioExceptionType.receiveTimeout => const TimeoutException(),
            DioExceptionType.connectionError =>
              const NetworkException(message: 'Failed to connect to Lotew Industrial Backend. Ensure server is running on port 8000.'),
            _ => switch (err.response?.statusCode) {
                422 => ValidationException(err.response?.data?['detail']?.toString() ?? 'Validation failed'),
                500 || 502 || 503 => ServerException(err.response?.statusCode ?? 500, err.response?.data?['detail']?.toString()),
                _ => ServerException(err.response?.statusCode ?? 500, err.message),
              },
          };
          handler.reject(
            DioException(requestOptions: err.requestOptions, error: exception),
          );
        },
      ),
    );
  }
}

