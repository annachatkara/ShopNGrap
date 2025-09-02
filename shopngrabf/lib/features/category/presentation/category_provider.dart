// Category provider
import 'package:flutter/foundation.dart';
import '../../../core/utils/error_handler.dart';
import '../data/category_repository.dart';
import '../domain/category_model.dart';

enum CategoryState {
  initial,
  loading,
  loaded,
  error,
  empty,
}

class CategoryProvider with ChangeNotifier {
  final CategoryRepository _categoryRepository = CategoryRepository();

  // State variables
  CategoryState _state = CategoryState.initial;
  List<Category> _categories = [];
  List<Category> _mainCategories = [];
  List<Category> _featuredCategories = [];
  List<Category> _categoryTree = [];
  Category? _selectedCategory;
  String? _errorMessage;
  bool _isLoading = false;

  // Filtering and search
  CategoryFilters _filters = const CategoryFilters();
  List<Category> _searchResults = [];
  String _searchQuery = '';
  bool _isSearching = false;

  // Admin state
  List<Category> _adminCategories = [];
  CategoryStatistics? _categoryStatistics;
  bool _isLoadingStatistics = false;
  bool _isCreatingCategory = false;
  bool _isUpdatingCategory = false;

  // User preferences
  List<int> _favoriteCategories = [];
  List<int> _recentlyViewedCategories = [];

  // Hierarchical navigation
  List<Category> _breadcrumbs = [];
  Category? _currentParentCategory;

  // Getters
  CategoryState get state => _state;
  List<Category> get categories => _categories;
  List<Category> get mainCategories => _mainCategories;
  List<Category> get featuredCategories => _featuredCategories;
  List<Category> get categoryTree => _categoryTree;
  Category? get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasError => _state == CategoryState.error;
  bool get isEmpty => _state == CategoryState.empty;
  bool get hasCategories => _categories.isNotEmpty;

  // Search getters
  List<Category> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  bool get hasSearchResults => _searchResults.isNotEmpty;

  // Admin getters
  List<Category> get adminCategories => _adminCategories;
  CategoryStatistics? get categoryStatistics => _categoryStatistics;
  bool get isLoadingStatistics => _isLoadingStatistics;
  bool get isCreatingCategory => _isCreatingCategory;
  bool get isUpdatingCategory => _isUpdatingCategory;

  // User preferences getters
  List<int> get favoriteCategories => _favoriteCategories;
  List<int> get recentlyViewedCategories => _recentlyViewedCategories;

  // Navigation getters
  List<Category> get breadcrumbs => _breadcrumbs;
  Category? get currentParentCategory => _currentParentCategory;
  bool get canGoBack => _breadcrumbs.isNotEmpty;

  // Filters getters
  CategoryFilters get filters => _filters;
  bool get hasActiveFilters => _filters.hasActiveFilters;

  // Initialize
  Future<void> initialize() async {
    await loadMainCategories();
    await loadFeaturedCategories();
    await _loadUserPreferences();
  }

