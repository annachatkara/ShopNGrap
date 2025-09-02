// API and app error handling
class ApiError {
  final String message;
  final String code;
  final Map<String, dynamic>? details;

  ApiError({
    required this.message,
    required this.code,
    this.details,
  });

  factory ApiError.fromResponse(Map<String, dynamic> response, int statusCode) {
    return ApiError(
      message: response['message'] ?? _getDefaultMessage(statusCode),
      code: response['code'] ?? 'ERROR_$statusCode',
      details: response['details'],
    );
  }

  static String _getDefaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Requested resource not found.';
      case 409:
        return 'Conflict occurred.';
      case 422:
        return 'Validation failed.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error.';
      case 502:
        return 'Bad gateway.';
      case 503:
        return 'Service unavailable.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  String toString() {
    return 'ApiError(message: $message, code: $code, details: $details)';
  }
}

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  factory AppException.network() {
    return AppException(
      message: 'Please check your internet connection',
      code: 'NETWORK_ERROR',
    );
  }

  factory AppException.timeout() {
    return AppException(
      message: 'Request timed out. Please try again.',
      code: 'TIMEOUT_ERROR',
    );
  }

  factory AppException.server() {
    return AppException(
      message: 'Server error. Please try again later.',
      code: 'SERVER_ERROR',
    );
  }

  factory AppException.unauthorized() {
    return AppException(
      message: 'Session expired. Please login again.',
      code: 'UNAUTHORIZED',
    );
  }

  factory AppException.validation(String message) {
    return AppException(
      message: message,
      code: 'VALIDATION_ERROR',
    );
  }

  @override
  String toString() {
    return 'AppException(message: $message, code: $code)';
  }
}

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is ApiError) {
      return error.message;
    } else if (error is AppException) {
      return error.message;
    } else {
      return 'An unexpected error occurred';
    }
  }

  static bool isNetworkError(dynamic error) {
    if (error is ApiError) {
      return error.code.contains('NETWORK');
    } else if (error is AppException) {
      return error.code == 'NETWORK_ERROR';
    }
    return false;
  }

  static bool isUnauthorized(dynamic error) {
    if (error is ApiError) {
      return error.code == 'UNAUTHORIZED' || error.code == 'ERROR_401';
    } else if (error is AppException) {
      return error.code == 'UNAUTHORIZED';
    }
    return false;
  }
}
