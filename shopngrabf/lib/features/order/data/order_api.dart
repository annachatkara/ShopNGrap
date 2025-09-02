// Order API implementation
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/order_model.dart';

class OrderApi {
  final ApiClient _apiClient = ApiClient();

  // Customer: Get user's orders
  Future<ApiResponse<OrdersResponse>> getMyOrders({
    OrderFilters? filters,
  }) async {
    final queryParams = filters?.toQueryParams() ?? {'page': 1, 'limit': 10};
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.myOrders,
      queryParams: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final ordersResponse = OrdersResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: ordersResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Customer: Get single order details
  Future<ApiResponse<Order>> getOrder(int orderId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.order(orderId),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final order = Order.fromJson(response.data!['order'] ?? response.data!);
      return ApiResponse.success(data: order, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Customer: Create new order from cart
  Future<ApiResponse<Order>> createOrder(CreateOrderRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.orders,
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final order = Order.fromJson(response.data!['order'] ?? response.data!);
      return ApiResponse.success(data: order, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Customer: Cancel order
  Future<ApiResponse<Order>> cancelOrder(
    int orderId,
    CancelOrderRequest request,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.order(orderId)}/cancel',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final order = Order.fromJson(response.data!['order'] ?? response.data!);
      return ApiResponse.success(data: order, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Get shop's orders
  Future<ApiResponse<OrdersResponse>> getShopOrders({
    OrderFilters? filters,
  }) async {
    final queryParams = filters?.toQueryParams() ?? {'page': 1, 'limit': 10};
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.shopOrders,
      queryParams: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final ordersResponse = OrdersResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: ordersResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Update order status
  Future<ApiResponse<Order>> updateOrderStatus(
    int orderId,
    UpdateOrderStatusRequest request,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${ApiEndpoints.order(orderId)}/status',
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final order = Order.fromJson(response.data!['order'] ?? response.data!);
      return ApiResponse.success(data: order, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Admin: Confirm order
  Future<ApiResponse<Order>> confirmOrder(
    int orderId, {
    String? notes,
    DateTime? estimatedPickupTime,
  }) async {
    final request = UpdateOrderStatusRequest(
      status: OrderStatus.confirmed,
      notes: notes,
      estimatedPickupTime: estimatedPickupTime,
    );

    return await updateOrderStatus(orderId, request);
  }

  // Admin: Mark order as ready for pickup
  Future<ApiResponse<Order>> markOrderReady(
    int orderId, {
    String? notes,
  }) async {
    final request = UpdateOrderStatusRequest(
      status: OrderStatus.ready,
      notes: notes,
    );

    return await updateOrderStatus(orderId, request);
  }

  // Admin: Complete order (customer picked up)
  Future<ApiResponse<Order>> completeOrder(
    int orderId, {
    String? notes,
  }) async {
    final request = UpdateOrderStatusRequest(
      status: OrderStatus.completed,
      notes: notes,
      actualPickupTime: DateTime.now(),
    );

    return await updateOrderStatus(orderId, request);
  }

  // Payment: Process payment
  Future<ApiResponse<Map<String, dynamic>>> processPayment(
    int orderId,
    Map<String, dynamic> paymentData,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.order(orderId)}/payment',
      body: paymentData,
      requiresAuth: true,
    );

    return response;
  }

  // Payment: Verify payment
  Future<ApiResponse<Order>> verifyPayment(
    int orderId,
    String transactionId,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.order(orderId)}/payment/verify',
      body: {'transactionId': transactionId},
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final order = Order.fromJson(response.data!['order'] ?? response.data!);
      return ApiResponse.success(data: order, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get order statistics (for admin dashboard)
  Future<ApiResponse<OrderStatistics>> getOrderStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.orders}/statistics',
      queryParams: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final stats = OrderStatistics.fromJson(response.data!['statistics'] ?? response.data!);
      return ApiResponse.success(data: stats, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get recent orders (for quick access)
  Future<ApiResponse<List<Order>>> getRecentOrders({int limit = 5}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.orders}/recent',
      queryParams: {'limit': limit},
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final ordersList = response.data!['orders'] as List<dynamic>? ?? [];
      final orders = ordersList.map((order) => Order.fromJson(order)).toList();
      return ApiResponse.success(data: orders, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Generate order receipt
  Future<ApiResponse<Map<String, dynamic>>> generateReceipt(int orderId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.order(orderId)}/receipt',
      requiresAuth: true,
    );

    return response;
  }

  // Send order notification
  Future<ApiResponse<Map<String, dynamic>>> sendOrderNotification(
    int orderId,
    String type, // 'sms', 'email', 'push'
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.order(orderId)}/notify',
      body: {'type': type},
      requiresAuth: true,
    );

    return response;
  }

  // Superuser: Get all orders across all shops
  Future<ApiResponse<OrdersResponse>> getAllOrders({
    OrderFilters? filters,
  }) async {
    final queryParams = filters?.toQueryParams() ?? {'page': 1, 'limit': 10};
    
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.orders}/all',
      queryParams: queryParams,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final ordersResponse = OrdersResponse.fromJson(response.data!);
      return ApiResponse.success(
        data: ordersResponse,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Real-time order updates (WebSocket simulation)
  Future<ApiResponse<Order>> getOrderUpdates(int orderId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.order(orderId)}/updates',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final order = Order.fromJson(response.data!['order'] ?? response.data!);
      return ApiResponse.success(data: order, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Bulk operations for admin efficiency
  Future<ApiResponse<Map<String, dynamic>>> bulkUpdateOrderStatus(
    List<int> orderIds,
    OrderStatus status, {
    String? notes,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.orders}/bulk-update',
      body: {
        'orderIds': orderIds,
        'status': status.value,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      requiresAuth: true,
    );

    return response;
  }
}
