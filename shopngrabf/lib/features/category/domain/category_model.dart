// Category model
import '../../../core/utils/formatters.dart';

class Category {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? iconName; // For icon fonts
  final int? parentId; // For subcategories
  final int sortOrder;
  final bool isActive;
  final bool isFeatured;
  final String? colorCode; // Hex color for category theme
  final int productCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Navigation and hierarchy
  final Category? parent;
  final List<Category> children;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.iconName,
    this.parentId,
    required this.sortOrder,
    required this.isActive,
    required this.isFeatured,
    this.colorCode,
    required this.productCount,
    required this.createdAt,
    required this.updatedAt,
    this.parent,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final childrenList = json['children'] as List<dynamic>? ?? [];
    final children = childrenList.map((child) => Category.fromJson(child)).toList();

    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      iconName: json['iconName'],
      parentId: json['parentId'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      colorCode: json['colorCode'],
      productCount: json['productCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      parent: json['parent'] != null ? Category.fromJson(json['parent']) : null,
      children: children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'iconName': iconName,
      'parentId': parentId,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'colorCode': colorCode,
      'productCount': productCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    String? iconName,
    int? parentId,
    int? sortOrder,
    bool? isActive,
    bool? isFeatured,
    String? colorCode,
    int? productCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? parent,
    List<Category>? children,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      colorCode: colorCode ?? this.colorCode,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parent: parent ?? this.parent,
      children: children ?? this.children,
    );
  }

  // Helper methods
  bool get isMainCategory => parentId == null;
  bool get isSubcategory => parentId != null;
  bool get hasChildren => children.isNotEmpty;
  bool get hasProducts => productCount > 0;

  String get formattedProductCount => Formatters.number(productCount);
  
