/// Base exception class for all app-level exceptions.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException(message: $message, statusCode: $statusCode)';
}

/// Thrown when the user is not authenticated or the session has expired.
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    String message = 'Unauthorized. Please sign in again.',
    int? statusCode = 401,
  }) : super(message: message, statusCode: statusCode);

  @override
  String toString() => 'UnauthorizedException(message: $message)';
}

/// Thrown when there is a network connectivity issue.
class NetworkException extends AppException {
  const NetworkException({
    String message = 'No internet connection. Please check your network.',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);

  @override
  String toString() => 'NetworkException(message: $message)';
}

/// Thrown when the server returns a 5xx error.
class ServerException extends AppException {
  const ServerException({
    String message = 'Server error. Please try again later.',
    int? statusCode = 500,
  }) : super(message: message, statusCode: statusCode);

  @override
  String toString() => 'ServerException(message: $message, statusCode: $statusCode)';
}

/// Thrown when a requested resource is not found (404).
class NotFoundException extends AppException {
  const NotFoundException({
    String message = 'The requested resource was not found.',
    int? statusCode = 404,
  }) : super(message: message, statusCode: statusCode);

  @override
  String toString() => 'NotFoundException(message: $message)';
}

/// Thrown when the server returns a 422 or 400 validation error.
class ValidationException extends AppException {
  final List<String> errors;

  const ValidationException({
    String message = 'Validation failed. Please check your input.',
    this.errors = const [],
    int? statusCode = 422,
  }) : super(message: message, statusCode: statusCode);

  String get firstError => errors.isNotEmpty ? errors.first : message;

  @override
  String toString() =>
      'ValidationException(message: $message, errors: $errors)';
}

/// Thrown when a request times out.
class TimeoutException extends AppException {
  const TimeoutException({
    String message = 'Request timed out. Please try again.',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);

  @override
  String toString() => 'TimeoutException(message: $message)';
}

/// Thrown for any other unexpected error.
class UnknownException extends AppException {
  const UnknownException({
    String message = 'An unexpected error occurred.',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);

  @override
  String toString() => 'UnknownException(message: $message)';
}
