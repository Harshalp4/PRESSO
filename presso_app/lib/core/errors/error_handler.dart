import 'package:dio/dio.dart';
import 'app_exception.dart';

class ErrorHandler {
  ErrorHandler._();

  /// Converts a [DioException] into a typed [AppException].
  static AppException handle(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException(
          message: 'Request timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Unable to connect. Check your internet connection.',
        );

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Secure connection failed. Please try again.',
        );

      case DioExceptionType.cancel:
        return const AppException(message: 'Request was cancelled.');

      case DioExceptionType.badResponse:
        return _handleBadResponse(exception);

      case DioExceptionType.unknown:
        if (exception.message?.contains('SocketException') == true ||
            exception.message?.contains('NetworkException') == true) {
          return const NetworkException();
        }
        return UnknownException(
          message: exception.message ?? 'An unexpected error occurred.',
        );
    }
  }

  static AppException _handleBadResponse(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final data = exception.response?.data;

    // Extract message from response body
    String serverMessage = _extractMessage(data);

    switch (statusCode) {
      case 400:
        final errors = _extractErrors(data);
        return ValidationException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'Invalid request. Please check your input.',
          errors: errors,
          statusCode: 400,
        );

      case 401:
        return UnauthorizedException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'Unauthorized. Please sign in again.',
        );

      case 403:
        return AppException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'You do not have permission to perform this action.',
          statusCode: 403,
        );

      case 404:
        return NotFoundException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'The requested resource was not found.',
        );

      case 409:
        return AppException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'A conflict occurred. Please try again.',
          statusCode: 409,
        );

      case 422:
        final errors = _extractErrors(data);
        return ValidationException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'Validation failed. Please check your input.',
          errors: errors,
          statusCode: 422,
        );

      case 429:
        return AppException(
          message: 'Too many requests. Please wait and try again.',
          statusCode: 429,
        );

      case 500:
        return ServerException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'Internal server error. Please try again later.',
          statusCode: 500,
        );

      case 502:
      case 503:
      case 504:
        return ServerException(
          message: 'Service temporarily unavailable. Please try again later.',
          statusCode: statusCode,
        );

      default:
        return UnknownException(
          message: serverMessage.isNotEmpty
              ? serverMessage
              : 'An unexpected error occurred (status: $statusCode).',
          statusCode: statusCode,
        );
    }
  }

  static String _extractMessage(dynamic data) {
    if (data == null) return '';
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ??
          (data['title'] as String?) ??
          (data['error'] as String?) ??
          '';
    }
    if (data is String) return data;
    return '';
  }

  static List<String> _extractErrors(dynamic data) {
    if (data == null) return [];
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is List) {
        return errors.map((e) => e.toString()).toList();
      }
      if (errors is Map) {
        // ASP.NET validation errors format: { "field": ["error1", "error2"] }
        final messages = <String>[];
        for (final entry in errors.entries) {
          if (entry.value is List) {
            messages.addAll((entry.value as List).map((e) => e.toString()));
          } else {
            messages.add(entry.value.toString());
          }
        }
        return messages;
      }
    }
    return [];
  }

  /// Converts any generic exception to a user-friendly message.
  static String toUserMessage(Object error) {
    if (error is AppException) return error.message;
    if (error is DioException) return handle(error).message;
    return 'An unexpected error occurred.';
  }
}
