// Product API implementation
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/product_model.dart';

class ProductApi {
  final ApiClient _apiClient = ApiClient();

  // Get all products (public)
  Future<ApiResponse<ProductsResponse>> getProducts({
    ProductFilters? filters,
  }) async {
    final queryParams = filters?.toQueryParams() ?? {'page': 1, 'limit': 10};
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParams: queryParams,
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final productsResponse = ProductsResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: productsResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get single product (public)
  Future<ApiResponse<Product>> getProduct(int productId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.product(productId),
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final product = Product.fromJson(response.data!['product'] ?? response.data!);
      return ApiResponse.success(data: product, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get user's products (for specific user, public)
  Future<ApiResponse<ProductsResponse>> getUserProducts(
    int userId, {
    ProductFilters? filters,
  }) async {
    final queryParams = filters?.toQueryParams() ?? {'page': 1, 'limit': 10};
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.userProducts(userId),
      queryParams: queryParams,
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final productsResponse = ProductsResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: productsResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get admin's products (requires admin auth)
  Future<ApiResponse<ProductsResponse>> getMyProducts({
    ProductFilters? filters,
  }) async {
    final queryParams = filters?.toQueryParams() ?? {'page': 1, 'limit': 10};
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.myProducts,
      queryParams: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final productsResponse = ProductsResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: productsResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Create product (admin only)
  Future<ApiResponse<Product>> createProduct(CreateProductRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.products,
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final product = Product.fromJson(response.data!['product'] ?? response.data!);
      return ApiResponse.success(data: product, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Update product (admin only)
  Future<ApiResponse<Product>> updateProduct(
    int productId,
    UpdateProductRequest request,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.product(productId),
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final product = Product.fromJson(response.data!['product'] ?? response.data!);
      return ApiResponse.success(data: product, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Delete product (admin only)
  Future<ApiResponse<Map<String, dynamic>>> deleteProduct(int productId) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.product(productId),
      requiresAuth: true,
    );
  }

  // Search products
  Future<ApiResponse<ProductsResponse>> searchProducts({
    required String query,
    ProductFilters? filters,
  }) async {
    final queryParams = (filters ?? const ProductFilters()).toQueryParams();
    queryParams['search'] = query;
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParams: queryParams,
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final productsResponse = ProductsResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: productsResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get products by category
  Future<ApiResponse<ProductsResponse>> getProductsByCategory(
    int categoryId, {
    ProductFilters? filters,
  }) async {
    final queryParams = (filters ?? const ProductFilters()).toQueryParams();
    queryParams['category'] = categoryId;
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParams: queryParams,
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final productsResponse = ProductsResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: productsResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get products by shop
  Future<ApiResponse<ProductsResponse>> getProductsByShop(
    int shopId, {
    ProductFilters? filters,
  }) async {
    final queryParams = (filters ?? const ProductFilters()).toQueryParams();
    queryParams['shop'] = shopId;
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParams: queryParams,
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final productsResponse = ProductsResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: productsResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }
}
