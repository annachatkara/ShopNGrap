// Cart provider
import 'package:flutter/foundation.dart';
import '../../../core/utils/error_handler.dart';
import '../data/cart_repository.dart';
import '../domain/cart_model.dart';

enum CartState {
  initial,
  loading,
  loaded,
  error,
  empty,
}

class CartProvider with ChangeNotifier {
  final CartRepository _cartRepository = CartRepository();

  // State variables
  CartState _state = CartState.initial;
  Cart? _cart;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isUpdating = false;
  Set<int> _updatingItems = {};

  // Getters
  CartState get state => _state;
  Cart? get cart => _cart;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get hasError => _state == CartState.error;
  bool get isEmpty => _state == CartState.empty || _cart?.isEmpty == true;
  bool get isNotEmpty => _cart?.isNotEmpty == true;
  bool get isOfflineMode => _cartRepository.isOfflineMode;

  // Cart data getters
  List<CartItem> get items => _cart?.items ?? [];
  int get totalItems => _cart?.totalItems ?? 0;
  double get subtotal => _cart?.subtotal ?? 0.0;
  double get deliveryFee => _cart?.deliveryFee ?? 0.0;
  double get tax => _cart?.tax ?? 0.0;
  double get discount => _cart?.discount ?? 0.0;
  double get total => _cart?.total ?? 0.0;
  double get savings => _cart?.totalSavings ?? 0.0;

  // Cart analysis
  bool get hasUnavailableItems => _cart?.hasUnavailableItems ?? false;
  List<CartItem> get availableItems => _cart?.availableItems ?? [];
  List<CartItem> get unavailableItems => _cart?.unavailableItems ?? [];
  Map<String, List<CartItem>> get itemsByShop => _cart?.itemsByShop ?? {};
  int get uniqueShopCount => _cart?.uniqueShopCount ?? 0;

  // Item status checkers
  bool isItemUpdating(int cartItemId) => _updatingItems.contains(cartItemId);

  // Initialize cart
  Future<void> initialize() async {
    await loadCart();
  }

  // Load cart
  Future<void> loadCart() async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      final cart = await _cartRepository.getCart();
      _cart = cart;
      
      if (cart.isEmpty) {
        _setState(CartState.empty);
      } else {
        _setState(CartState.loaded);
      }
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      _setState(CartState.error);
    } finally {
      _setLoading(false);
    }
  }

  // Refresh cart
  Future<void> refreshCart() async {
    await loadCart();
  }

  // Add item to cart
  Future<bool> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    try {
      _setUpdating(true);
      _clearError();

      final updatedCart = await _cartRepository.addToCart(
        productId: productId,
        quantity: quantity,
      );
      
      _cart = updatedCart;
      
      if (updatedCart.isEmpty) {
        _setState(CartState.empty);
      } else {
        _setState(CartState.loaded);
      }
      
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Update cart item quantity
  Future<bool> updateCartItemQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return await removeFromCart(cartItemId);
    }

    try {
      _addUpdatingItem(cartItemId);
      _clearError();

      final updatedCart = await _cartRepository.updateCartItem(
        cartItemId: cartItemId,
        quantity: quantity,
      );
      
      _cart = updatedCart;
      
      if (updatedCart.isEmpty) {
        _setState(CartState.empty);
      } else {
        _setState(CartState.loaded);
      }
      
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _removeUpdatingItem(cartItemId);
    }
  }

  // Increase item quantity
  Future<bool> increaseQuantity(int cartItemId) async {
    final item = _cart?.items.firstWhere((item) => item.id == cartItemId);
    if (item == null || !item.canIncreaseQuantity) return false;
    
    return await updateCartItemQuantity(
      cartItemId: cartItemId,
      quantity: item.quantity + 1,
    );
  }

  // Decrease item quantity
  Future<bool> decreaseQuantity(int cartItemId) async {
    final item = _cart?.items.firstWhere((item) => item.id == cartItemId);
    if (item == null) return false;
    
    if (!item.canDecreaseQuantity) {
      return await removeFromCart(cartItemId);
    }
    
    return await updateCartItemQuantity(
      cartItemId: cartItemId,
      quantity: item.quantity - 1,
    );
  }

  // Remove item from cart
  Future<bool> removeFromCart(int cartItemId) async {
    try {
      _addUpdatingItem(cartItemId);
      _clearError();

      final updatedCart = await _cartRepository.removeFromCart(cartItemId);
      _cart = updatedCart;
      
      if (updatedCart.isEmpty) {
        _setState(CartState.empty);
      } else {
        _setState(CartState.loaded);
      }
      
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _removeUpdatingItem(cartItemId);
    }
  }

  // Clear entire cart
  Future<bool> clearCart() async {
    try {
      _setUpdating(true);
      _clearError();

      final updatedCart = await _cartRepository.clearCart();
      _cart = updatedCart;
      _setState(CartState.empty);
      
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Quick add to cart (for product cards)
  Future<bool> quickAddToCart(int productId, {int quantity = 1}) async {
    try {
      final success = await _cartRepository.quickAddToCart(productId, quantity: quantity);
      if (success) {
        // Refresh cart to update UI
        await loadCart();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Check if product is in cart
  bool isProductInCart(int productId) {
    return _cart?.containsProduct(productId) ?? false;
  }

  // Get product quantity in cart
  int getProductQuantityInCart(int productId) {
    final item = _cart?.getItemByProductId(productId);
    return item?.quantity ?? 0;
  }

  // Sync offline cart
  Future<bool> syncOfflineCart() async {
    if (!isOfflineMode) return true;

    try {
      _setUpdating(true);
      _clearError();

      final syncedCart = await _cartRepository.syncOfflineCart();
      _cart = syncedCart;
      
      if (syncedCart.isEmpty) {
        _setState(CartState.empty);
      } else {
        _setState(CartState.loaded);
      }
      
      return true;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Remove unavailable items
  Future<bool> removeUnavailableItems() async {
    if (_cart == null || !hasUnavailableItems) return true;

    try {
      _setUpdating(true);
      
      final unavailableItems = _cart!.unavailableItems;
      bool allRemoved = true;
      
      for (final item in unavailableItems) {
        final success = await removeFromCart(item.id);
        if (!success) allRemoved = false;
      }
      
      return allRemoved;
    } catch (e) {
      _setError(ErrorHandler.getErrorMessage(e));
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Get cart summary
  CartSummary? get cartSummary {
    if (_cart == null) return null;
    return CartSummary.fromCart(_cart!);
  }

  // Private helper methods
  void _setState(CartState state) {
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

  void _setUpdating(bool updating) {
    if (_isUpdating != updating) {
      _isUpdating = updating;
      notifyListeners();
    }
  }

  void _addUpdatingItem(int cartItemId) {
    _updatingItems.add(cartItemId);
    notifyListeners();
  }

  void _removeUpdatingItem(int cartItemId) {
    _updatingItems.remove(cartItemId);
    notifyListeners();
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

  // Reset cart state
  void reset() {
    _state = CartState.initial;
    _cart = null;
    _errorMessage = null;
    _isLoading = false;
    _isUpdating = false;
    _updatingItems.clear();
    notifyListeners();
  }

  // Clear local data
  Future<void> clearLocalData() async {
    await _cartRepository.clearLocalCart();
    reset();
  }
}
