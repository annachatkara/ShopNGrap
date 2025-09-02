// Order model
import '../../../core/utils/formatters.dart';
import '../../cart/domain/cart_model.dart';
import '../../address/domain/address_model.dart';
import '../../product/domain/product_model.dart';

enum OrderStatus {
  pending('pending', 'Order Placed', 'Your order has been placed successfully'),
  confirmed('confirmed', 'Order Confirmed', 'Your order has been confirmed by the shop'),
  preparing('preparing', 'Preparing Order', 'Your order is being prepared'),
  ready('ready', 'Ready for Pickup', 'Your order is ready for pickup'),
  completed('completed', 'Completed', 'Order completed successfully'),
  cancelled('cancelled', 'Cancelled', 'Order has been cancelled'),
  refunded('refunded', 'Refunded', 'Order has been refunded');

  const OrderStatus(this.value, this.title, this.description);
  
  final String value;
  final String title;
  final String description;
  
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.grey;
    }
  }
  
  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.kitchen;
      case OrderStatus.ready:
        return Icons.shopping_bag;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.refunded:
        return Icons.money_off;
    }
  }
  
  bool get canCancel => this == OrderStatus.pending || this == OrderStatus.confirmed;
  bool get canMarkReady => this == OrderStatus.confirmed || this == OrderStatus.preparing;
  bool get canComplete => this == OrderStatus.ready;
  bool get isActive => this != OrderStatus.completed && this != OrderStatus.cancelled && this != OrderStatus.refunded;
  bool get isCompleted => this == OrderStatus.completed;
  bool get isCancelled => this == OrderStatus.cancelled;
  
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

enum PaymentMethod {
  cash('cash', 'Cash on Pickup', Icons.money),
  card('card', 'Card Payment', Icons.credit_card),
  upi('upi', 'UPI Payment', Icons.payment),
  wallet('wallet', 'Digital Wallet', Icons.account_balance_wallet);

  const PaymentMethod(this.value, this.title, this.icon);
  
  final String value;
  final String title;
  final IconData icon;
  
  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

enum PaymentStatus {
  pending('pending', 'Payment Pending'),
  paid('paid', 'Payment Completed'),
  failed('failed', 'Payment Failed'),
  refunded('refunded', 'Payment Refunded');

  const PaymentStatus(this.value, this.title);
  
  final String value;
  final String title;
  
  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.grey;
    }
  }
  
  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final String productDescription;
  final double productPrice;
  final String? productImageUrl;
  final int quantity;
  final double totalPrice;
  final int shopId;
  final String shopName;
  final bool isAvailable; // Product still available at order time
  final DateTime createdAt;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    this.productImageUrl,
    required this.quantity,
    required this.totalPrice,
    required this.shopId,
    required this.shopName,
    required this.isAvailable,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final shop = product['shop'] ?? {};

    return OrderItem(
      id: json['id'] ?? 0,
      orderId: json['orderId'] ?? 0,
      productId: json['productId'] ?? product['id'] ?? 0,
      productName: product['name'] ?? json['productName'] ?? '',
      productDescription: product['description'] ?? json['productDescription'] ?? '',
      productPrice: (json['productPrice'] ?? product['price'] ?? 0).toDouble(),
      productImageUrl: product['imageUrl'] ?? json['productImageUrl'],
      quantity: json['quantity'] ?? 1,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      shopId: json['shopId'] ?? shop['id'] ?? 0,
      shopName: json['shopName'] ?? shop['shopName'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'productDescription': productDescription,
      'productPrice': productPrice,
      'productImageUrl': productImageUrl,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'shopId': shopId,
      'shopName': shopName,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  String get formattedPrice => Formatters.currency(productPrice);
  String get formattedTotal => Formatters.currency(totalPrice);
  double get unitPrice => productPrice;
  double get savings => 0.0; // Could add discount logic

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OrderItem(id: $id, productName: $productName, quantity: $quantity, totalPrice: $totalPrice)';
  }
}

class Order {
  final int id;
  final int customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final List<OrderItem> items;
  final int totalItems;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? paymentTransactionId;
  final ShopAddress pickupAddress;
  final DateTime? estimatedPickupTime;
  final DateTime? actualPickupTime;
  final String? notes; // Customer notes
  final String? shopNotes; // Shop internal notes
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.items,
    required this.totalItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.discount,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentTransactionId,
    required this.pickupAddress,
    this.estimatedPickupTime,
    this.actualPickupTime,
    this.notes,
    this.shopNotes,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList.map((item) => OrderItem.fromJson(item)).toList();
    