  Color get categoryColor {
    if (colorCode != null) {
      try {
        return Color(int.parse(colorCode!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }

  IconData get categoryIcon {
    if (iconName != null) {
      // Map icon names to IconData
      switch (iconName!.toLowerCase()) {
        case 'food':
          return Icons.restaurant;
        case 'electronics':
          return Icons.electrical_services;
        case 'clothing':
          return Icons.checkroom;
        case 'books':
          return Icons.book;
        case 'sports':
          return Icons.sports;
        case 'home':
          return Icons.home;
        case 'beauty':
          return Icons.face;
        case 'automotive':
          return Icons.directions_car;
        case 'toys':
          return Icons.toys;
        case 'health':
          return Icons.health_and_safety;
        default:
          return Icons.category;
      }
    }
    return Icons.category;
  }

  // Get full category path (for breadcrumbs)
  String get categoryPath {
    if (parent != null) {
      return '${parent!.categoryPath} > $name';
    }
    return name;
  }

  List<Category> get breadcrumbs {
    if (parent != null) {
      return [...parent!.breadcrumbs, this];
    }
    return [this];
  }

  // Get all subcategories recursively
  List<Category> get allSubcategories {
    final allSubs = <Category>[];
    for (final child in children) {
      allSubs.add(child);
      allSubs.addAll(child.allSubcategories);
    }
    return allSubs;
  }

  // Get category depth level
  int get level {
    if (parent != null) {
      return parent!.level + 1;
    }
    return 0;
  }

  // Get total product count including subcategories
  int get totalProductCount {
    int total = productCount;
    for (final child in children) {
      total += child.totalProductCount;
    }
    return total;
  }

  // Search functionality
  bool containsQuery(String query) {
    final lowercaseQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowercaseQuery) ||
           description.toLowerCase().contains(lowercaseQuery);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, parentId: $parentId, productCount: $productCount)';
  }
}

class CreateCategoryRequest {
  final String name;
  final String description;
  final String? imageUrl;
  final String? iconName;
  final int? parentId;
  final int sortOrder;
  final bool isActive;
  final bool isFeatured;
  final String? colorCode;

  const CreateCategoryRequest({
    required this.name,
    required this.description,
    this.imageUrl,
    this.iconName,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.colorCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (iconName != null && iconName!.isNotEmpty) 'iconName': iconName,
      if (parentId != null) 'parentId': parentId,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'isFeatured': isFeatured,
      if (colorCode != null && colorCode!.isNotEmpty) 'colorCode': colorCode,
    };
  }
}

class UpdateCategoryRequest {
  final String? name;
  final String? description;
  final String? imageUrl;
  final String? iconName;
  final int? parentId;
  final int? sortOrder;
  final bool? isActive;
  final bool? isFeatured;
  final String? colorCode;

  const UpdateCategoryRequest({
    this.name,
    this.description,
    this.imageUrl,
    this.iconName,
    this.parentId,
    this.sortOrder,
    this.isActive,
    this.isFeatured,
    this.colorCode,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (iconName != null) data['iconName'] = iconName;
    if (parentId != null) data['parentId'] = parentId;
    if (sortOrder != null) data['sortOrder'] = sortOrder;
    if (isActive != null) data['isActive'] = isActive;
    if (isFeatured != null) data['isFeatured'] = isFeatured;
    if (colorCode != null) data['colorCode'] = colorCode;
    
    return data;
  }

  bool get hasChanges {
    return name != null ||
           description != null ||
           imageUrl != null ||
           iconName != null ||
           parentId != null ||
           sortOrder != null ||
           isActive != null ||
           isFeatured != null ||
           colorCode != null;
  }
}

class CategoryFilters {
  final bool? isActive;
  final bool? isFeatured;
  final int? parentId;
  final String? search;
  final int page;
  final int limit;
  final String? sortBy; // 'name', 'productCount', 'sortOrder', 'createdAt'
  final String? sortOrder; // 'asc', 'desc'

  const CategoryFilters({
    this.isActive,
    this.isFeatured,
    this.parentId,
    this.search,
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.sortOrder,
  });

  CategoryFilters copyWith({
    bool? isActive,
    bool? isFeatured,
    int? parentId,
    String? search,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) {
    return CategoryFilters(
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      parentId: parentId ?? this.parentId,
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (isActive != null) params['isActive'] = isActive;
    if (isFeatured != null) params['isFeatured'] = isFeatured;
    if (parentId != null) params['parentId'] = parentId;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (sortBy != null) params['sortBy'] = sortBy;
    if (sortOrder != null) params['sortOrder'] = sortOrder;

    return params;
  }

  bool get hasActiveFilters {
    return isActive != null ||
           isFeatured != null ||
           parentId != null ||
           search != null ||
           sortBy != null;
  }
}

class CategoriesResponse {
  final List<Category> categories;
  final Pagination pagination;
  final CategoryStatistics? statistics;

  const CategoriesResponse({
    required this.categories,
    required this.pagination,
    this.statistics,
  });

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    final categoriesList = json['categories'] as List<dynamic>? ?? [];
    return CategoriesResponse(
      categories: categoriesList.map((category) => Category.fromJson(category)).toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      statistics: json['statistics'] != null 
          ? CategoryStatistics.fromJson(json['statistics'])
          : null,
    );
  }
}

class CategoryStatistics {
  final int totalCategories;
  final int mainCategories;
  final int subcategories;
  final int activeCategories;
  final int featuredCategories;
  final int categoriesWithProducts;
  final double averageProductsPerCategory;

  const CategoryStatistics({
    required this.totalCategories,
    required this.mainCategories,
    required this.subcategories,
    required this.activeCategories,
    required this.featuredCategories,
    required this.categoriesWithProducts,
    required this.averageProductsPerCategory,
  });

  factory CategoryStatistics.fromJson(Map<String, dynamic> json) {
    return CategoryStatistics(
      totalCategories: json['totalCategories'] ?? 0,
      mainCategories: json['mainCategories'] ?? 0,
      subcategories: json['subcategories'] ?? 0,
      activeCategories: json['activeCategories'] ?? 0,
      featuredCategories: json['featuredCategories'] ?? 0,
      categoriesWithProducts: json['categoriesWithProducts'] ?? 0,
      averageProductsPerCategory: (json['averageProductsPerCategory'] ?? 0).toDouble(),
    );
  }

  String get formattedAverageProducts => averageProductsPerCategory.toStringAsFixed(1);
  
  double get categoriesWithProductsPercentage => 
      totalCategories > 0 ? (categoriesWithProducts / totalCategories) * 100 : 0;
}

// Built-in category hierarchy for common e-commerce categories
class CategoryHierarchy {
  static const Map<String, List<String>> commonCategories = {
    'Electronics': [
      'Smartphones & Tablets',
      'Laptops & Computers',
      'Audio & Headphones',
      'Cameras & Photography',
      'Gaming',
      'Accessories',
    ],
    'Fashion & Clothing': [
      'Men\'s Clothing',
      'Women\'s Clothing',
      'Kids\' Clothing',
      'Shoes & Footwear',
      'Bags & Accessories',
      'Jewelry & Watches',
    ],
    'Home & Garden': [
      'Furniture',
      'Home Decor',
      'Kitchen & Dining',
      'Bedding & Bath',
      'Garden & Outdoor',
      'Tools & Hardware',
    ],
    'Health & Beauty': [
      'Skincare',
      'Makeup & Cosmetics',
      'Hair Care',
      'Personal Care',
      'Health Supplements',
      'Medical Equipment',
    ],
    'Sports & Outdoors': [
      'Fitness Equipment',
      'Outdoor Gear',
      'Team Sports',
      'Water Sports',
      'Winter Sports',
      'Activewear',
    ],
    'Books & Media': [
      'Fiction Books',
      'Non-Fiction Books',
      'Children\'s Books',
      'Music & Movies',
      'E-books & Audiobooks',
      'Magazines',
    ],
    'Food & Beverages': [
      'Fresh Produce',
      'Packaged Foods',
      'Beverages',
      'Snacks & Sweets',
      'Organic & Natural',
      'International Foods',
    ],
    'Automotive': [
      'Car Parts',
      'Car Accessories',
      'Motorcycle Parts',
      'Car Care',
      'Tools & Equipment',
      'Tires & Wheels',
    ],
  };

  static List<String> getMainCategories() {
    return commonCategories.keys.toList();
  }

  static List<String> getSubcategories(String mainCategory) {
    return commonCategories[mainCategory] ?? [];
  }
}

// Pagination model (if not already defined)
class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int? nextPage;
  final int? previousPage;

  const Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.nextPage,
    this.previousPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      nextPage: json['nextPage'],
      previousPage: json['previousPage'],
    );
  }
}
