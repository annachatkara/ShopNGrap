// Order repository implementation
import '../../../core/storage/preferences.dart';
import '../../../core/utils/error_handler.dart';
import '../domain/order_model.dart';
import 'order_api.dart';

class OrderRepository {
  final OrderApi _orderApi = OrderApi();
  final Preferences _preferences = Preferences();

  // Cache for orders
  final Map<int, Order> _orderCache = {};
  final Map<String, OrdersResponse> _ordersListCache = {};
  DateTime? _lastFetchTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 2);

  // Get user's orders (customer view)
  Future<OrdersResponse> getMyOrders({
    OrderFilters? filters,
    bool forceRefresh = false,
  }) async {
    try {
      // Create cache key
      final cacheKey = 'my_orders_${filters?.toQueryParams().toString() ?? 'default'}';
      
      // Check cache first
      if (!forceRefresh && _isListCacheValid(cacheKey)) {
        return _ordersListCache[cacheKey]!;
      }

      final response = await _orderApi.getMyOrders(filters: filters);
      
      if (response.isSuccess && response.data != null) {
        // Cache the response
        _ordersListCache[cacheKey] = response.data!;
        _lastFetchTime = DateTime.now();
        
        // Cache individual orders
        for (final order in response.data!.orders) {
          _orderCache[order.id] = order;
        }
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load orders',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load orders. Please try again.',
        originalError: e,
      );
    }
  }

  // Get single order details
  Future<Order> getOrder(int orderId, {bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh && _orderCache.containsKey(orderId)) {
        return _orderCache[orderId]!;
      }

      final response = await _orderApi.getOrder(orderId);
      
      if (response.isSuccess && response.data != null) {
        // Cache the order
        _orderCache[orderId] = response.data!;
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        if (response.isNotFound) {
          throw AppException(
            message: 'Order not found',
            code: 'ORDER_NOT_FOUND',
          );
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load order',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load order. Please try again.',
        originalError: e,
      );
    }
  }

  // Create new order from cart
  Future<Order> createOrder(CreateOrderRequest request) async {
    try {
      final response = await _orderApi.createOrder(request);
      
      if (response.isSuccess && response.data != null) {
        // Cache the new order
        _orderCache[response.data!.id] = response.data!;
        
        // Clear orders list cache to force refresh
        _ordersListCache.clear();
        
        // Save recent order ID
        await _saveRecentOrderId(response.data!.id);
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        
        // Handle specific business errors
        if (response.error?.code == 'INSUFFICIENT_STOCK') {
          throw AppException(
            message: 'Some items are out of stock. Please update your cart.',
            code: 'INSUFFICIENT_STOCK',
          );
        }
        
        if (response.error?.code == 'CART_EMPTY') {
          throw AppException(
            message: 'Your cart is empty. Please add items first.',
            code: 'CART_EMPTY',
          );
        }
        
        if (response.error?.code == 'SHOP_CLOSED') {
          throw AppException(
            message: 'Shop is currently closed. Please try again later.',
            code: 'SHOP_CLOSED',
          );
        }
        
        throw AppException(
          message: response.error?.message ?? 'Failed to create order',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to create order. Please try again.',
        originalError: e,
      );
    }
  }

  // Cancel order
  Future<Order> cancelOrder(int orderId, CancelOrderRequest request) async {
    try {
      final response = await _orderApi.cancelOrder(orderId, request);
      
      if (response.isSuccess && response.data != null) {
        // Update cache
        _orderCache[orderId] = response.data!;
        
        // Clear list cache to force refresh
        _ordersListCache.clear();
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        if (response.isNotFound) {
          throw AppException(
            message: 'Order not found',
            code: 'ORDER_NOT_FOUND',
          );
        }
        if (response.error?.code == 'ORDER_CANNOT_BE_CANCELLED') {
          throw AppException(
            message: 'Order cannot be cancelled at this stage',
            code: 'ORDER_CANNOT_BE_CANCELLED',
          );
        }
        
        throw AppException(
          message: response.error?.message ?? 'Failed to cancel order',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to cancel order. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Get shop orders
  Future<OrdersResponse> getShopOrders({
    OrderFilters? filters,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'shop_orders_${filters?.toQueryParams().toString() ?? 'default'}';
      
      if (!forceRefresh && _isListCacheValid(cacheKey)) {
        return _ordersListCache[cacheKey]!;
      }

      final response = await _orderApi.getShopOrders(filters: filters);
      
      if (response.isSuccess && response.data != null) {
        _ordersListCache[cacheKey] = response.data!;
        _lastFetchTime = DateTime.now();
        
        // Cache individual orders
        for (final order in response.data!.orders) {
          _orderCache[order.id] = order;
        }
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load shop orders',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to load shop orders. Please try again.',
        originalError: e,
      );
    }
  }

  // Admin: Update order status
  Future<Order> updateOrderStatus(
    int orderId,
    UpdateOrderStatusRequest request,
  ) async {
    try {
      final response = await _orderApi.updateOrderStatus(orderId, request);
      
      if (response.isSuccess && response.data != null) {
        // Update cache
        _orderCache[orderId] = response.data!;
        
        // Clear list cache to force refresh
        _ordersListCache.clear();
        
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        if (response.isNotFound) {
          throw AppException(
            message: 'Order not found',
            code: 'ORDER_NOT_FOUND',
          );
        }
        
        throw AppException(
          message: response.error?.message ?? 'Failed to update order status',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to update order status. Please try again.',
        originalError: e,
      );
    }
  }

  // Convenience methods for common status updates
  Future<Order> confirmOrder(
    int orderId, {
    String? notes,
    DateTime? estimatedPickupTime,
  }) async {
    return await _orderApi.confirmOrder(
      orderId,
      notes: notes,
      estimatedPickupTime: estimatedPickupTime,
    ).then((response) {
      if (response.isSuccess && response.data != null) {
        _orderCache[orderId] = response.data!;
        _ordersListCache.clear();
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to confirm order',
        );
      }
    });
  }

  Future<Order> markOrderReady(int orderId, {String? notes}) async {
    return await _orderApi.markOrderReady(orderId, notes: notes).then((response) {
      if (response.isSuccess && response.data != null) {
        _orderCache[orderId] = response.data!;
        _ordersListCache.clear();
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to mark order as ready',
        );
      }
    });
  }

  Future<Order> completeOrder(int orderId, {String? notes}) async {
    return await _orderApi.completeOrder(orderId, notes: notes).then((response) {
      if (response.isSuccess && response.data != null) {
        _orderCache[orderId] = response.data!;
        _ordersListCache.clear();
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Failed to complete order',
        );
      }
    });
  }

  // Payment operations
  Future<Map<String, dynamic>?> processPayment(
    int orderId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final response = await _orderApi.processPayment(orderId, paymentData);
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Payment processing failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Payment processing failed. Please try again.',
        originalError: e,
      );
    }
  }

  Future<Order> verifyPayment(int orderId, String transactionId) async {
    try {
      final response = await _orderApi.verifyPayment(orderId, transactionId);
      
      if (response.isSuccess && response.data != null) {
        _orderCache[orderId] = response.data!;
        _ordersListCache.clear();
        return response.data!;
      } else {
        throw AppException(
          message: response.error?.message ?? 'Payment verification failed',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Payment verification failed. Please try again.',
        originalError: e,
      );
    }
  }

  // Analytics and statistics
  Future<OrderStatistics> getOrderStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await _orderApi.getOrderStatistics(
        fromDate: fromDate,
        toDate: toDate,
      );
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to load statistics',
          code: response.error?.code,
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

  // Recent orders for quick access
  Future<List<Order>> getRecentOrders({int limit = 5}) async {
    try {
      final response = await _orderApi.getRecentOrders(limit: limit);
      
      if (response.isSuccess && response.data != null) {
        // Cache recent orders
        for (final order in response.data!) {
          _orderCache[order.id] = order;
        }
        return response.data!;
      } else {
        if (response.isUnauthorized) {
          throw AppException.unauthorized();
        }
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Order receipt and sharing
  Future<Map<String, dynamic>?> generateReceipt(int orderId) async {
    try {
      final response = await _orderApi.generateReceipt(orderId);
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Notifications
  Future<bool> sendOrderNotification(int orderId, String type) async {
    try {
      final response = await _orderApi.sendOrderNotification(orderId, type);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Real-time updates simulation
  Future<Order?> getOrderUpdates(int orderId) async {
    try {
      final response = await _orderApi.getOrderUpdates(orderId);
      
      if (response.isSuccess && response.data != null) {
        _orderCache[orderId] = response.data!;
        return response.data!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cache management
  void clearCache() {
    _orderCache.clear();
    _ordersListCache.clear();
    _lastFetchTime = null;
  }

  void clearOrderCache(int orderId) {
    _orderCache.remove(orderId);
    _ordersListCache.clear(); // Clear list cache as it might contain the order
  }

  // Local storage for recent orders
  Future<void> _saveRecentOrderId(int orderId) async {
    final recentOrders = _preferences.getRecentOrderIds();
    recentOrders.insert(0, orderId);
    
    // Keep only last 10 recent orders
    if (recentOrders.length > 10) {
      recentOrders.removeRange(10, recentOrders.length);
    }
    
    await _preferences.setRecentOrderIds(recentOrders);
  }

  Future<List<int>> getRecentOrderIds() async {
    return _preferences.getRecentOrderIds();
  }

  // Cache validation helpers
  bool _isListCacheValid(String cacheKey) {
    if (!_ordersListCache.containsKey(cacheKey) || _lastFetchTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  // Order search and filtering helpers
  List<Order> filterOrdersLocally(List<Order> orders, OrderFilters filters) {
    return orders.where((order) {
      // Status filter
      if (filters.status != null && order.status != filters.status) {
        return false;
      }
      
      // Payment status filter
      if (filters.paymentStatus != null && order.paymentStatus != filters.paymentStatus) {
        return false;
      }
      
      // Date range filter
      if (filters.fromDate != null && order.createdAt.isBefore(filters.fromDate!)) {
        return false;
      }
      if (filters.toDate != null && order.createdAt.isAfter(filters.toDate!)) {
        return false;
      }
      
      // Search filter
      if (filters.search != null && filters.search!.isNotEmpty) {
        final searchTerm = filters.search!.toLowerCase();
        if (!order.orderNumber.toLowerCase().contains(searchTerm) &&
            !order.customerName.toLowerCase().contains(searchTerm) &&
            !order.customerEmail.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  List<Order> sortOrdersLocally(List<Order> orders, String? sortBy) {
    final sortedOrders = List<Order>.from(orders);
    
    switch (sortBy) {
      case 'newest':
        sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        sortedOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'amount':
        sortedOrders.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'status':
        sortedOrders.sort((a, b) => a.status.value.compareTo(b.status.value));
        break;
      default:
        // Default to newest first
        sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    return sortedOrders;
  }
}