    return Order(
      id: json['id'] ?? 0,
      customerId: json['customerId'] ?? json['customer']?['id'] ?? 0,
      customerName: json['customerName'] ?? json['customer']?['name'] ?? '',
      customerEmail: json['customerEmail'] ?? json['customer']?['email'] ?? '',
      customerPhone: json['customerPhone'] ?? json['customer']?['phone'] ?? '',
      items: items,
      totalItems: json['totalItems'] ?? items.fold(0, (sum, item) => sum + item.quantity),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] ?? 'cash'),
      paymentStatus: PaymentStatus.fromString(json['paymentStatus'] ?? 'pending'),
      paymentTransactionId: json['paymentTransactionId'],
      pickupAddress: ShopAddress.fromJson(json['pickupAddress'] ?? {}),
      estimatedPickupTime: json['estimatedPickupTime'] != null 
          ? DateTime.parse(json['estimatedPickupTime']) 
          : null,
      actualPickupTime: json['actualPickupTime'] != null 
          ? DateTime.parse(json['actualPickupTime']) 
          : null,
      notes: json['notes'],
      shopNotes: json['shopNotes'],
      cancellationReason: json['cancellationReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'totalItems': totalItems,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status.value,
      'paymentMethod': paymentMethod.value,
      'paymentStatus': paymentStatus.value,
      'paymentTransactionId': paymentTransactionId,
      'pickupAddress': pickupAddress.toJson(),
      'estimatedPickupTime': estimatedPickupTime?.toIso8601String(),
      'actualPickupTime': actualPickupTime?.toIso8601String(),
      'notes': notes,
      'shopNotes': shopNotes,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get orderNumber => 'ORD${id.toString().padLeft(6, '0')}';
  String get formattedTotal => Formatters.currency(total);
  String get formattedSubtotal => Formatters.currency(subtotal);
  String get statusTitle => status.title;
  String get statusDescription => status.description;
  Color get statusColor => status.color;
  IconData get statusIcon => status.icon;
  
  bool get canCancel => status.canCancel && paymentStatus != PaymentStatus.paid;
  bool get canMarkReady => status.canMarkReady;
  bool get canComplete => status.canComplete;
  bool get isActive => status.isActive;
  bool get isCompleted => status.isCompleted;
  bool get isCancelled => status.isCancelled;
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isPaymentPending => paymentStatus == PaymentStatus.pending;
  
  // Get unique shops in order
  List<int> get uniqueShopIds => items.map((item) => item.shopId).toSet().toList();
  Map<int, List<OrderItem>> get itemsByShop {
    final grouped = <int, List<OrderItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.shopId, () => []).add(item);
    }
    return grouped;
  }

  // Time helpers
  String get timeAgo => Formatters.timeAgo(createdAt);
  String get formattedCreatedAt => Formatters.dateTime(createdAt);
  String get formattedEstimatedPickup => estimatedPickupTime != null 
      ? Formatters.dateTime(estimatedPickupTime!) 
      : 'Not scheduled';
  
  Duration? get timeSinceOrder {
    return DateTime.now().difference(createdAt);
  }
  
  bool get isOverdue {
    if (estimatedPickupTime == null) return false;
    return DateTime.now().isAfter(estimatedPickupTime!) && !isCompleted && !isCancelled;
  }
  
  // Business logic helpers
  bool get hasUnavailableItems => items.any((item) => !item.isAvailable);
  List<OrderItem> get availableItems => items.where((item) => item.isAvailable).toList();
  List<OrderItem> get unavailableItems => items.where((item) => !item.isAvailable).toList();
  
  double get totalSavings => items.fold(0, (sum, item) => sum + item.savings);
  
  String get pickupInstructions {
    final instructions = <String>[];
    instructions.add('Order Number: $orderNumber');
    instructions.add('Pickup from: ${pickupAddress.shopName}');
    instructions.add('Address: ${pickupAddress.shortAddress}');
    instructions.add('Contact: ${pickupAddress.phone}');
    if (estimatedPickupTime != null) {
      instructions.add('Estimated time: $formattedEstimatedPickup');
    }
    if (notes != null && notes!.isNotEmpty) {
      instructions.add('Note: $notes');
    }
    return instructions.join('\n');
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, status: ${status.value}, total: $total)';
  }
}

