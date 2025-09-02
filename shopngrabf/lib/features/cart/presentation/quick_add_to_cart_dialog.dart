import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../product/domain/product_model.dart';
import 'cart_provider.dart';

class QuickAddToCartDialog extends StatefulWidget {
  const QuickAddToCartDialog({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  State<QuickAddToCartDialog> createState() => _QuickAddToCartDialogState();
}

class _QuickAddToCartDialogState extends State<QuickAddToCartDialog> {
  final _quantityController = TextEditingController(text: '1');
  int _selectedQuantity = 1;
  bool _isAdding = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _increaseQuantity() {
    if (_selectedQuantity < widget.product.stock && _selectedQuantity < 10) {
      setState(() {
        _selectedQuantity++;
        _quantityController.text = _selectedQuantity.toString();
      });
    }
  }

  void _decreaseQuantity() {
    if (_selectedQuantity > 1) {
      setState(() {
        _selectedQuantity--;
        _quantityController.text = _selectedQuantity.toString();
      });
    }
  }

  void _onQuantityChanged(String value) {
    final quantity = int.tryParse(value);
    if (quantity != null && quantity > 0 && quantity <= widget.product.stock) {
      setState(() {
        _selectedQuantity = quantity;
      });
    }
  }

  Future<void> _addToCart() async {
    if (_isAdding || _selectedQuantity <= 0) return;

    setState(() {
      _isAdding = true;
    });

    try {
      final cartProvider = context.read<CartProvider>();
      final success = await cartProvider.addToCart(
        productId: widget.product.id,
        quantity: _selectedQuantity,
      );
      
      if (success && mounted) {
        Navigator.of(context).pop(true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.product.name} to cart'),
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
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add to Cart',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Product Info
            Row(
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: widget.product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported);
                            },
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                
                const SizedBox(width: 12),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        widget.product.formattedPrice,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      Text(
                        '${widget.product.stock} available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.product.stockStatusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quantity Selection
            Text(
              'Quantity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _selectedQuantity > 1 ? _decreaseQuantity : null,
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          controller: _quantityController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          validator: (value) => Validators.quantity(
                            value,
                            maxQuantity: widget.product.stock,
                          ),
                          onChanged: _onQuantityChanged,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _selectedQuantity < widget.product.stock && _selectedQuantity < 10
                            ? _increaseQuantity
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Total Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '₹${(widget.product.price * _selectedQuantity).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: CustomButton(
                    onPressed: _isAdding ? null : _addToCart,
                    child: _isAdding
                        ? const LoadingIndicator(size: 20)
                        : const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum AddToCartStyle {
  button,   // Regular button
  floating, // Floating action button
  compact,  // Compact button for lists
}

// Helper function to show the dialog
Future<bool?> showQuickAddToCartDialog(
  BuildContext context,
  Product product,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => QuickAddToCartDialog(product: product),
  );
}
