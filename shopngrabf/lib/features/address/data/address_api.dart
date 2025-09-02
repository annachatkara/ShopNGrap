// Address API implementation
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/address_model.dart';

class ShopAddressApi {
  final ApiClient _apiClient = ApiClient();

  // Get all shop addresses (public - for customers to see pickup locations)
  Future<ApiResponse<List<ShopAddress>>> getAllShopAddresses({
    int? categoryId,
    String? city,
    String? state,
  }) async {
    final queryParams = <String, dynamic>{};
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (city != null) queryParams['city'] = city;
    if (state != null) queryParams['state'] = state;

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.addresses}/shops',
      queryParams: queryParams,
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final addressesList = response.data!['shopAddresses'] as List<dynamic>? ?? [];
      final addresses = addressesList.map((address) => ShopAddress.fromJson(address)).toList();
      return ApiResponse.success(data: addresses, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get nearby shop addresses (public)
  Future<ApiResponse<List<ShopAddress>>> getNearbyShopAddresses(
    NearbyShopsRequest request,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.addresses}/shops/nearby',
      queryParams: request.toQueryParams(),
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final addressesList = response.data!['shopAddresses'] as List<dynamic>? ?? [];
      final addresses = addressesList.map((address) => ShopAddress.fromJson(address)).toList();
      return ApiResponse.success(data: addresses, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get single shop address (public)
  Future<ApiResponse<ShopAddress>> getShopAddress(int shopId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.addresses}/shops/$shopId',
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final address = ShopAddress.fromJson(response.data!['shopAddress'] ?? response.data!);
      return ApiResponse.success(data: address, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get my shop address (admin only)
  Future<ApiResponse<ShopAddress>> getMyShopAddress() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.addresses}/my-shop',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final address = ShopAddress.fromJson(response.data!['shopAddress'] ?? response.data!);
      return ApiResponse.success(data: address, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Create/Update my shop address (admin only)
  Future<ApiResponse<ShopAddress>> createOrUpdateMyShopAddress(
    CreateShopAddressRequest request,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.addresses}/my-shop',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final address = ShopAddress.fromJson(response.data!['shopAddress'] ?? response.data!);
      return ApiResponse.success(data: address, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Update my shop address (admin only)
  Future<ApiResponse<ShopAddress>> updateMyShopAddress(
    UpdateShopAddressRequest request,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${ApiEndpoints.addresses}/my-shop',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final address = ShopAddress.fromJson(response.data!['shopAddress'] ?? response.data!);
      return ApiResponse.success(data: address, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Validate pincode and get location suggestions
  Future<ApiResponse<Map<String, dynamic>>> validatePincode(String pincode) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.addresses}/validate-pincode',
      body: {'pincode': pincode},
      requiresAuth: false,
    );

    return response;
  }

  // Get location from coordinates (reverse geocoding)
  Future<ApiResponse<Map<String, dynamic>>> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.addresses}/reverse-geocode',
      queryParams: {
        'latitude': latitude,
        'longitude': longitude,
      },
      requiresAuth: false,
    );

    return response;
  }

  // Search locations for autocomplete
  Future<ApiResponse<List<Map<String, dynamic>>>> searchLocations(String query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.addresses}/search-locations',
      queryParams: {'q': query},
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final suggestions = response.data!['locations'] as List<dynamic>? ?? [];
      final locationsList = suggestions.cast<Map<String, dynamic>>();
      return ApiResponse.success(data: locationsList, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }
}
