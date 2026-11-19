import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'network_exception.dart';

class DioClient {
  late final Dio dio;

  DioClient({String? baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
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

