// Product provider
import 'package:flutter/foundation.dart';
import '../../../core/utils/error_handler.dart';
import '../data/product_repository.dart';
import '../domain/product_model.dart';

enum ProductState {
  initial,
  loading,
  loaded,
  error,
  empty,
}

class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();

  // State variables
  ProductState _state = ProductState.initial;
  List<Product> _products = [];
  Product? _selectedProduct;
  Pagination? _pagination;
  ProductFilters _filters = const ProductFilters();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  // Search and recently viewed
  List<String> _searchHistory = [];
  List<Product> _recentlyViewed = [];
  String _searchQuery = '';

  // Admin products (separate state)
  List<Product> _myProducts = [];
  bool _isLoadingMyProducts = false;
  Pagination? _myProductsPagination;

  // Getters
  ProductState get state => _state;
  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  Pagination? get pagination => _pagination;
  ProductFilters get filters => _filters;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasReachedMax => _hasReachedMax;
  bool get hasError => _state == ProductState.error;
  bool get isEmpty => _state == ProductState.empty;
  bool get hasProducts => _products.isNotEmpty;

  // Search getters
  List<String> get searchHistory => _searchHistory;
  List<Product> get recentlyViewed => _recentlyViewed;
  String get searchQuery => _searchQuery;

  // Admin getters
  List<Product> get myProducts => _myProducts;
  bool get isLoadingMyProducts => _isLoadingMyProducts;
  Pagination? get myProductsPagination => _myProductsPagination;

  // Filter helpers
  bool get hasActiveFilters => _filters.hasActiveFilters;
  int get totalProducts => _pagination?.total ?? 0;
  String get resultsText {
    if (totalProducts == 0) return 'No products found';
    if (totalProducts == 1) return '1 product found';
    return '$totalProducts products found';
  }

  // Initialize
  Future<void> initialize() async {
    await loadSearchHistory();
    await loadRecentlyViewed();
    await loadProducts();
  }

  // Load products
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _products.clear();
      _pagination = null;
      _hasReachedMax = false;
    }

    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      final response = await _productRepository.getProducts(filters: _filters);
      
      if (response.products.isEmpty && _products.isEmpty) {
        _setState(ProductState.empty);
      } else {
        _products = response.products;
        _pagination = response.pagination;
        _hasReachedMax = !response.pagination.hasNextPage;
        _setState(ProductState.loaded);
      }
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(ProductState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || _hasReachedMax || _pagination == null) return;

    try {
      _setLoadingMore(true);

      final nextFilters = _filters.copyWith(page: _pagination!.nextPage);
      final response = await _productRepository.getProducts(filters: nextFilters);
      
      _products.addAll(response.products);
      _pagination = response.pagination;
      _hasReachedMax = !response.pagination.hasNextPage;
      _filters = nextFilters;
      
      notifyListeners();
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
    } finally {
      _setLoadingMore(false);
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    _searchQuery = query;
    _filters = _filters.copyWith(search: query, page: 1);
    await loadProducts(refresh: true);
  }

  // Clear search
  Future<void> clearSearch() async {
    _searchQuery = '';
    _filters = _filters.copyWith(search: null, page: 1);
    await loadProducts(refresh: true);
  }

  // Apply filters
  Future<void> applyFilters(ProductFilters newFilters) async {
    _filters = newFilters.copyWith(page: 1);
    await loadProducts(refresh: true);
  }

  // Clear filters
  Future<void> clearFilters() async {
    _filters = const ProductFilters();
    await loadProducts(refresh: true);
  }

  // Sort products
  Future<void> sortProducts(String sortBy) async {
    _filters = _filters.copyWith(sortBy: sortBy, page: 1);
    await loadProducts(refresh: true);
  }

  // Filter by category
  Future<void> filterByCategory(int? categoryId) async {
    _filters = _filters.copyWith(categoryId: categoryId, page: 1);
    await loadProducts(refresh: true);
  }

  // Filter by shop
  Future<void> filterByShop(int? shopId) async {
    _filters = _filters.copyWith(shopId: shopId, page: 1);
    await loadProducts(refresh: true);
  }

  // Filter by price range
  Future<void> filterByPriceRange(double? minPrice, double? maxPrice) async {
    _filters = _filters.copyWith(minPrice: minPrice, maxPrice: maxPrice, page: 1);
    await loadProducts(refresh: true);
  }

  // Filter in stock only
  Future<void> filterInStockOnly(bool inStockOnly) async {
    _filters = _filters.copyWith(inStockOnly: inStockOnly ? true : null, page: 1);
    await loadProducts(refresh: true);
  }

  // Get single product
  Future<bool> getProduct(int productId) async {
    try {
      _setLoading(true);
      _clearError();

      final product = await _productRepository.getProduct(productId);
      _selectedProduct = product;
      
      // Add to recently viewed
      await _addToRecentlyViewed(product);
      
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load products by category
  Future<void> loadProductsByCategory(int categoryId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _productRepository.getProductsByCategory(
        categoryId,
        filters: _filters,
      );
      
      if (response.products.isEmpty) {
        _setState(ProductState.empty);
      } else {
        _products = response.products;
        _pagination = response.pagination;
        _hasReachedMax = !response.pagination.hasNextPage;
        _setState(ProductState.loaded);
      }
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(ProductState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Load products by shop
  Future<void> loadProductsByShop(int shopId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _productRepository.getProductsByShop(
        shopId,
        filters: _filters,
      );
      
      if (response.products.isEmpty) {
        _setState(ProductState.empty);
      } else {
        _products = response.products;
        _pagination = response.pagination;
        _hasReachedMax = !response.pagination.hasNextPage;
        _setState(ProductState.loaded);
      }
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(ProductState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Admin: Load my products
  Future<void> loadMyProducts({bool refresh = false}) async {
    if (refresh) {
      _myProducts.clear();
      _myProductsPagination = null;
    }

    if (_isLoadingMyProducts) return;

    try {
      _setLoadingMyProducts(true);

      final response = await _productRepository.getMyProducts(
        filters: const ProductFilters(page: 1, limit: 20),
      );
      
      _myProducts = response.products;
      _myProductsPagination = response.pagination;
      
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to view your products');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
    } finally {
      _setLoadingMyProducts(false);
    }
  }

  // Admin: Create product
  Future<bool> createProduct(CreateProductRequest request) async {
    try {
      _setLoading(true);
      _clearError();

      final product = await _productRepository.createProduct(request);
      
      // Add to my products list
      _myProducts.insert(0, product);
      
      // Also add to main products list if it matches current filters
      if (_shouldIncludeInCurrentList(product)) {
        _products.insert(0, product);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to create products');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Admin: Update product
  Future<bool> updateProduct(int productId, UpdateProductRequest request) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedProduct = await _productRepository.updateProduct(productId, request);
      
      // Update in my products list
      final myIndex = _myProducts.indexWhere((p) => p.id == productId);
      if (myIndex != -1) {
        _myProducts[myIndex] = updatedProduct;
      }
      
      // Update in main products list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      
      // Update selected product if it's the same
      if (_selectedProduct?.id == productId) {
        _selectedProduct = updatedProduct;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to update products');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Admin: Delete product
  Future<bool> deleteProduct(int productId) async {
    try {
      _setLoading(true);
      _clearError();

      await _productRepository.deleteProduct(productId);
      
      // Remove from my products list
      _myProducts.removeWhere((p) => p.id == productId);
      
      // Remove from main products list
      _products.removeWhere((p) => p.id == productId);
      
      // Clear selected product if it's the same
      if (_selectedProduct?.id == productId) {
        _selectedProduct = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to delete products');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search history management
  Future<void> loadSearchHistory() async {
    _searchHistory = _productRepository.getSearchHistory();
    notifyListeners();
  }

  Future<void> clearSearchHistory() async {
    await _productRepository.clearSearchHistory();
    _searchHistory.clear();
    notifyListeners();
  }

  // Recently viewed management
  Future<void> loadRecentlyViewed() async {
    try {
      _recentlyViewed = await _productRepository.getRecentlyViewedProducts();
      notifyListeners();
    } catch (e) {
      // Silently handle error
    }
  }

  Future<void> _addToRecentlyViewed(Product product) async {
    // Remove if already exists
    _recentlyViewed.removeWhere((p) => p.id == product.id);
    
    // Add to beginning
    _recentlyViewed.insert(0, product);
    
    // Keep only last 20
    if (_recentlyViewed.length > 20) {
      _recentlyViewed = _recentlyViewed.take(20).toList();
    }
    
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await loadProducts(refresh: true);
    await loadRecentlyViewed();
  }

  // Clear cache
  void clearCache() {
    _productRepository.clearCache();
  }

  // Private helper methods
  void _setState(ProductState state) {
    if (_state != state) {
      _state = state;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setLoadingMore(bool loading) {
    if (_isLoadingMore != loading) {
      _isLoadingMore = loading;
      notifyListeners();
    }
  }

  void _setLoadingMyProducts(bool loading) {
    if (_isLoadingMyProducts != loading) {
      _isLoadingMyProducts = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  bool _shouldIncludeInCurrentList(Product product) {
    // Check if the product matches current filters
    if (_filters.categoryId != null && product.categoryId != _filters.categoryId) {
      return false;
    }
    
    if (_filters.shopId != null && product.shopId != _filters.shopId) {
      return false;
    }
    
    if (_filters.search != null && _filters.search!.isNotEmpty) {
      final query = _filters.search!.toLowerCase();
      if (!product.name.toLowerCase().contains(query) &&
          !product.description.toLowerCase().contains(query)) {
        return false;
      }
    }
    
    if (_filters.inStockOnly == true && product.isOutOfStock) {
      return false;
    }
    
    if (_filters.minPrice != null && product.price < _filters.minPrice!) {
      return false;
    }
    
    if (_filters.maxPrice != null && product.price > _filters.maxPrice!) {
      return false;
    }
    
    return true;
  }

  // Reset all state
  void reset() {
    _state = ProductState.initial;
    _products.clear();
    _selectedProduct = null;
    _pagination = null;
    _filters = const ProductFilters();
    _errorMessage = null;
    _isLoading = false;
    _isLoadingMore = false;
    _hasReachedMax = false;
    _searchQuery = '';
    _myProducts.clear();
    _isLoadingMyProducts = false;
    _myProductsPagination = null;
    notifyListeners();
  }
}
