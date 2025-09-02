import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'cart_provider.dart';

class AddToCartWidget extends StatefulWidget {
  const AddToCartWidget({
    super.key,
    required this.productId,
    required this.availableStock,
    this.onAdded,
    this.style = AddToCartStyle.button,
  });

  final int productId;
  final int availableStock;
  final VoidCallback? onAdded;
  final AddToCartStyle style;

  @override
  State<AddToCartWidget> createState() => _AddToCartWidgetState();
}

class _AddToCartWidgetState extends State<AddToCartWidget> {
  bool _isAdding = false;

  Future<void> _addToCart() async {
    if (_isAdding || widget.availableStock <= 0) return;

    setState(() {
      _isAdding = true;
    });

    try {
      final cartProvider = context.read<CartProvider>();
      final success = await cartProvider.addToCart(productId: widget.productId);
      
      if (success && mounted) {
        widget.onAdded?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cartProvider.errorMessage ?? 'Failed to add to cart'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final isInCart = cartProvider.isProductInCart(widget.productId);
        final quantityInCart = cartProvider.getProductQuantityInCart(widget.productId);
        
        switch (widget.style) {
          case AddToCartStyle.button:
            return _buildButton(isInCart, quantityInCart);
          case AddToCartStyle.floating:
            return _buildFloatingButton(isInCart, quantityInCart);
          case AddToCartStyle.compact:
            return _buildCompactButton(isInCart, quantityInCart);
        }
      },
    );
  }

  Widget _buildButton(bool isInCart, int quantityInCart) {
    if (widget.availableStock <= 0) {
      return CustomButton(
        onPressed: null,
        backgroundColor: Colors.grey,
        child: const Text('Out of Stock'),
      );
    }

    if (isInCart) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _isAdding ? null : () {
                final cartProvider = context.read<CartProvider>();
                final item = cartProvider.cart?.getItemByProductId(widget.productId);
                if (item != null) {
                  cartProvider.decreaseQuantity(item.id);
                }
              },
              icon: const Icon(Icons.remove, size: 18),
            ),
            Text(
              '$quantityInCart',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _isAdding || quantityInCart >= widget.availableStock 
                  ? null 
                  : () {
                      final cartProvider = context.read<CartProvider>();
                      final item = cartProvider.cart?.getItemByProductId(widget.productId);
                      if (item != null) {
                        cartProvider.increaseQuantity(item.id);
                      }
                    },
              icon: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
      );
    }

    return CustomButton(
      onPressed: _isAdding ? null : _addToCart,
      child: _isAdding
          ? const LoadingIndicator(size: 20)
          : const Text('Add to Cart'),
    );
  }

  Widget _buildFloatingButton(bool isInCart, int quantityInCart) {
    return FloatingActionButton.extended(
      onPressed: widget.availableStock <= 0 || _isAdding ? null : _addToCart,
      icon: _isAdding
          ? const LoadingIndicator(size: 20)
          : Icon(isInCart ? Icons.shopping_cart : Icons.add_shopping_cart),
      label: Text(isInCart ? 'Added ($quantityInCart)' : 'Add to Cart'),
      backgroundColor: isInCart ? Colors.green : null,
    );
  }

  Widget _buildCompactButton(bool isInCart, int quantityInCart) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: widget.availableStock <= 0 || _isAdding ? null : _addToCart,
        icon: _isAdding
            ? const LoadingIndicator(size: 16)
            : Icon(
                isInCart ? Icons.check : Icons.add_shopping_cart,
                size: 16,
              ),
        label: Text(
          isInCart ? 'Added' : 'Add',
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isInCart ? Colors.green : null,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

enum AddToCartStyle {
  button,    // Full width button
  floating,  // Floating action button
  compact,   // Small compact button
}
