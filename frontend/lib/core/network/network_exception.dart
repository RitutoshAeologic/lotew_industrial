class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException({this.message = 'A network error occurred', this.statusCode});

  @override
  String toString() => 'NetworkException($statusCode): $message';
}

class TimeoutException extends NetworkException {
  const TimeoutException() : super(message: 'Request timed out. Please check your backend connection.');
}

class ServerException extends NetworkException {
  const ServerException(int statusCode, [String? message])
      : super(statusCode: statusCode, message: message ?? 'Server responded with error $statusCode');
}

class ValidationException extends NetworkException {
  const ValidationException(String message) : super(message: message, statusCode: 422);
}