  // Load main categories
  Future<void> loadMainCategories({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    try {
      _setLoading(true);
      _clearError();

      final categories = await _categoryRepository.getMainCategories(
        forceRefresh: forceRefresh,
        activeOnly: true,
      );

      _mainCategories = categories;

      if (_mainCategories.isEmpty) {
        _setState(CategoryState.empty);
      } else {
        _setState(CategoryState.loaded);
      }
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(CategoryState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Load featured categories
  Future<void> loadFeaturedCategories({bool forceRefresh = false}) async {
    try {
      final categories = await _categoryRepository.getFeaturedCategories(
        forceRefresh: forceRefresh,
        limit: 10,
      );
      
      _featuredCategories = categories;
      notifyListeners();
    } catch (e) {
      // Silently handle featured categories error
    }
  }

  // Load category tree
  Future<void> loadCategoryTree({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final tree = await _categoryRepository.getCategoryTree(
        forceRefresh: forceRefresh,
      );

      _categoryTree = tree;
      _setState(CategoryState.loaded);
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(CategoryState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Get subcategories
  Future<List<Category>> getSubcategories(int parentId, {bool forceRefresh = false}) async {
    try {
      return await _categoryRepository.getSubcategories(parentId, forceRefresh: forceRefresh);
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return [];
    }
  }

  // Get single category
  Future<bool> getCategory(int categoryId, {bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final category = await _categoryRepository.getCategory(categoryId, forceRefresh: forceRefresh);
      _selectedCategory = category;

      // Update breadcrumbs
      _updateBreadcrumbs(category);

      // Add to recently viewed
      await _addToRecentlyViewed(categoryId);

      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Navigate to category
  Future<void> navigateToCategory(Category category) async {
    _selectedCategory = category;
    _updateBreadcrumbs(category);
    await _addToRecentlyViewed(category.id);
    notifyListeners();
  }

  // Navigate to parent category
  Future<void> navigateToParent() async {
    if (_breadcrumbs.length > 1) {
      final parent = _breadcrumbs[_breadcrumbs.length - 2];
      await navigateToCategory(parent);
    } else {
      // Navigate to main categories
      _selectedCategory = null;
      _breadcrumbs.clear();
      _currentParentCategory = null;
      notifyListeners();
    }
  }

  // Search categories
  Future<void> searchCategories(String query) async {
    if (query.trim().isEmpty) {
      _clearSearch();
      return;
    }

    try {
      _setSearching(true);
      _searchQuery = query.trim();

      final results = await _categoryRepository.searchCategories(_searchQuery);
      _searchResults = results;

      notifyListeners();
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _searchResults = [];
    } finally {
      _setSearching(false);
    }
  }

  // Clear search
  void _clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  // Apply filters
  Future<void> applyFilters(CategoryFilters newFilters) async {
    _filters = newFilters;
    await _loadFilteredCategories();
  }

  // Clear filters
  Future<void> clearFilters() async {
    _filters = const CategoryFilters();
    await _loadFilteredCategories();
  }

  // Load filtered categories
  Future<void> _loadFilteredCategories() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _categoryRepository.getCategories(
        filters: _filters,
        forceRefresh: true,
      );

      _categories = response.categories;

      if (_categories.isEmpty) {
        _setState(CategoryState.empty);
      } else {
        _setState(CategoryState.loaded);
      }
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(CategoryState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Admin: Load all categories
  Future<void> loadAdminCategories({
    CategoryFilters? filters,
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;

    try {
      _setLoading(true);
      _clearError();

      final response = await _categoryRepository.getAllCategoriesAdmin(
        filters: filters,
        forceRefresh: forceRefresh,
      );

      _adminCategories = response.categories;

      if (_adminCategories.isEmpty) {
        _setState(CategoryState.empty);
      } else {
        _setState(CategoryState.loaded);
      }
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to manage categories');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      _setState(CategoryState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Admin: Create category
  Future<Category?> createCategory(CreateCategoryRequest request) async {
    try {
      _setCreatingCategory(true);
      _clearError();

      final category = await _categoryRepository.createCategory(request);

      // Add to admin categories list
      _adminCategories.insert(0, category);

      // Clear main categories cache to refresh
      _clearCaches();

      return category;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to create categories');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return null;
    } finally {
      _setCreatingCategory(false);
    }
  }

  // Admin: Update category
  Future<Category?> updateCategory(int categoryId, UpdateCategoryRequest request) async {
    try {
      _setUpdatingCategory(true);
      _clearError();

      final category = await _categoryRepository.updateCategory(categoryId, request);

      // Update in admin categories list
      final index = _adminCategories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _adminCategories[index] = category;
      }

      // Update selected category if it's the same
      if (_selectedCategory?.id == categoryId) {
        _selectedCategory = category;
      }

      // Clear caches
      _clearCaches();

      return category;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to update categories');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return null;
    } finally {
      _setUpdatingCategory(false);
    }
  }

  // Admin: Delete category
  Future<bool> deleteCategory(int categoryId) async {
    try {
      _setUpdatingCategory(true);
      _clearError();

      final success = await _categoryRepository.deleteCategory(categoryId);

      if (success) {
        // Remove from admin categories list
        _adminCategories.removeWhere((c) => c.id == categoryId);

        // Clear selected category if it's the deleted one
        if (_selectedCategory?.id == categoryId) {
          _selectedCategory = null;
        }

        // Clear caches
        _clearCaches();

        return true;
      }

      return false;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to delete categories');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return false;
    } finally {
      _setUpdatingCategory(false);
    }
  }

  // Admin: Bulk update category status
  Future<bool> bulkUpdateCategoryStatus(List<int> categoryIds, bool isActive) async {
    try {
      _setUpdatingCategory(true);
      _clearError();

      final updatedCategories = await _categoryRepository.bulkUpdateCategoryStatus(
        categoryIds,
        isActive,
      );

      // Update admin categories list
      for (final updatedCategory in updatedCategories) {
        final index = _adminCategories.indexWhere((c) => c.id == updatedCategory.id);
        if (index != -1) {
          _adminCategories[index] = updatedCategory;
        }
      }

      _clearCaches();
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to update categories');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return false;
    } finally {
      _setUpdatingCategory(false);
    }
  }

  // Admin: Load statistics
  Future<void> loadCategoryStatistics() async {
    try {
      _setLoadingStatistics(true);
      _clearError();

      final stats = await _categoryRepository.getCategoryStatistics();
      _categoryStatistics = stats;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to view statistics');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
    } finally {
      _setLoadingStatistics(false);
    }
  }

  // Upload category image
  Future<String?> uploadCategoryImage(String filePath, String fileName) async {
    try {
      return await _categoryRepository.uploadCategoryImage(filePath, fileName);
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return null;
    }
  }

  // User preferences: Toggle favorite category
  Future<void> toggleFavoriteCategory(int categoryId) async {
    if (_favoriteCategories.contains(categoryId)) {
      _favoriteCategories.remove(categoryId);
    } else {
      _favoriteCategories.add(categoryId);
    }

    await _categoryRepository.saveFavoriteCategories(_favoriteCategories);
    notifyListeners();
  }

  // Check if category is favorite
  bool isFavoriteCategory(int categoryId) {
    return _favoriteCategories.contains(categoryId);
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
      return await _categoryRepository.getProductsByCategory(
        categoryId,
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
        includeSubcategories: includeSubcategories,
      );
    } catch (e) {
      return {'products': [], 'pagination': {}};
    }
  }

  // Helper methods for category hierarchy
  List<Category> getCategoriesByParent(int? parentId) {
    return _categories.where((c) => c.parentId == parentId).toList();
  }

  List<Category> getMainCategoriesWithChildren() {
    return _mainCategories.where((c) => c.hasChildren).toList();
  }

  List<Category> getCategoriesWithProducts() {
    return _categories.where((c) => c.hasProducts).toList();
  }

  // Sort categories locally
  void sortCategories(String sortBy) {
    switch (sortBy) {
      case 'name':
        _categories.sort((a, b) => a.name.compareTo(b.name));
        _adminCategories.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'productCount':
        _categories.sort((a, b) => b.productCount.compareTo(a.productCount));
        _adminCategories.sort((a, b) => b.productCount.compareTo(a.productCount));
        break;
      case 'sortOrder':
        _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _adminCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case 'createdAt':
        _categories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _adminCategories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    _clearCaches();
    await loadMainCategories(forceRefresh: true);
    await loadFeaturedCategories(forceRefresh: true);
  }

  // Private helper methods
  void _setState(CategoryState state) {
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

  void _setSearching(bool searching) {
    if (_isSearching != searching) {
      _isSearching = searching;
      notifyListeners();
    }
  }

  void _setCreatingCategory(bool creating) {
    if (_isCreatingCategory != creating) {
      _isCreatingCategory = creating;
      notifyListeners();
    }
  }

  void _setUpdatingCategory(bool updating) {
    if (_isUpdatingCategory != updating) {
      _isUpdatingCategory = updating;
      notifyListeners();
    }
  }

  void _setLoadingStatistics(bool loading) {
    if (_isLoadingStatistics != loading) {
      _isLoadingStatistics = loading;
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

  void _updateBreadcrumbs(Category category) {
    _breadcrumbs = category.breadcrumbs;
    _currentParentCategory = category.parent;
    notifyListeners();
  }

  Future<void> _addToRecentlyViewed(int categoryId) async {
    _recentlyViewedCategories.remove(categoryId); // Remove if already exists
    _recentlyViewedCategories.insert(0, categoryId); // Add to beginning

    // Keep only last 10
    if (_recentlyViewedCategories.length > 10) {
      _recentlyViewedCategories = _recentlyViewedCategories.take(10).toList();
    }

    await _categoryRepository.saveRecentlyViewedCategories(_recentlyViewedCategories);
  }

  Future<void> _loadUserPreferences() async {
    _favoriteCategories = await _categoryRepository.getFavoriteCategoryIds();
    _recentlyViewedCategories = await _categoryRepository.getRecentlyViewedCategoryIds();
    notifyListeners();
  }

  void _clearCaches() {
    _categoryRepository.clearAllCache();
    _categories.clear();
    _mainCategories.clear();
    _featuredCategories.clear();
    _categoryTree.clear();
  }

  // Reset state
  void reset() {
    _state = CategoryState.initial;
    _categories.clear();
    _mainCategories.clear();
    _featuredCategories.clear();
    _categoryTree.clear();
    _adminCategories.clear();
    _selectedCategory = null;
    _categoryStatistics = null;
    _searchResults.clear();
    _searchQuery = '';
    _breadcrumbs.clear();
    _currentParentCategory = null;
    _filters = const CategoryFilters();
    _errorMessage = null;
    _isLoading = false;
    _isSearching = false;
    _isCreatingCategory = false;
    _isUpdatingCategory = false;
    _isLoadingStatistics = false;
    notifyListeners();
  }
}
