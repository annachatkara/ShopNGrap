// Category repository implementation
import '../../../core/storage/preferences.dart';
import '../../../core/utils/error_handler.dart';
import '../domain/category_model.dart';
import 'category_api.dart';

class CategoryRepository {
  final CategoryApi _categoryApi = CategoryApi();
  final Preferences _preferences = Preferences();

  // Cache for categories
  final Map<String, List<Category>> _categoriesCache = {};
  final Map<int, Category> _individualCategoryCache = {};
  DateTime? _lastFetchTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 30);

  // Cache keys
  static const String _mainCategoriesKey = 'main_categories';
  static const String _featuredCategoriesKey = 'featured_categories';
  static const String _categoryTreeKey = 'category_tree';

  // Get all categories with caching
  Future<CategoriesResponse> getCategories({
    CategoryFilters? filters,
    bool forceRefresh = false,
    bool includeHierarchy = true,
  }) async {
    try {
      final cacheKey = 'categories_${filters?.toQueryParams().toString() ?? 'all'}';
      
      // Check cache first
      if (!forceRefresh && _isCacheValid() && _categoriesCache.containsKey(cacheKey)) {
        return CategoriesResponse(
          categories: _categoriesCache[cacheKey]!,
          pagination: Pagination(
            currentPage: 1,
            totalPages: 1,
            totalItems: _categoriesCache[cacheKey]!.length,
            itemsPerPage: _categoriesCache[cacheKey]!.length,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        );
      }

      final response = await _categoryApi.getCategories(
        filters: filters,
        includeHierarchy: includeHierarchy,
      );
      
      if (response.isSuccess && response.data != null) {
        // Cache the response
        _categoriesCache[cacheKey] = response.data!.categories;
        _lastFetchTime = DateTime.now();
        
        // Cache individual categories
        for (final category in response.data!.categories) {
          _individualCategoryCache[category.id] = category;
        }
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load categories',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load categories. Please try again.',
        originalError: e,
      );
    }
  }

  // Get main categories only
  Future<List<Category>> getMainCategories({
    bool forceRefresh = false,
    bool activeOnly = true,
  }) async {
    try {
      final cacheKey = '$_mainCategoriesKey${activeOnly ? '_active' : ''}';
      
      if (!forceRefresh && _isCacheValid() && _categoriesCache.containsKey(cacheKey)) {
        return _categoriesCache[cacheKey]!;
      }

      final response = await _categoryApi.getMainCategories(activeOnly: activeOnly);
      
      if (response.isSuccess && response.data != null) {
        _categoriesCache[cacheKey] = response.data!;
        _lastFetchTime = DateTime.now();
        
        // Cache individual categories
        for (final category in response.data!) {
          _individualCategoryCache[category.id] = category;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to load main categories',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load main categories. Please try again.',
        originalError: e,
      );
    }
  }

  // Get featured categories
  Future<List<Category>> getFeaturedCategories({
    bool forceRefresh = false,
    int limit = 10,
  }) async {
    try {
      if (!forceRefresh && _isCacheValid() && _categoriesCache.containsKey(_featuredCategoriesKey)) {
        return _categoriesCache[_featuredCategoriesKey]!.take(limit).toList();
      }

      final response = await _categoryApi.getFeaturedCategories(limit: limit);
      
      if (response.isSuccess && response.data != null) {
        _categoriesCache[_featuredCategoriesKey] = response.data!;
        _lastFetchTime = DateTime.now();
        
        // Cache individual categories
        for (final category in response.data!) {
          _individualCategoryCache[category.id] = category;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to load featured categories',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load featured categories. Please try again.',
        originalError: e,
      );
    }
  }

  // Get subcategories
  Future<List<Category>> getSubcategories(
    int parentId, {
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'subcategories_$parentId';
      
      if (!forceRefresh && _isCacheValid() && _categoriesCache.containsKey(cacheKey)) {
        return _categoriesCache[cacheKey]!;
      }

      final response = await _categoryApi.getSubcategories(parentId);
      
      if (response.isSuccess && response.data != null) {
        _categoriesCache[cacheKey] = response.data!;
        _lastFetchTime = DateTime.now();
        
        // Cache individual categories
        for (final category in response.data!) {
          _individualCategoryCache[category.id] = category;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to load subcategories',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load subcategories. Please try again.',
        originalError: e,
      );
    }
  }

  // Get single category
  Future<Category> getCategory(int categoryId, {bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh && _individualCategoryCache.containsKey(categoryId)) {
        return _individualCategoryCache[categoryId]!;
      }

      final response = await _categoryApi.getCategory(categoryId);
      
      if (response.isSuccess && response.data != null) {
        _individualCategoryCache[categoryId] = response.data!;
        return response.data!;
      } else {
        if (response.isNotFound) {
          throw AppException(
            message: 'Category not found',
            code: 'CATEGORY_NOT_FOUND',
          );
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load category',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load category. Please try again.',
        originalError: e,
      );
    }
  }

  // Search categories
  Future<List<Category>> searchCategories(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final response = await _categoryApi.searchCategories(query.trim());
      
      if (response.isSuccess && response.data != null) {
        // Cache search results temporarily
        for (final category in response.data!) {
          _individualCategoryCache[category.id] = category;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to search categories',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      return []; // Return empty list for search failures
    }
  }

  // Get category tree
  Future<List<Category>> getCategoryTree({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _isCacheValid() && _categoriesCache.containsKey(_categoryTreeKey)) {
        return _categoriesCache[_categoryTreeKey]!;
      }

      final response = await _categoryApi.getCategoryTree();
      
      if (response.isSuccess && response.data != null) {
        _categoriesCache[_categoryTreeKey] = response.data!;
        _lastFetchTime = DateTime.now();
        
        // Cache individual categories and their children recursively
        _cacheTreeCategories(response.data!);
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to load category tree',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load category tree. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Get all categories (including inactive)
  Future<CategoriesResponse> getAllCategoriesAdmin({
    CategoryFilters? filters,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _categoryApi.getAllCategoriesAdmin(filters: filters);
      
      if (response.isSuccess && response.data != null) {
        // Don't cache admin data as it changes frequently
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load admin categories',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load admin categories. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Create category
  Future<Category> createCategory(CreateCategoryRequest request) async {
    try {
      final response = await _categoryApi.createCategory(request);
      
      if (response.isSuccess && response.data != null) {
        // Clear cache to ensure fresh data
        _clearCache();
        
        // Cache the new category
        _individualCategoryCache[response.data!.id] = response.data!;
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        
        // Handle specific business errors
        if (response.error?.code == 'CATEGORY_NAME_EXISTS') {
          throw AppException(
            message: 'A category with this name already exists',
            code: 'CATEGORY_NAME_EXISTS',
          );
        }
        
        throw AppException(
          message: response.error?.message ?? 'Failed to create category',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to create category. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Update category
  Future<Category> updateCategory(
    int categoryId,
    UpdateCategoryRequest request,
  ) async {
    try {
      final response = await _categoryApi.updateCategory(categoryId, request);
      
      if (response.isSuccess && response.data != null) {
        // Clear cache to ensure fresh data
        _clearCache();
        
        // Update individual cache
        _individualCategoryCache[categoryId] = response.data!;
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        if (response.isNotFound) {
          throw AppException(
            message: 'Category not found',
            code: 'CATEGORY_NOT_FOUND',
          );
        }
        
        throw AppException(
          message: response.error?.message ?? 'Failed to update category',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to update category. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Delete category
  Future<bool> deleteCategory(int categoryId) async {
    try {
      final response = await _categoryApi.deleteCategory(categoryId);
      
      if (response.isSuccess) {
        // Clear cache and remove from individual cache
        _clearCache();
        _individualCategoryCache.remove(categoryId);
        
        return true;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        if (response.error?.code == 'CATEGORY_HAS_PRODUCTS') {
          throw AppException(
            message: 'Cannot delete category with products. Move products first.',
            code: 'CATEGORY_HAS_PRODUCTS',
          );
        }
        if (response.error?.code == 'CATEGORY_HAS_SUBCATEGORIES') {
          throw AppException(
            message: 'Cannot delete category with subcategories. Remove subcategories first.',
            code: 'CATEGORY_HAS_SUBCATEGORIES',
          );
        }
        
        throw AppException(
          message: response.error?.message ?? 'Failed to delete category',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to delete category. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Bulk operations
  Future<List<Category>> bulkUpdateCategoryStatus(
    List<int> categoryIds,
    bool isActive,
  ) async {
    try {
      final response = await _categoryApi.bulkUpdateCategoryStatus(categoryIds, isActive);
      
      if (response.isSuccess && response.data != null) {
        _clearCache();
        
        // Update individual cache
        for (final category in response.data!) {
          _individualCategoryCache[category.id] = category;
        }
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to update categories',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to update categories. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Get statistics
  Future<CategoryStatistics> getCategoryStatistics() async {
    try {
      final response = await _categoryApi.getCategoryStatistics();
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load statistics',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load statistics. Please try again.',
        originalError: e,
      );
    }
  }

  // Upload category image
  Future<String> uploadCategoryImage(String filePath, String fileName) async {
    try {
      final response = await _categoryApi.uploadCategoryImage(filePath, fileName);
      
      if (response.isSuccess && response.data != null) {
        return response.data!['imageUrl'] ?? response.data!['url'] ?? '';
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to upload image',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to upload image. Please try again.',
        originalError: e,
      );
    }
  }

  // Get products by category
  Future<Map<String, dynamic>> getProductsByCategory(
    int categoryId, {
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    bool includeSubcategories = true,
  }) async {
    try {
      final response = await _categoryApi.getProductsByCategory(
        categoryId,
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
        includeSubcategories: includeSubcategories,
      );
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to load products',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      return {'products': [], 'pagination': {}};
    }
  }

  // Local filtering and search helpers
  List<Category> filterCategoriesLocally(
    List<Category> categories,
    CategoryFilters filters,
  ) {
    return categories.where((category) {
      // Active filter
      if (filters.isActive != null && category.isActive != filters.isActive) {
        return false;
      }
      
      // Featured filter
      if (filters.isFeatured != null && category.isFeatured != filters.isFeatured) {
        return false;
      }
      
      // Parent filter
      if (filters.parentId != null && category.parentId != filters.parentId) {
        return false;
      }
      
      // Search filter
      if (filters.search != null && filters.search!.isNotEmpty) {
        if (!category.containsQuery(filters.search!)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  List<Category> sortCategoriesLocally(List<Category> categories, String? sortBy) {
    final sortedCategories = List<Category>.from(categories);
    
    switch (sortBy) {
      case 'name':
        sortedCategories.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'productCount':
        sortedCategories.sort((a, b) => b.productCount.compareTo(a.productCount));
        break;
      case 'sortOrder':
        sortedCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case 'createdAt':
        sortedCategories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        // Default to sort order
        sortedCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    
    return sortedCategories;
  }

  // Cache management
  void _cacheTreeCategories(List<Category> categories) {
    for (final category in categories) {
      _individualCategoryCache[category.id] = category;
      if (category.children.isNotEmpty) {
        _cacheTreeCategories(category.children);
      }
    }
  }

  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    
    final now = DateTime.now();
    return now.difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  void _clearCache() {
    _categoriesCache.clear();
    _lastFetchTime = null;
  }

  void clearAllCache() {
    _categoriesCache.clear();
    _individualCategoryCache.clear();
    _lastFetchTime = null;
  }

  // Local storage for user preferences
  Future<void> saveFavoriteCategories(List<int> categoryIds) async {
    await _preferences.setFavoriteCategoryIds(categoryIds);
  }

  Future<List<int>> getFavoriteCategoryIds() async {
    return _preferences.getFavoriteCategoryIds();
  }

  Future<void> saveRecentlyViewedCategories(List<int> categoryIds) async {
    await _preferences.setRecentCategoryIds(categoryIds);
  }

  Future<List<int>> getRecentlyViewedCategoryIds() async {
    return _preferences.getRecentCategoryIds();
  }
}