class CreateOrderRequest {
  final List<int> cartItemIds; // Cart items to convert to order
  final int pickupAddressId; // Shop address for pickup
  final PaymentMethod paymentMethod;
  final String? notes;
  final DateTime? preferredPickupTime;

  const CreateOrderRequest({
    required this.cartItemIds,
    required this.pickupAddressId,
    required this.paymentMethod,
    this.notes,
    this.preferredPickupTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'cartItemIds': cartItemIds,
      'pickupAddressId': pickupAddressId,
      'paymentMethod': paymentMethod.value,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (preferredPickupTime != null) 
        'preferredPickupTime': preferredPickupTime!.toIso8601String(),
    };
  }
}

class UpdateOrderStatusRequest {
  final OrderStatus status;
  final String? notes;
  final DateTime? estimatedPickupTime;
  final DateTime? actualPickupTime;

  const UpdateOrderStatusRequest({
    required this.status,
    this.notes,
    this.estimatedPickupTime,
    this.actualPickupTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (estimatedPickupTime != null) 
        'estimatedPickupTime': estimatedPickupTime!.toIso8601String(),
      if (actualPickupTime != null) 
        'actualPickupTime': actualPickupTime!.toIso8601String(),
    };
  }
}

class CancelOrderRequest {
  final String reason;
  final bool refundRequested;

  const CancelOrderRequest({
    required this.reason,
    this.refundRequested = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'refundRequested': refundRequested,
    };
  }
}

class OrderFilters {
  final OrderStatus? status;
  final PaymentStatus? paymentStatus;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? shopId;
  final String? search; // Search by order number or customer name
  final int page;
  final int limit;
  final String? sortBy; // 'newest', 'oldest', 'amount', 'status'

  const OrderFilters({
    this.status,
    this.paymentStatus,
    this.fromDate,
    this.toDate,
    this.shopId,
    this.search,
    this.page = 1,
    this.limit = 10,
    this.sortBy,
  });

  OrderFilters copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? shopId,
    String? search,
    int? page,
    int? limit,
    String? sortBy,
  }) {
    return OrderFilters(
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      shopId: shopId ?? this.shopId,
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (status != null) params['status'] = status!.value;
    if (paymentStatus != null) params['paymentStatus'] = paymentStatus!.value;
    if (fromDate != null) params['fromDate'] = fromDate!.toIso8601String();
    if (toDate != null) params['toDate'] = toDate!.toIso8601String();
    if (shopId != null) params['shopId'] = shopId;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (sortBy != null) params['sortBy'] = sortBy;

    return params;
  }

  bool get hasActiveFilters {
    return status != null ||
           paymentStatus != null ||
           fromDate != null ||
           toDate != null ||
           shopId != null ||
           search != null ||
           sortBy != null;
  }
}

class OrdersResponse {
  final List<Order> orders;
  final Pagination pagination;
  final OrderStatistics? statistics;

  const OrdersResponse({
    required this.orders,
    required this.pagination,
    this.statistics,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    final ordersList = json['orders'] as List<dynamic>? ?? [];
    return OrdersResponse(
      orders: ordersList.map((order) => Order.fromJson(order)).toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      statistics: json['statistics'] != null 
          ? OrderStatistics.fromJson(json['statistics'])
          : null,
    );
  }
}

class OrderStatistics {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double todayRevenue;
  final double averageOrderValue;

  const OrderStatistics({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.averageOrderValue,
  });

  factory OrderStatistics.fromJson(Map<String, dynamic> json) {
    return OrderStatistics(
      totalOrders: json['totalOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
    );
  }

  String get formattedTotalRevenue => Formatters.currency(totalRevenue);
  String get formattedTodayRevenue => Formatters.currency(todayRevenue);
  String get formattedAverageOrderValue => Formatters.currency(averageOrderValue);
  
  double get completionRate => totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0;
  double get cancellationRate => totalOrders > 0 ? (cancelledOrders / totalOrders) * 100 : 0;
}
