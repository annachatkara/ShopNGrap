// Cart repository implementation
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/utils/error_handler.dart';
import '../domain/cart_model.dart';
import 'cart_api.dart';

class CartRepository {
  final CartApi _cartApi = CartApi();
  final SecureStorage _secureStorage = SecureStorage();
  final Preferences _preferences = Preferences();

  // Local cart for offline support
  Cart? _localCart;
  bool _isOfflineMode = false;

  // Get cart (with offline support)
  Future<Cart> getCart() async {
    try {
      // Try to get from server first
      final response = await _cartApi.getCart();
      
      if (response.isSuccess && response.data != null) {
        _localCart = response.data!;
        _isOfflineMode = false;
        
        // Save to local storage
        await _saveCartToLocal(response.data!);
        
        return response.data!;
      } else {
        // If server fails, try local storage
        return await _getCartFromLocal();
      }
    } catch (e) {
      // If network error, use local cart
      if (ErrorHandler.isNetworkError(e)) {
        return await _getCartFromLocal();
      }
      
      if (ErrorHandler.isUnauthorized(e)) {
        throw AppException.unauthorized();
      }
      
      throw AppException(
        message: 'Failed to load cart. Please try again.',
        originalError: e,
      );
    }
  }

  // Add item to cart
  Future<Cart> addToCart({
    required int productId,
    required int quantity,
  }) async {
    try {
      final request = AddToCartRequest(productId: productId, quantity: quantity);
      
      if (_isOfflineMode) {
        return await _addToCartOffline(request);
      }

      final response = await _cartApi.addToCart(request);
      
      if (response.isSuccess && response.data != null) {
        // Refresh cart to get updated totals
        return await getCart();
      } else {
        if (ErrorHandler.isUnauthorized(e)) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to add item to cart',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        return await _addToCartOffline(AddToCartRequest(
          productId: productId,
          quantity: quantity,
        ));
      }
      
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to add item to cart. Please try again.',
        originalError: e,
      );
    }
  }

  // Update cart item
  Future<Cart> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      final request = UpdateCartItemRequest(quantity: quantity);
      
      if (_isOfflineMode) {
        return await _updateCartItemOffline(cartItemId, quantity);
      }

      final response = await _cartApi.updateCartItem(cartItemId, request);
      
      if (response.isSuccess && response.data != null) {
        // Refresh cart to get updated totals
        return await getCart();
      } else {
        if (ErrorHandler.isUnauthorized(e)) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to update cart item',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        return await _updateCartItemOffline(cartItemId, quantity);
      }
      
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to update cart item. Please try again.',
        originalError: e,
      );
    }
  }

  // Remove item from cart
  Future<Cart> removeFromCart(int cartItemId) async {
    try {
      if (_isOfflineMode) {
        return await _removeFromCartOffline(cartItemId);
      }

      final response = await _cartApi.removeFromCart(cartItemId);
      
      if (response.isSuccess) {
        // Refresh cart to get updated totals
        return await getCart();
      } else {
        if (ErrorHandler.isUnauthorized(e)) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to remove item from cart',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        return await _removeFromCartOffline(cartItemId);
      }
      
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to remove item from cart. Please try again.',
        originalError: e,
      );
    }
  }

  // Clear cart
  Future<Cart> clearCart() async {
    try {
      if (_isOfflineMode) {
        return await _clearCartOffline();
      }

      final response = await _cartApi.clearCart();
      
      if (response.isSuccess) {
        _localCart = const Cart(items: [], totalItems: 0, subtotal: 0.0, total: 0.0);
        await _saveCartToLocal(_localCart!);
        return _localCart!;
      } else {
        if (ErrorHandler.isUnauthorized(e)) {
          throw AppException.unauthorized();
        }
        throw AppException(
          message: response.error?.message ?? 'Failed to clear cart',
          code: response.error?.code,
        );
      }
    } catch (e) {
      if (ErrorHandler.isNetworkError(e)) {
        return await _clearCartOffline();
      }
      
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to clear cart. Please try again.',
        originalError: e,
      );
    }
  }

  // Quick add to cart (simplified)
  Future<bool> quickAddToCart(int productId, {int quantity = 1}) async {
    try {
      final response = await _cartApi.quickAddToCart(productId, quantity);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  // Get cart item count (for badge)
  Future<int> getCartItemCount() async {
    try {
      final cart = await getCart();
      return cart.totalItems;
    } catch (e) {
      return 0;
    }
  }

  // Check if product is in cart
  Future<bool> isProductInCart(int productId) async {
    try {
      final cart = await getCart();
      return cart.containsProduct(productId);
    } catch (e) {
      return false;
    }
  }

  // Get product quantity in cart
  Future<int> getProductQuantityInCart(int productId) async {
    try {
      final cart = await getCart();
      final item = cart.getItemByProductId(productId);
      return item?.quantity ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Sync offline cart with server
  Future<Cart> syncOfflineCart() async {
    if (_localCart == null || !_isOfflineMode) {
      return await getCart();
    }

    try {
      final cartItems = _localCart!.items.map((item) => item.toJson()).toList();
      final response = await _cartApi.syncCart(cartItems);
      
      if (response.isSuccess && response.data != null) {
        _localCart = response.data!;
        _isOfflineMode = false;
        await _saveCartToLocal(_localCart!);
        return _localCart!;
      } else {
        throw AppException(
          message: 'Failed to sync cart with server',
          code: response.error?.code,
        );
      }
    } catch (e) {
      throw AppException(
        message: 'Failed to sync cart. Please try again.',
        originalError: e,
      );
    }
  }

  // Private helper methods for offline support
  Future<Cart> _getCartFromLocal() async {
    try {
      final cartData = await _secureStorage.getCartData();
      if (cartData != null && cartData.isNotEmpty) {
        final items = cartData.map((item) => CartItem.fromJson(item)).toList();
        _localCart = _calculateCartTotals(items);
        _isOfflineMode = true;
        return _localCart!;
      }
      
      _localCart = const Cart(items: [], totalItems: 0, subtotal: 0.0, total: 0.0);
      return _localCart!;
    } catch (e) {
      _localCart = const Cart(items: [], totalItems: 0, subtotal: 0.0, total: 0.0);
      return _localCart!;
    }
  }

  Future<void> _saveCartToLocal(Cart cart) async {
    try {
      final cartData = cart.items.map((item) => item.toJson()).toList();
      await _secureStorage.saveCartData(cartData);
    } catch (e) {
      // Silently handle save errors
    }
  }

  Future<Cart> _addToCartOffline(AddToCartRequest request) async {
    final cart = _localCart ?? await _getCartFromLocal();
    final items = List<CartItem>.from(cart.items);
    
    // Check if item already exists
    final existingIndex = items.indexWhere((item) => item.productId == request.productId);
    
    if (existingIndex != -1) {
      // Update quantity
      final existingItem = items[existingIndex];
      final newQuantity = existingItem.quantity + request.quantity;
      items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
    } else {
      // Add new item (create placeholder item)
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        productId: request.productId,
        productName: 'Product ${request.productId}', // Placeholder
        productDescription: 'Loading...',
        productPrice: 0.0, // Will be updated when syncing
        quantity: request.quantity,
        availableStock: 999, // Placeholder
        isActive: true,
        shopId: 0,
        shopName: 'Loading...',
        categoryId: 0,
        categoryName: 'Loading...',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      items.add(newItem);
    }
    
    _localCart = _calculateCartTotals(items);
    await _saveCartToLocal(_localCart!);
    return _localCart!;
  }

  Future<Cart> _updateCartItemOffline(int cartItemId, int quantity) async {
    final cart = _localCart ?? await _getCartFromLocal();
    final items = List<CartItem>.from(cart.items);
    
    final index = items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      items[index] = items[index].copyWith(quantity: quantity);
    }
    
    _localCart = _calculateCartTotals(items);
    await _saveCartToLocal(_localCart!);
    return _localCart!;
  }

  Future<Cart> _removeFromCartOffline(int cartItemId) async {
    final cart = _localCart ?? await _getCartFromLocal();
    final items = List<CartItem>.from(cart.items);
    
    items.removeWhere((item) => item.id == cartItemId);
    
    _localCart = _calculateCartTotals(items);
    await _saveCartToLocal(_localCart!);
    return _localCart!;
  }

  Future<Cart> _clearCartOffline() async {
    _localCart = const Cart(items: [], totalItems: 0, subtotal: 0.0, total: 0.0);
    await _saveCartToLocal(_localCart!);
    return _localCart!;
  }

  Cart _calculateCartTotals(List<CartItem> items) {
    final totalItems = items.fold(0, (sum, item) => sum + item.quantity);
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    // Calculate delivery fee (free over ₹500)
    final deliveryFee = subtotal >= 500 ? 0.0 : 50.0;
    
    // Calculate tax (18% GST)
    final tax = subtotal * 0.18;
    
    // No discount in offline mode
    const discount = 0.0;
    
    final total = subtotal + deliveryFee + tax - discount;
    
    return Cart(
      items: items,
      totalItems: totalItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      discount: discount,
      total: total,
      lastUpdated: DateTime.now(),
    );
  }

  // Clear local cart data
  Future<void> clearLocalCart() async {
    await _secureStorage.deleteCartData();
    _localCart = null;
  }

  // Get offline status
  bool get isOfflineMode => _isOfflineMode;
  
  // Force offline mode (for testing)
  void setOfflineMode(bool offline) {
    _isOfflineMode = offline;
  }
}
