// Category API implementation
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/category_model.dart';

class CategoryApi {
  final ApiClient _apiClient = ApiClient();

  // Public: Get all categories (with hierarchy)
  Future<ApiResponse<CategoriesResponse>> getCategories({
    CategoryFilters? filters,
    bool includeHierarchy = true,
  }) async {
    final queryParams = filters?.toQueryParams() ?? {'page': 1, 'limit': 50};
    if (includeHierarchy) queryParams['includeHierarchy'] = true;
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
      queryParams: queryParams,
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final categoriesResponse = CategoriesResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: categoriesResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Public: Get main categories only
  Future<ApiResponse<List<Category>>> getMainCategories({
    bool activeOnly = true,
  }) async {
    final queryParams = <String, dynamic>{
      'parentId': null, // Only main categories
      'limit': 100,
    };
    if (activeOnly) queryParams['isActive'] = true;
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
      queryParams: queryParams,
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final categoriesList = response.data!['categories'] as List<dynamic>? ?? [];
      final categories = categoriesList.map((category) => Category.fromJson(category)).toList();
      return ApiResponse.success(data: categories, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Public: Get featured categories
  Future<ApiResponse<List<Category>>> getFeaturedCategories({
    int limit = 10,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
      queryParams: {
        'isFeatured': true,
        'isActive': true,
        'limit': limit,
        'sortBy': 'sortOrder',
        'sortOrder': 'asc',
      },
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final categoriesList = response.data!['categories'] as List<dynamic>? ?? [];
      final categories = categoriesList.map((category) => Category.fromJson(category)).toList();
      return ApiResponse.success(data: categories, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Public: Get subcategories by parent ID
  Future<ApiResponse<List<Category>>> getSubcategories(int parentId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
      queryParams: {
        'parentId': parentId,
        'isActive': true,
        'sortBy': 'sortOrder',
        'sortOrder': 'asc',
        'limit': 100,
      },
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final categoriesList = response.data!['categories'] as List<dynamic>? ?? [];
      final categories = categoriesList.map((category) => Category.fromJson(category)).toList();
      return ApiResponse.success(data: categories, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Public: Get single category with full hierarchy
  Future<ApiResponse<Category>> getCategory(int categoryId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/$categoryId',
      queryParams: {'includeHierarchy': true},
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final category = Category.fromJson(response.data!['category'] ?? response.data!);
      return ApiResponse.success(data: category, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Public: Search categories
  Future<ApiResponse<List<Category>>> searchCategories(String query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/search',
      queryParams: {
        'q': query,
        'isActive': true,
        'limit': 20,
      },
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final categoriesList = response.data!['categories'] as List<dynamic>? ?? [];
      final categories = categoriesList.map((category) => Category.fromJson(category)).toList();
      return ApiResponse.success(data: categories, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Public: Get category tree (hierarchical structure)
  Future<ApiResponse<List<Category>>> getCategoryTree() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/tree',
      queryParams: {'isActive': true},
      requiresAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final categoriesList = response.data!['categories'] as List<dynamic>? ?? [];
      final categories = categoriesList.map((category) => Category.fromJson(category)).toList();
      return ApiResponse.success(data: categories, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Get all categories (including inactive)
  Future<ApiResponse<CategoriesResponse>> getAllCategoriesAdmin({
    CategoryFilters? filters,
  }) async {
    final queryParams = filters?.toQueryParams() ?? {'page': 1, 'limit': 20};
    queryParams['includeInactive'] = true;
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/admin',
      queryParams: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final categoriesResponse = CategoriesResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: categoriesResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Create category
  Future<ApiResponse<Category>> createCategory(CreateCategoryRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.categories,
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final category = Category.fromJson(response.data!['category'] ?? response.data!);
      return ApiResponse.success(data: category, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Update category
  Future<ApiResponse<Category>> updateCategory(
    int categoryId,
    UpdateCategoryRequest request,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/$categoryId',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final category = Category.fromJson(response.data!['category'] ?? response.data!);
      return ApiResponse.success(data: category, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Delete category
  Future<ApiResponse<void>> deleteCategory(int categoryId) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.categories}/$categoryId',
      requiresAuth: true,
    );

    if (response.isSuccess) {
      return ApiResponse.success(data: null, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Bulk update category status
  Future<ApiResponse<List<Category>>> bulkUpdateCategoryStatus(
    List<int> categoryIds,
    bool isActive,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/bulk-update',
      body: {
        'categoryIds': categoryIds,
        'isActive': isActive,
      },
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final categoriesList = response.data!['categories'] as List<dynamic>? ?? [];
      final categories = categoriesList.map((category) => Category.fromJson(category)).toList();
      return ApiResponse.success(data: categories, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Reorder categories
  Future<ApiResponse<List<Category>>> reorderCategories(
    List<Map<String, int>> categoryOrders, // [{"id": 1, "sortOrder": 0}, ...]
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/reorder',
      body: {'categoryOrders': categoryOrders},
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final categoriesList = response.data!['categories'] as List<dynamic>? ?? [];
      final categories = categoriesList.map((category) => Category.fromJson(category)).toList();
      return ApiResponse.success(data: categories, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Get category statistics
  Future<ApiResponse<CategoryStatistics>> getCategoryStatistics() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/statistics',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final stats = CategoryStatistics.fromJson(response.data!['statistics'] ?? response.data!);
      return ApiResponse.success(data: stats, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Upload category image
  Future<ApiResponse<Map<String, String>>> uploadCategoryImage(
    String filePath,
    String fileName,
  ) async {
    final response = await _apiClient.uploadFile(
      '${ApiEndpoints.categories}/upload-image',
      filePath: filePath,
      fileName: fileName,
      fieldName: 'categoryImage',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: Map<String, String>.from(response.data!),
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Import categories from CSV/JSON
  Future<ApiResponse<Map<String, dynamic>>> importCategories(
    String filePath,
    String format, // 'csv' or 'json'
  ) async {
    final response = await _apiClient.uploadFile(
      '${ApiEndpoints.categories}/import',
      filePath: filePath,
      fileName: 'categories.$format',
      fieldName: 'categoriesFile',
      additionalData: {'format': format},
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: response.data!,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Export categories
  Future<ApiResponse<Map<String, dynamic>>> exportCategories(
    String format, // 'csv' or 'json'
    {CategoryFilters? filters}
  ) async {
    final queryParams = filters?.toQueryParams() ?? {};
    queryParams['format'] = format;

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/export',
      queryParams: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(
        data: response.data!,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Product integration: Get products by category
  Future<ApiResponse<Map<String, dynamic>>> getProductsByCategory(
    int categoryId, {
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    bool includeSubcategories = true,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/$categoryId/products',
      queryParams: {
        'page': page,
        'limit': limit,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
        'includeSubcategories': includeSubcategories,
      },
      requiresAuth: false,
    );

    return response;
  }

  // Analytics: Get category performance
  Future<ApiResponse<Map<String, dynamic>>> getCategoryAnalytics(
    int categoryId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/$categoryId/analytics',
      queryParams: queryParams,
      requiresAuth: true,
    );

    return response;
  }

  // Cache management
  Future<ApiResponse<void>> refreshCategoryCache() async {
    final response = await _apiClient.post(
      '${ApiEndpoints.categories}/refresh-cache',
      requiresAuth: true,
    );

    if (response.isSuccess) {
      return ApiResponse.success(data: null, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }
}
