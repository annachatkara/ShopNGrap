// Product model
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isActive;
  final int categoryId;
  final String categoryName;
  final int shopId;
  final String shopName;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.isActive,
    required this.categoryId,
    required this.categoryName,
    required this.shopId,
    required this.shopName,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      categoryId: json['categoryId'] ?? json['category']?['id'] ?? 0,
      categoryName: json['categoryName'] ?? json['category']?['name'] ?? '',
      shopId: json['shopId'] ?? json['shop']?['id'] ?? 0,
      shopName: json['shopName'] ?? json['shop']?['shopName'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'shopId': shopId,
      'shopName': shopName,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? imageUrl,
    bool? isActive,
    int? categoryId,
    String? categoryName,
    int? shopId,
    String? shopName,
    double? averageRating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isInStock => stock > 0;
  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 5;
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }
  
  Color get stockStatusColor {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  String get displayRating => averageRating > 0 ? averageRating.toStringAsFixed(1) : 'No rating';
  String get reviewText => reviewCount == 1 ? 'review' : 'reviews';
  
  bool get hasDiscount => false; // You can add discount logic here
  double get discountPercentage => 0.0; // You can add discount logic here

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, stock: $stock)';
  }
}

class ProductFilters {
  final String? search;
  final int? categoryId;
  final int? shopId;
  final double? minPrice;
  final double? maxPrice;
  final bool? inStockOnly;
  final String? sortBy; // 'newest', 'price_low', 'price_high', 'rating', 'name'
  final int page;
  final int limit;

  const ProductFilters({
    this.search,
    this.categoryId,
    this.shopId,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly,
    this.sortBy,
    this.page = 1,
    this.limit = 10,
  });

  ProductFilters copyWith({
    String? search,
    int? categoryId,
    int? shopId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    String? sortBy,
    int? page,
    int? limit,
  }) {
    return ProductFilters(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      shopId: shopId ?? this.shopId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['category'] = categoryId;
    if (shopId != null) params['shop'] = shopId;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (inStockOnly == true) params['inStock'] = 'true';
    if (sortBy != null) params['sortBy'] = sortBy;

    return params;
  }

  bool get hasActiveFilters {
    return search != null ||
           categoryId != null ||
           shopId != null ||
           minPrice != null ||
           maxPrice != null ||
           inStockOnly == true ||
           sortBy != null;
  }

  ProductFilters clearFilters() {
    return const ProductFilters();
  }
}

class CreateProductRequest {
  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final String? imageUrl;

  const CreateProductRequest({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
    };
  }
}

class UpdateProductRequest {
  final String? name;
  final String? description;
  final double? price;
  final int? stock;
  final int? categoryId;
  final String? imageUrl;
  final bool? isActive;

  const UpdateProductRequest({
    this.name,
    this.description,
    this.price,
    this.stock,
    this.categoryId,
    this.imageUrl,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (stock != null) data['stock'] = stock;
    if (categoryId != null) data['categoryId'] = categoryId;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (isActive != null) data['isActive'] = isActive;
    
    return data;
  }

  bool get hasChanges {
    return name != null ||
           description != null ||
           price != null ||
           stock != null ||
           categoryId != null ||
           imageUrl != null ||
           isActive != null;
  }
}

class ProductsResponse {
  final List<Product> products;
  final Pagination pagination;

  const ProductsResponse({
    required this.products,
    required this.pagination,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    final productsList = json['products'] as List<dynamic>? ?? [];
    return ProductsResponse(
      products: productsList.map((product) => Product.fromJson(product)).toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
    );
  }

  bool get hasNextPage => page < pages;
  bool get hasPreviousPage => page > 1;
  int get nextPage => hasNextPage ? page + 1 : page;
  int get previousPage => hasPreviousPage ? page - 1 : page;
  
  String get displayText => 'Page $page of $pages ($total items)';
}
