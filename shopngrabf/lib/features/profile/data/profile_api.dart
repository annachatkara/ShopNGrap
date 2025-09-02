// Profile API implementation
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/profile_model.dart';

class ProfileApi {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<UserProfile>> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.profile,
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: UserProfile.fromJson(response.data!['user'] ?? response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.failure(error: response.error!, statusCode: response.statusCode);
  }

  Future<ApiResponse<UserProfile>> updateProfile(Map<String, dynamic> body) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.profile,
      body: body,
      requiresAuth: true,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: UserProfile.fromJson(response.data!['user'] ?? response.data!),
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.failure(error: response.error!, statusCode: response.statusCode);
  }

  Future<ApiResponse<void>> uploadAvatar(String filePath, String fileName) async {
    final response = await _apiClient.uploadFile(
      ApiEndpoints.profileAvatar,
      filePath: filePath,
      fileName: fileName,
      fieldName: 'avatar',
      requiresAuth: true,
    );
    return response.isSuccess
        ? ApiResponse.success(data: null, statusCode: response.statusCode)
        : ApiResponse.failure(error: response.error!, statusCode: response.statusCode);
  }
}
