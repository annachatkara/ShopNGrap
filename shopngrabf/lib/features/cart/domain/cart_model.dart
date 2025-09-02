// Cart model
class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String productDescription;
  final double productPrice;
  final String? productImageUrl;
  final int quantity;
  final int availableStock;
  final bool isActive;
  final int shopId;
  final String shopName;
  final int categoryId;
  final String categoryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    this.productImageUrl,
    required this.quantity,
    required this.availableStock,
    required this.isActive,
    required this.shopId,
    required this.shopName,
    required this.categoryId,
    required this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final shop = product['shop'] ?? {};
    final category = product['category'] ?? {};

    return CartItem(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? product['id'] ?? 0,
      productName: product['name'] ?? '',
      productDescription: product['description'] ?? '',
      productPrice: (product['price'] ?? 0).toDouble(),
      productImageUrl: product['imageUrl'],
      quantity: json['quantity'] ?? 1,
      availableStock: product['stock'] ?? 0,
      isActive: product['isActive'] ?? true,
      shopId: shop['id'] ?? 0,
      shopName: shop['shopName'] ?? '',
      categoryId: category['id'] ?? 0,
      categoryName: category['name'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productDescription': productDescription,
      'productPrice': productPrice,
      'productImageUrl': productImageUrl,
      'quantity': quantity,
      'availableStock': availableStock,
      'isActive': isActive,
      'shopId': shopId,
      'shopName': shopName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productDescription,
    double? productPrice,
    String? productImageUrl,
    int? quantity,
    int? availableStock,
    bool? isActive,
    int? shopId,
    String? shopName,
    int? categoryId,
    String? categoryName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productPrice: productPrice ?? this.productPrice,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
      isActive: isActive ?? this.isActive,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  double get totalPrice => productPrice * quantity;
  double get savings => 0.0; // You can add discount logic here
  bool get isInStock => availableStock >= quantity;
  bool get isOutOfStock => availableStock == 0;
  bool get isLowStock => availableStock > 0 && availableStock < 5;
  bool get canIncreaseQuantity => quantity < availableStock && quantity < 10;
  bool get canDecreaseQuantity => quantity > 1;
  
  String get stockWarning {
    if (isOutOfStock) return 'Out of stock';
    if (!isInStock) return 'Only $availableStock available';
    if (isLowStock) return 'Only $availableStock left';
    return '';
  }

  Color get stockWarningColor {
    if (isOutOfStock || !isInStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.transparent;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id && other.productId == productId;
  }

  @override
  int get hashCode => id.hashCode ^ productId.hashCode;

  @override
  String toString() {
    return 'CartItem(id: $id, productId: $productId, productName: $productName, quantity: $quantity)';
  }
}

class Cart {
  final List<CartItem> items;
  final int totalItems;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final DateTime? lastUpdated;

  const Cart({
    required this.items,
    required this.totalItems,
    required this.subtotal,
    this.deliveryFee = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    this.lastUpdated,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList.map((item) => CartItem.fromJson(item)).toList();
    
    return Cart(
      items: items,
      totalItems: json['totalItems'] ?? items.fold(0, (sum, item) => sum + item.quantity),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'totalItems': totalItems,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'discount': discount,
      'total': total,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  Cart copyWith({
    List<CartItem>? items,
    int? totalItems,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? discount,
    double? total,
    DateTime? lastUpdated,
  }) {
    return Cart(
      items: items ?? this.items,
      totalItems: totalItems ?? this.totalItems,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper methods
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get hasUnavailableItems => items.any((item) => !item.isInStock || !item.isActive);
  List<CartItem> get availableItems => items.where((item) => item.isInStock && item.isActive).toList();
  List<CartItem> get unavailableItems => items.where((item) => !item.isInStock || !item.isActive).toList();
  
  // Get items grouped by shop
  Map<String, List<CartItem>> get itemsByShop {
    final grouped = <String, List<CartItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.shopName, () => []).add(item);
    }
    return grouped;
  }

  // Get unique shop count
  int get uniqueShopCount {
    return items.map((item) => item.shopId).toSet().length;
  }

  // Check if cart contains product
  bool containsProduct(int productId) {
    return items.any((item) => item.productId == productId);
  }

  // Get item by product ID
  CartItem? getItemByProductId(int productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Calculate savings
  double get totalSavings => items.fold(0, (sum, item) => sum + item.savings);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cart && 
           other.items.length == items.length &&
           other.total == total;
  }

  @override
  int get hashCode => items.hashCode ^ total.hashCode;

  @override
  String toString() {
    return 'Cart(items: ${items.length}, total: $total, subtotal: $subtotal)';
  }
}

class AddToCartRequest {
  final int productId;
  final int quantity;

  const AddToCartRequest({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}

class UpdateCartItemRequest {
  final int quantity;

  const UpdateCartItemRequest({required this.quantity});

  Map<String, dynamic> toJson() {
    return {'quantity': quantity};
  }
}

class CartSummary {
  final int totalItems;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final double savings;

  const CartSummary({
    required this.totalItems,
    required this.subtotal,
    this.deliveryFee = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    this.savings = 0.0,
  });

  factory CartSummary.fromCart(Cart cart) {
    return CartSummary(
      totalItems: cart.totalItems,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      tax: cart.tax,
      discount: cart.discount,
      total: cart.total,
      savings: cart.totalSavings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'discount': discount,
      'total': total,
      'savings': savings,
    };
  }
}
