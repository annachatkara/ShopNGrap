// Centralized HTTP client
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import '../utils/error_handler.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late http.Client _client;
  final SecureStorage _secureStorage = SecureStorage();

  void initialize() {
    _client = http.Client();
  }

  Future<Map<String, String>> _getHeaders({
    bool requiresAuth = false,
    Map<String, String>? customHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
    };

    if (requiresAuth) {
      final token = await _secureStorage.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '${AppConfig.jwtPrefix}$token';
      }
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  Uri _buildUri(String endpoint, {Map<String, dynamic>? queryParams}) {
    final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      // Filter out null values and convert to string
      final cleanParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null) {
          cleanParams[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: cleanParams);
    }
    
    return uri;
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams: queryParams);
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        customHeaders: customHeaders,
      );

      if (AppConfig.enableDebugLogs) {
        print('GET: $uri');
        print('Headers: $headers');
      }

      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams: queryParams);
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        customHeaders: customHeaders,
      );

      String? jsonBody;
      if (body != null) {
        jsonBody = jsonEncode(body);
      }

      if (AppConfig.enableDebugLogs) {
        print('POST: $uri');
        print('Headers: $headers');
        print('Body: $jsonBody');
      }

      final response = await _client
          .post(uri, headers: headers, body: jsonBody)
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams: queryParams);
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        customHeaders: customHeaders,
      );

      String? jsonBody;
      if (body != null) {
        jsonBody = jsonEncode(body);
      }

      if (AppConfig.enableDebugLogs) {
        print('PUT: $uri');
        print('Headers: $headers');
        print('Body: $jsonBody');
      }

      final response = await _client
          .put(uri, headers: headers, body: jsonBody)
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams: queryParams);
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        customHeaders: customHeaders,
      );

      if (AppConfig.enableDebugLogs) {
        print('DELETE: $uri');
        print('Headers: $headers');
      }

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    if (AppConfig.enableDebugLogs) {
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
    }

    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.failure(
          error: ApiError.fromResponse(data, response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.failure(
        error: ApiError(
          message: 'Failed to parse response',
          code: 'PARSE_ERROR',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  ApiResponse<T> _handleError<T>(dynamic error) {
    if (AppConfig.enableDebugLogs) {
      print('API Error: $error');
    }

    if (error is SocketException) {
      return ApiResponse.failure(
        error: ApiError(
          message: AppConfig.networkErrorMessage,
          code: 'NETWORK_ERROR',
        ),
      );
    } else if (error is HttpException) {
      return ApiResponse.failure(
        error: ApiError(
          message: AppConfig.serverErrorMessage,
          code: 'HTTP_ERROR',
        ),
      );
    } else {
      return ApiResponse.failure(
        error: ApiError(
          message: AppConfig.genericErrorMessage,
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiResponse<T> {
  final T? data;
  final ApiError? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });

  factory ApiResponse.success({
    required T data,
    int? statusCode,
  }) {
    return ApiResponse._(
      data: data,
      statusCode: statusCode,
      isSuccess: true,
    );
  }

  factory ApiResponse.failure({
    required ApiError error,
    int? statusCode,
  }) {
    return ApiResponse._(
      error: error,
      statusCode: statusCode,
      isSuccess: false,
    );
  }

  // Helper methods
  bool get isFailure => !isSuccess;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}
