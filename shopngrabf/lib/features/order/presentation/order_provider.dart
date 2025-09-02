// Order provider
import 'package:flutter/foundation.dart';
import '../../../core/utils/error_handler.dart';
import '../data/order_repository.dart';
import '../domain/order_model.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../auth/presentation/auth_provider.dart';

enum OrderState {
  initial,
  loading,
  loaded,
  error,
  empty,
}

class OrderProvider with ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();

  // State variables
  OrderState _state = OrderState.initial;
  List<Order> _orders = [];
  Order? _selectedOrder;
  OrdersResponse? _ordersResponse;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isCreatingOrder = false;
  bool _isUpdatingStatus = false;

  // Filtering and pagination
  OrderFilters _filters = const OrderFilters();
  bool _hasReachedMax = false;

  // Admin state
  List<Order> _shopOrders = [];
  OrderStatistics? _orderStatistics;
  bool _isLoadingStatistics = false;

  // Recent orders cache
  List<Order> _recentOrders = [];

  // Real-time updates
  final Map<int, Order> _updatedOrders = {};

  // Getters
  OrderState get state => _state;
  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  OrdersResponse? get ordersResponse => _ordersResponse;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isCreatingOrder => _isCreatingOrder;
  bool get isUpdatingStatus => _isUpdatingStatus;
  bool get hasError => _state == OrderState.error;
  bool get isEmpty => _state == OrderState.empty;
  bool get hasOrders => _orders.isNotEmpty;

  // Filtering getters
  OrderFilters get filters => _filters;
  bool get hasActiveFilters => _filters.hasActiveFilters;
  bool get hasReachedMax => _hasReachedMax;
  int get totalOrders => _ordersResponse?.pagination.total ?? 0;

  // Admin getters
  List<Order> get shopOrders => _shopOrders;
  OrderStatistics? get orderStatistics => _orderStatistics;
  bool get isLoadingStatistics => _isLoadingStatistics;

  // Recent orders
  List<Order> get recentOrders => _recentOrders;

  // Order status helpers
  List<Order> get pendingOrders => _orders.where((o) => o.status == OrderStatus.pending).toList();
  List<Order> get activeOrders => _orders.where((o) => o.isActive).toList();
  List<Order> get completedOrders => _orders.where((o) => o.isCompleted).toList();
  List<Order> get cancelledOrders => _orders.where((o) => o.isCancelled).toList();

  // Initialize
  Future<void> initialize() async {
    await loadOrders();
    await loadRecentOrders();
  }

  // Load user's orders
  Future<void> loadOrders({bool forceRefresh = false}) async {
    if (_isLoading) return;

    if (forceRefresh) {
      _orders.clear();
      _ordersResponse = null;
      _hasReachedMax = false;
      _filters = _filters.copyWith(page: 1);
    }

    try {
      _setLoading(true);
      _clearError();

      final response = await _orderRepository.getMyOrders(
        filters: _filters,
        forceRefresh: forceRefresh,
      );

      _ordersResponse = response;
      _orders = response.orders;
      _hasReachedMax = !response.pagination.hasNextPage;

      if (_orders.isEmpty) {
        _setState(OrderState.empty);
      } else {
        _setState(OrderState.loaded);
      }
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(OrderState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Load more orders (pagination)
  Future<void> loadMoreOrders() async {
    if (_isLoading || _hasReachedMax || _ordersResponse == null) return;

    try {
      _setLoading(true);

      final nextFilters = _filters.copyWith(page: _ordersResponse!.pagination.nextPage);
      final response = await _orderRepository.getMyOrders(filters: nextFilters);

      _orders.addAll(response.orders);
      _ordersResponse = response;
      _hasReachedMax = !response.pagination.hasNextPage;
      _filters = nextFilters;

      notifyListeners();
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // Get single order
  Future<bool> getOrder(int orderId, {bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final order = await _orderRepository.getOrder(orderId, forceRefresh: forceRefresh);
      _selectedOrder = order;

      // Update order in list if it exists
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = order;
      }

      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create order from cart
  Future<Order?> createOrder({
    required List<int> cartItemIds,
    required int pickupAddressId,
    required PaymentMethod paymentMethod,
    String? notes,
    DateTime? preferredPickupTime,
  }) async {
    try {
      _setCreatingOrder(true);
      _clearError();

      final request = CreateOrderRequest(
        cartItemIds: cartItemIds,
        pickupAddressId: pickupAddressId,
        paymentMethod: paymentMethod,
        notes: notes,
        preferredPickupTime: preferredPickupTime,
      );

      final order = await _orderRepository.createOrder(request);

      // Add to orders list
      _orders.insert(0, order);
      _selectedOrder = order;

      // Update state
      if (_state == OrderState.empty) {
        _setState(OrderState.loaded);
      }

      notifyListeners();
      return order;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return null;
    } finally {
      _setCreatingOrder(false);
    }
  }

  // Cancel order
  Future<bool> cancelOrder(int orderId, String reason, {bool refundRequested = false}) async {
    try {
      _setUpdatingStatus(true);
      _clearError();

      final request = CancelOrderRequest(
        reason: reason,
        refundRequested: refundRequested,
      );

      final updatedOrder = await _orderRepository.cancelOrder(orderId, request);

      // Update order in list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }

      // Update selected order
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setUpdatingStatus(false);
    }
  }

  // Apply filters
  Future<void> applyFilters(OrderFilters newFilters) async {
    _filters = newFilters.copyWith(page: 1);
    await loadOrders(forceRefresh: true);
  }

  // Clear filters
  Future<void> clearFilters() async {
    _filters = const OrderFilters();
    await loadOrders(forceRefresh: true);
  }

  // Filter by status
  Future<void> filterByStatus(OrderStatus? status) async {
    _filters = _filters.copyWith(status: status, page: 1);
    await loadOrders(forceRefresh: true);
  }

  // Search orders
  Future<void> searchOrders(String query) async {
    _filters = _filters.copyWith(search: query, page: 1);
    await loadOrders(forceRefresh: true);
  }

  // Sort orders
  Future<void> sortOrders(String sortBy) async {
    _filters = _filters.copyWith(sortBy: sortBy, page: 1);
    await loadOrders(forceRefresh: true);
  }

  // Admin: Load shop orders
  Future<void> loadShopOrders({bool forceRefresh = false}) async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      final response = await _orderRepository.getShopOrders(
        filters: _filters,
        forceRefresh: forceRefresh,
      );

      _shopOrders = response.orders;
      _ordersResponse = response;

      if (_shopOrders.isEmpty) {
        _setState(OrderState.empty);
      } else {
        _setState(OrderState.loaded);
      }
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to view shop orders');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      _setState(OrderState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Admin: Update order status
  Future<bool> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String? notes,
    DateTime? estimatedPickupTime,
    DateTime? actualPickupTime,
  }) async {
    try {
      _setUpdatingStatus(true);
      _clearError();

      final request = UpdateOrderStatusRequest(
        status: status,
        notes: notes,
        estimatedPickupTime: estimatedPickupTime,
        actualPickupTime: actualPickupTime,
      );

      final updatedOrder = await _orderRepository.updateOrderStatus(orderId, request);

      // Update in shop orders
      final shopIndex = _shopOrders.indexWhere((o) => o.id == orderId);
      if (shopIndex != -1) {
        _shopOrders[shopIndex] = updatedOrder;
      }

      // Update in customer orders
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }

      // Update selected order
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (ErrorHandler.isUnauthorized(e)) {
        _setError('Please login as admin to update order status');
      } else {
        _setError(ErrorHandler.getErrorMessage(e));
      }
      return false;
    } finally {
      _setUpdatingStatus(false);
    }
  }

  // Admin: Quick status updates
  Future<bool> confirmOrder(int orderId, {String? notes, DateTime? estimatedPickupTime}) async {
    try {
      final updatedOrder = await _orderRepository.confirmOrder(
        orderId,
        notes: notes,
        estimatedPickupTime: estimatedPickupTime,
      );
      
      _updateOrderInLists(updatedOrder);
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  Future<bool> markOrderReady(int orderId, {String? notes}) async {
    try {
      final updatedOrder = await _orderRepository.markOrderReady(orderId, notes: notes);
      _updateOrderInLists(updatedOrder);
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  Future<bool> completeOrder(int orderId, {String? notes}) async {
    try {
      final updatedOrder = await _orderRepository.completeOrder(orderId, notes: notes);
      _updateOrderInLists(updatedOrder);
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  // Load statistics
  Future<void> loadOrderStatistics({DateTime? fromDate, DateTime? toDate}) async {
    try {
      _setLoadingStatistics(true);
      _clearError();

      final stats = await _orderRepository.getOrderStatistics(
        fromDate: fromDate,
        toDate: toDate,
      );

      _orderStatistics = stats;
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

  // Load recent orders
  Future<void> loadRecentOrders() async {
    try {
      final recent = await _orderRepository.getRecentOrders(limit: 5);
      _recentOrders = recent;
      notifyListeners();
    } catch (e) {
      // Silently handle error for recent orders
    }
  }

  // Payment operations
  Future<Map<String, dynamic>?> processPayment(
    int orderId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      _setUpdatingStatus(true);
      _clearError();

      final result = await _orderRepository.processPayment(orderId, paymentData);
      return result;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return null;
    } finally {
      _setUpdatingStatus(false);
    }
  }

  Future<bool> verifyPayment(int orderId, String transactionId) async {
    try {
      _setUpdatingStatus(true);
      
      final updatedOrder = await _orderRepository.verifyPayment(orderId, transactionId);
      _updateOrderInLists(updatedOrder);
      
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setUpdatingStatus(false);
    }
  }

  // Notifications
  Future<bool> sendOrderNotification(int orderId, String type) async {
    try {
      return await _orderRepository.sendOrderNotification(orderId, type);
    } catch (e) {
      return false;
    }
  }

  // Real-time order updates
  Future<void> refreshOrderUpdates(int orderId) async {
    try {
      final updatedOrder = await _orderRepository.getOrderUpdates(orderId);
      if (updatedOrder != null) {
        _updateOrderInLists(updatedOrder);
      }
    } catch (e) {
      // Silently handle real-time update errors
    }
  }

  // Start periodic updates for active orders
  void startOrderUpdates() {
    // In a real app, you might use WebSockets or periodic polling
    // For now, we'll implement periodic refresh for active orders
    Timer.periodic(const Duration(seconds: 30), (timer) {
      final activeOrderIds = _orders
          .where((order) => order.isActive)
          .map((order) => order.id)
          .toList();

      for (final orderId in activeOrderIds) {
        refreshOrderUpdates(orderId);
      }
    });
  }

  // Helper methods for order management
  Order? findOrderById(int orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return _shopOrders.firstWhere((order) => order.id == orderId);
    }
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<Order> getOrdersByDateRange(DateTime from, DateTime to) {
    return _orders.where((order) {
      return order.createdAt.isAfter(from) && order.createdAt.isBefore(to);
    }).toList();
  }

  double getTotalOrderValue() {
    return _orders.fold(0.0, (sum, order) => sum + order.total);
  }

  // Refresh all data
  Future<void> refresh() async {
    await loadOrders(forceRefresh: true);
    await loadRecentOrders();
  }

  // Clear cache
  void clearCache() {
    _orderRepository.clearCache();
  }

  // Private helper methods
  void _setState(OrderState state) {
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

  void _setCreatingOrder(bool creating) {
    if (_isCreatingOrder != creating) {
      _isCreatingOrder = creating;
      notifyListeners();
    }
  }

  void _setUpdatingStatus(bool updating) {
    if (_isUpdatingStatus != updating) {
      _isUpdatingStatus = updating;
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

  void _updateOrderInLists(Order updatedOrder) {
    // Update in shop orders
    final shopIndex = _shopOrders.indexWhere((o) => o.id == updatedOrder.id);
    if (shopIndex != -1) {
      _shopOrders[shopIndex] = updatedOrder;
    }

    // Update in customer orders
    final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
    }

    // Update selected order
    if (_selectedOrder?.id == updatedOrder.id) {
      _selectedOrder = updatedOrder;
    }

    notifyListeners();
  }

  // Reset all state
  void reset() {
    _state = OrderState.initial;
    _orders.clear();
    _shopOrders.clear();
    _selectedOrder = null;
    _ordersResponse = null;
    _orderStatistics = null;
    _recentOrders.clear();
    _filters = const OrderFilters();
    _hasReachedMax = false;
    _errorMessage = null;
    _isLoading = false;
    _isCreatingOrder = false;
    _isUpdatingStatus = false;
    _isLoadingStatistics = false;
    notifyListeners();
  }
}
