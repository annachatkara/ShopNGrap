// Admin API implementation
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/admin_model.dart';

class AdminApi {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<AdminUser>>> getUsers({String? search}) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminUsers,
      queryParams: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      final list = (response.data!['users'] as List<dynamic>?)
          ?.map((u) => AdminUser.fromJson(u))
          .toList() ?? [];
      return ApiResponse.success(data: list, statusCode: response.statusCode);
    }
    return ApiResponse.failure(error: response.error!, statusCode: response.statusCode);
  }

  Future<ApiResponse<void>> toggleUser(int userId, bool isActive) async {
    final response = await _client.post<void>(
      '${ApiEndpoints.adminUsers}/$userId/toggle',
      body: {'isActive': isActive},
      requiresAuth: true,
    );
    return response.isSuccess
        ? ApiResponse.success(data: null, statusCode: response.statusCode)
        : ApiResponse.failure(error: response.error!, statusCode: response.statusCode);
  }

  Future<ApiResponse<SystemSettings>> getSettings() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.systemSettings,
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: SystemSettings.fromJson(response.data!['settings'] ?? response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.failure(error: response.error!, statusCode: response.statusCode);
  }

  Future<ApiResponse<SystemSettings>> updateSettings(SystemSettings settings) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.systemSettings,
      body: settings.toJson(),
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: SystemSettings.fromJson(response.data!['settings'] ?? response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.failure(error: response.error!, statusCode: response.statusCode);
  }

  Future<ApiResponse<DashboardMetrics>> getMetrics() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminMetrics,
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: DashboardMetrics.fromJson(response.data!['metrics'] ?? response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.failure(error: response.error!, statusCode: response.statusCode);
  }
}
