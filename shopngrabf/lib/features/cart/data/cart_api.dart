// Cart API implementation
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/cart_model.dart';

class CartApi {
  final ApiClient _apiClient = ApiClient();

  // Get user's cart
  Future<ApiResponse<Cart>> getCart() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.cart,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final cart = Cart.fromJson(response.data!['cart'] ?? response.data!);
      return ApiResponse.success(data: cart, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Add item to cart
  Future<ApiResponse<CartItem>> addToCart(AddToCartRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.cart,
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final cartItem = CartItem.fromJson(response.data!['cartItem'] ?? response.data!);
      return ApiResponse.success(data: cartItem, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Update cart item quantity
  Future<ApiResponse<CartItem>> updateCartItem(
    int cartItemId,
    UpdateCartItemRequest request,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.cartItem(cartItemId),
      body: request.toJson(),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final cartItem = CartItem.fromJson(response.data!['cartItem'] ?? response.data!);
      return ApiResponse.success(data: cartItem, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Remove item from cart
  Future<ApiResponse<Map<String, dynamic>>> removeFromCart(int cartItemId) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.cartItem(cartItemId),
      requiresAuth: true,
    );
  }

  // Clear entire cart
  Future<ApiResponse<Map<String, dynamic>>> clearCart() async {
    return await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.cart,
      requiresAuth: true,
    );
  }

  // Quick add to cart (product ID and quantity only)
  Future<ApiResponse<Map<String, dynamic>>> quickAddToCart(
    int productId,
    int quantity,
  ) async {
    final request = AddToCartRequest(productId: productId, quantity: quantity);
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.cart,
      body: request.toJson(),
      requiresAuth: true,
    );

    return response;
  }

  // Sync cart items (for offline support)
  Future<ApiResponse<Cart>> syncCart(List<Map<String, dynamic>> cartItems) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiEndpoints.cart}/sync',
      body: {'items': cartItems},
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final cart = Cart.fromJson(response.data!['cart'] ?? response.data!);
      return ApiResponse.success(data: cart, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }

  // Get cart summary (totals only)
  Future<ApiResponse<CartSummary>> getCartSummary() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.cart}/summary',
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final summary = CartSummary(
        totalItems: response.data!['totalItems'] ?? 0,
        subtotal: (response.data!['subtotal'] ?? 0).toDouble(),
        deliveryFee: (response.data!['deliveryFee'] ?? 0).toDouble(),
        tax: (response.data!['tax'] ?? 0).toDouble(),
        discount: (response.data!['discount'] ?? 0).toDouble(),
        total: (response.data!['total'] ?? 0).toDouble(),
        savings: (response.data!['savings'] ?? 0).toDouble(),
      );
      return ApiResponse.success(data: summary, statusCode: response.statusCode);
    } else {
      return ApiResponse.failure(
        error: response.error!,
        statusCode: response.statusCode,
      );
    }
  }
}
