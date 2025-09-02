// Product repository implementation
import '../../../core/storage/preferences.dart';
import '../../../core/utils/error_handler.dart';
import '../domain/product_model.dart';
import 'product_api.dart';

class ProductRepository {
  final ProductApi _productApi = ProductApi();
  final Preferences _preferences = Preferences();

  // Cache for recently viewed products
  final Map<int, Product> _productCache = {};
  final Map<String, ProductsResponse> _listCache = {};

  // Get all products
  Future<ProductsResponse> getProducts({ProductFilters? filters}) async {
    try {
      // Create cache key
      final cacheKey = 'products_${filters?.toQueryParams().toString() ?? 'default'}';
      
      // Check cache first (for better UX)
      if (_listCache.containsKey(cacheKey)) {
        final cached = _listCache[cacheKey]!;
        // Return cached data, but also fetch fresh data in background
        _refreshProductsInBackground(filters);
        return cached;
      }

      final response = await _productApi.getProducts(filters: filters);
      
      if (response.isSuccess && response.data != null) {
        // Cache the response
        _listCache[cacheKey] = response.data!;
        
        // Cache individual products
        for (final product in response.data!.products) {
          _productCache[product.id] = product;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to load products',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load products. Please try again.',
        originalError: e,
      );
    }
  }

  // Get single product
  Future<Product> getProduct(int productId) async {
    try {
      // Check cache first
      if (_productCache.containsKey(productId)) {
        final cached = _productCache[productId]!;
        // Return cached data, but also fetch fresh data in background
        _refreshProductInBackground(productId);
        return cached;
      }

      final response = await _productApi.getProduct(productId);
      
      if (response.isSuccess && response.data != null) {
        // Cache the product
        _productCache[productId] = response.data!;
        
        // Add to recently viewed
        await _addToRecentlyViewed(productId);
        
        return response.data!;
      } else {
        if (response.isNotFound) {
          throw AppException(
            message: 'Product not found',
            code: 'PRODUCT_NOT_FOUND',
          );
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load product',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load product. Please try again.',
        originalError: e,
      );
    }
  }

  // Search products
  Future<ProductsResponse> searchProducts({
    required String query,
    ProductFilters? filters,
  }) async {
    try {
      // Add search query to history
      await _addToSearchHistory(query);

      final response = await _productApi.searchProducts(
        query: query,
        filters: filters,
      );
      
      if (response.isSuccess && response.data != null) {
        // Cache individual products
        for (final product in response.data!.products) {
          _productCache[product.id] = product;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Search failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Search failed. Please try again.',
        originalError: e,
      );
    }
  }

  // Get products by category
  Future<ProductsResponse> getProductsByCategory(
    int categoryId, {
    ProductFilters? filters,
  }) async {
    try {
      final response = await _productApi.getProductsByCategory(
        categoryId,
        filters: filters,
      );
      
      if (response.isSuccess && response.data != null) {
        // Cache individual products
        for (final product in response.data!.products) {
          _productCache[product.id] = product;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to load category products',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load category products. Please try again.',
        originalError: e,
      );
    }
  }

  // Get products by shop
  Future<ProductsResponse> getProductsByShop(
    int shopId, {
    ProductFilters? filters,
  }) async {
    try {
      final response = await _productApi.getProductsByShop(
        shopId,
        filters: filters,
      );
      
      if (response.isSuccess && response.data != null) {
        // Cache individual products
        for (final product in response.data!.products) {
          _productCache[product.id] = product;
        }
        
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to load shop products',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load shop products. Please try again.',
        originalError: e,
      );
    }
  }

  // Get admin's products (requires admin auth)
  Future<ProductsResponse> getMyProducts({ProductFilters? filters}) async {
    try {
      final response = await _productApi.getMyProducts(filters: filters);
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load your products',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load your products. Please try again.',
        originalError: e,
      );
    }
  }

  // Create product (admin only)
  Future<Product> createProduct(CreateProductRequest request) async {
    try {
      final response = await _productApi.createProduct(request);
      
      if (response.isSuccess && response.data != null) {
        // Cache the new product
        _productCache[response.data!.id] = response.data!;
        
        // Clear list cache to force refresh
        _listCache.clear();
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to create product',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to create product. Please try again.',
        originalError: e,
      );
    }
  }

  // Update product (admin only)
  Future<Product> updateProduct(
    int productId,
    UpdateProductRequest request,
  ) async {
    try {
      final response = await _productApi.updateProduct(productId, request);
      
      if (response.isSuccess && response.data != null) {
        // Update cache
        _productCache[productId] = response.data!;
        
        // Clear list cache to force refresh
        _listCache.clear();
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        if (response.isNotFound) {
          throw AppException(
            message: 'Product not found',
            code: 'PRODUCT_NOT_FOUND',
          );
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to update product',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to update product. Please try again.',
        originalError: e,
      );
    }
  }

  // Delete product (admin only)
  Future<void> deleteProduct(int productId) async {
    try {
      final response = await _productApi.deleteProduct(productId);
      
      if (response.isSuccess) {
        // Remove from cache
        _productCache.remove(productId);
        
        // Clear list cache to force refresh
        _listCache.clear();
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        if (response.isNotFound) {
          throw AppException(
            message: 'Product not found',
            code: 'PRODUCT_NOT_FOUND',
          );
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to delete product',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to delete product. Please try again.',
        originalError: e,
      );
    }
  }

  // Get recently viewed products
  Future<List<Product>> getRecentlyViewedProducts() async {
    try {
      final recentIds = _preferences.getRecentlyViewed();
      final products = <Product>[];
      
      for (final id in recentIds) {
        if (_productCache.containsKey(id)) {
          products.add(_productCache[id]!);
        } else {
          // Try to fetch from API
          try {
            final product = await getProduct(id);
            products.add(product);
          } catch (e) {
            // Skip if product not found or error
            continue;
          }
        }
      }
      
      return products;
    } catch (e) {
      return [];
    }
  }

  // Get search history
  List<String> getSearchHistory() {
    return _preferences.getSearchHistory();
  }

  // Clear search history
  Future<void> clearSearchHistory() async {
    await _preferences.clearSearchHistory();
  }

  // Clear cache
  void clearCache() {
    _productCache.clear();
    _listCache.clear();
  }

  // Private helper methods
  void _refreshProductsInBackground(ProductFilters? filters) {
    // Fetch fresh data in background without waiting
    _productApi.getProducts(filters: filters).then((response) {
      if (response.isSuccess && response.data != null) {
        final cacheKey = 'products_${filters?.toQueryParams().toString() ?? 'default'}';
        _listCache[cacheKey] = response.data!;
        
        // Update individual product cache
        for (final product in response.data!.products) {
          _productCache[product.id] = product;
        }
      }
    }).catchError((e) {
      // Silently handle background refresh errors
    });
  }

  void _refreshProductInBackground(int productId) {
    _productApi.getProduct(productId).then((response) {
      if (response.isSuccess && response.data != null) {
        _productCache[productId] = response.data!;
      }
    }).catchError((e) {
      // Silently handle background refresh errors
    });
  }

  Future<void> _addToRecentlyViewed(int productId) async {
    await _preferences.addRecentlyViewed(productId);
  }

  Future<void> _addToSearchHistory(String query) async {
    if (query.trim().isNotEmpty) {
      await _preferences.addSearchHistory(query.trim());
    }
  }
}
