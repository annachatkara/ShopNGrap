// Cart page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../domain/cart_model.dart';
import 'cart_provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  static const routeName = '/cart';

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isNotEmpty) {
                return PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, size: 20),
                          SizedBox(width: 8),
                          Text('Clear Cart'),
                        ],
                      ),
                    ),
                    if (cartProvider.hasUnavailableItems)
                      const PopupMenuItem(
                        value: 'remove_unavailable',
                        child: Row(
                          children: [
                            Icon(Icons.remove_shopping_cart, size: 20),
                            SizedBox(width: 8),
                            Text('Remove Unavailable'),
                          ],
                        ),
                      ),
                    if (cartProvider.isOfflineMode)
                      const PopupMenuItem(
                        value: 'sync',
                        child: Row(
                          children: [
                            Icon(Icons.sync, size: 20),
                            SizedBox(width: 8),
                            Text('Sync Cart'),
                          ],
                        ),
                      ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (cartProvider.hasError) {
            return _buildErrorView(cartProvider);
          }

          if (cartProvider.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add some products to get started',
              actionText: 'Start Shopping',
            );
          }

          return _buildCartView(cartProvider);
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty || cartProvider.hasError) {
            return const SizedBox.shrink();
          }
          
          return _buildBottomBar(cartProvider);
        },
      ),
    );
  }

  Widget _buildErrorView(CartProvider cartProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            cartProvider.errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => cartProvider.refreshCart(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartView(CartProvider cartProvider) {
    return RefreshIndicator(
      onRefresh: () => cartProvider.refreshCart(),
      child: Column(
        children: [
          // Offline indicator
          if (cartProvider.isOfflineMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You\'re offline. Changes will sync when connected.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: () => cartProvider.syncOfflineCart(),
                    child: const Text('Sync Now'),
                  ),
                ],
              ),
            ),

          // Unavailable items warning
          if (cartProvider.hasUnavailableItems)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Some items are unavailable or out of stock',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () => cartProvider.removeUnavailableItems(),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ),

          // Cart items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getItemCount(cartProvider),
              itemBuilder: (context, index) => _buildItem(context, cartProvider, index),
            ),
          ),
        ],
      ),
    );
  }

  int _getItemCount(CartProvider cartProvider) {
    int count = 0;
    
    // Add available items
    if (cartProvider.availableItems.isNotEmpty) {
      count += 1; // Header
      count += cartProvider.availableItems.length; // Items
    }
    
    // Add unavailable items
    if (cartProvider.unavailableItems.isNotEmpty) {
      count += 1; // Header
      count += cartProvider.unavailableItems.length; // Items
    }
    
    return count;
  }

  Widget _buildItem(BuildContext context, CartProvider cartProvider, int index) {
    int currentIndex = 0;
    
    // Available items section
    if (cartProvider.availableItems.isNotEmpty) {
      if (index == currentIndex) {
        return _buildSectionHeader('Available Items (${cartProvider.availableItems.length})');
      }
      currentIndex++;
      
      if (index < currentIndex + cartProvider.availableItems.length) {
        final itemIndex = index - currentIndex;
        return _buildCartItemCard(cartProvider.availableItems[itemIndex], cartProvider);
      }
      currentIndex += cartProvider.availableItems.length;
    }
    
    // Unavailable items section
    if (cartProvider.unavailableItems.isNotEmpty) {
      if (index == currentIndex) {
        return _buildSectionHeader(
          'Unavailable Items (${cartProvider.unavailableItems.length})',
          color: Colors.red,
        );
      }
      currentIndex++;
      
      if (index < currentIndex + cartProvider.unavailableItems.length) {
        final itemIndex = index - currentIndex;
        return _buildCartItemCard(
          cartProvider.unavailableItems[itemIndex],
          cartProvider,
          isUnavailable: true,
        );
      }
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            color: color ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(
    CartItem item,
    CartProvider cartProvider, {
    bool isUnavailable = false,
  }) {
    final isUpdating = cartProvider.isItemUpdating(item.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: item.productImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.productImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported);
                            },
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                
                const SizedBox(width: 16),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        item.productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isUnavailable ? TextDecoration.lineThrough : null,
                          color: isUnavailable ? Colors.grey : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Shop Name
                      Text(
                        'Sold by ${item.shopName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Price and Total
                      Row(
                        children: [
                          Text(
                            Formatters.currency(item.productPrice),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '× ${item.quantity}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            Formatters.currency(item.totalPrice),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      // Stock warning
                      if (item.stockWarning.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            item.stockWarning,
                            style: TextStyle(
                              color: item.stockWarningColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Remove Button
                IconButton(
                  onPressed: isUpdating ? null : () {
                    _showRemoveDialog(item, cartProvider);
                  },
                  icon: isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            
            if (!isUnavailable) ...[
              const SizedBox(height: 16),
              
              // Quantity Controls
              Row(
                children: [
                  const Text('Quantity:'),
                  const Spacer(),
                  _buildQuantityControls(item, cartProvider, isUpdating),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(CartItem item, CartProvider cartProvider, bool isUpdating) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease Button
          IconButton(
            onPressed: isUpdating || !item.canDecreaseQuantity
                ? null
                : () => cartProvider.decreaseQuantity(item.id),
            icon: const Icon(Icons.remove, size: 18),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          
          // Quantity Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '${item.quantity}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          
          // Increase Button
          IconButton(
            onPressed: isUpdating || !item.canIncreaseQuantity
                ? null
                : () => cartProvider.increaseQuantity(item.id),
            icon: const Icon(Icons.add, size: 18),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cart Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', cartProvider.subtotal),
                  if (cartProvider.deliveryFee > 0)
                    _buildSummaryRow('Delivery Fee', cartProvider.deliveryFee),
                  if (cartProvider.tax > 0)
                    _buildSummaryRow('Tax', cartProvider.tax),
                  if (cartProvider.discount > 0)
                    _buildSummaryRow('Discount', -cartProvider.discount, isDiscount: true),
                  const Divider(),
                  _buildSummaryRow(
                    'Total',
                    cartProvider.total,
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: cartProvider.availableItems.isNotEmpty && !cartProvider.isUpdating
                    ? _proceedToCheckout
                    : null,
                child: cartProvider.isUpdating
                    ? const LoadingIndicator(size: 20)
                    : Text(
                        'Proceed to Checkout (${cartProvider.availableItems.length} items)',
                      ),
              ),
            ),
            
            // Continue Shopping
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            isDiscount ? '-${Formatters.currency(amount)}' : Formatters.currency(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : (isTotal ? Theme.of(context).primaryColor : null),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    final cartProvider = context.read<CartProvider>();
    
    switch (action) {
      case 'clear':
        _showClearCartDialog(cartProvider);
        break;
      case 'remove_unavailable':
        cartProvider.removeUnavailableItems();
        break;
      case 'sync':
        cartProvider.syncOfflineCart();
        break;
    }
  }

  void _showRemoveDialog(CartItem item, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.productName}" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              cartProvider.removeFromCart(item.id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              cartProvider.clearCart();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    // TODO: Navigate to checkout page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proceeding to checkout...')),
    );
  }
}
