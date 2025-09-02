import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../domain/order_model.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../address/presentation/address_provider.dart';
import '../../address/domain/address_model.dart';
import 'order_provider.dart';
import 'order_detail_page.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  static const routeName = '/create-order';

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  ShopAddress? _selectedPickupAddress;
  DateTime? _preferredPickupTime;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final cartProvider = context.read<CartProvider>();
    final addressProvider = context.read<AddressProvider>();
    
    // Load available pickup addresses based on cart items
    await _loadAvailablePickupAddresses(cartProvider);
  }

  Future<void> _loadAvailablePickupAddresses(CartProvider cartProvider) async {
    final addressProvider = context.read<AddressProvider>();
    
    // Get unique shop IDs from cart
    final shopIds = cartProvider.cart?.uniqueShopIds ?? [];
    
    if (shopIds.isNotEmpty) {
      // For pickup-based system, we need to get shop addresses
      await addressProvider.loadShopAddresses();
      
      // Find the shop address for items in cart
      final shopAddresses = addressProvider.shopAddresses
          .where((address) => shopIds.contains(address.shopId))
          .toList();
      
      if (shopAddresses.isNotEmpty) {
        setState(() {
          _selectedPickupAddress = shopAddresses.first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: Consumer3<CartProvider, AddressProvider, OrderProvider>(
        builder: (context, cartProvider, addressProvider, orderProvider, child) {
          if (cartProvider.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty'),
                  Text('Add some items to proceed with checkout'),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order items summary
                        _buildOrderItemsCard(cartProvider),
                        
                        const SizedBox(height: 16),
                        
                        // Pickup location selection
                        _buildPickupLocationCard(addressProvider),
                        
                        const SizedBox(height: 16),
                        
                        // Preferred pickup time
                        _buildPickupTimeCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Payment method selection
                        _buildPaymentMethodCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Order notes
                        _buildOrderNotesCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Order summary
                        _buildOrderSummaryCard(cartProvider),
                      ],
                    ),
                  ),
                ),
                
                // Bottom action bar
                _buildBottomActionBar(cartProvider, orderProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderItemsCard(CartProvider cartProvider) {
    final cart = cartProvider.cart!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Order Items (${cart.totalItems})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Edit Cart'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Show first 3 items, with "and X more" if there are more
            ...cart.availableItems.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
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
                                return const Icon(Icons.image_not_supported, size: 20);
                              },
                            ),
                          )
                        : const Icon(Icons.image, size: 20, color: Colors.grey),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Qty: ${item.quantity} × ${Formatters.currency(item.productPrice)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Text(
                    Formatters.currency(item.totalPrice),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            )).toList(),
            
            if (cart.availableItems.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                'and ${cart.availableItems.length - 3} more items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            // Unavailable items warning
            if (cart.hasUnavailableItems) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${cart.unavailableItems.length} item(s) are unavailable and will be excluded from this order.',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickupLocationCard(AddressProvider addressProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Pickup Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_selectedPickupAddress != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPickupAddress!.shopName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedPickupAddress!.shortAddress,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _selectedPickupAddress!.isCurrentlyOpen ? Icons.check_circle : Icons.schedule,
                          size: 16,
                          color: _selectedPickupAddress!.statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedPickupAddress!.statusText,
                          style: TextStyle(
                            color: _selectedPickupAddress!.statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _selectedPickupAddress!.businessHours,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              OutlinedButton.icon(
                onPressed: _showPickupLocationSelector,
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Change Location'),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No pickup location available for your cart items.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _showPickupLocationSelector,
                      child: const Text('Select'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickupTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Preferred Pickup Time (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_preferredPickupTime != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      Formatters.dateTime(_preferredPickupTime!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _preferredPickupTime = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 20),
                    ),
                  ],
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _selectPreferredPickupTime,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Select Preferred Time'),
              ),
            ],
            
            const SizedBox(height: 8),
            
            Text(
              'The shop will try to prepare your order by this time, but it\'s not guaranteed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.purple),
                const SizedBox(width: 12),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ...PaymentMethod.values.map((method) {
              return RadioListTile<PaymentMethod>(
                value: method,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                title: Row(
                  children: [
                    Icon(method.icon, size: 20),
                    const SizedBox(width: 12),
                    Text(method.title),
                  ],
                ),
                subtitle: method == PaymentMethod.cash 
                    ? const Text('Pay when you pickup your order')
                    : const Text('Pay online now'),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Order Notes (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any special instructions for the shop...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(CartProvider cartProvider) {
    final cart = cartProvider.cart!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildSummaryRow('Subtotal', cart.subtotal),
            if (cart.deliveryFee > 0)
              _buildSummaryRow('Service Fee', cart.deliveryFee),
            if (cart.tax > 0)
              _buildSummaryRow('Tax', cart.tax),
            if (cart.discount > 0)
              _buildSummaryRow('Discount', -cart.discount, isDiscount: true),
            
            const Divider(),
            
            _buildSummaryRow('Total', cart.total, isTotal: true),
            
            if (cart.totalSavings > 0) ...[
              const SizedBox(height: 8),
              Text(
                'You save ${Formatters.currency(cart.totalSavings)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
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

  Widget _buildBottomActionBar(CartProvider cartProvider, OrderProvider orderProvider) {
    final canPlaceOrder = _selectedPickupAddress != null && 
                         cartProvider.availableItems.isNotEmpty;
    
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
            // Order total
            Row(
              children: [
                Text(
                  'Total: ${Formatters.currency(cartProvider.total)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${cartProvider.totalItems} items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Place order button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: canPlaceOrder && !orderProvider.isCreatingOrder 
                    ? _placeOrder 
                    : null,
                child: orderProvider.isCreatingOrder
                    ? const LoadingIndicator(size: 20)
                    : Text(
                        _selectedPaymentMethod == PaymentMethod.cash 
                            ? 'Place Order'
                            : 'Proceed to Payment',
                      ),
              ),
            ),
            
            if (!canPlaceOrder) ...[
              const SizedBox(height: 8),
              Text(
                _selectedPickupAddress == null 
                    ? 'Please select a pickup location'
                    : 'No available items to order',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _showPickupLocationSelector() {
    final addressProvider = context.read<AddressProvider>();
    final cartProvider = context.read<CartProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PickupLocationSelector(
        availableAddresses: addressProvider.shopAddresses
            .where((address) => cartProvider.cart!.uniqueShopIds.contains(address.shopId))
            .toList(),
        selectedAddress: _selectedPickupAddress,
        onAddressSelected: (address) {
          setState(() {
            _selectedPickupAddress = address;
          });
        },
      ),
    );
  }

  Future<void> _selectPreferredPickupTime() async {
    if (_selectedPickupAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location first')),
      );
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Validate pickup time is within business hours
        if (_isValidPickupTime(selectedDateTime)) {
          setState(() {
            _preferredPickupTime = selectedDateTime;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select a time within business hours: ${_selectedPickupAddress!.businessHours}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _isValidPickupTime(DateTime dateTime) {
    if (_selectedPickupAddress == null) return false;
    
    // Check if it's a working day
    final dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dateTime.weekday - 1];
    if (!_selectedPickupAddress!.workingDays.contains(dayName)) {
      return false;
    }
    
    // Check if it's within business hours (simplified check)
    final hour = dateTime.hour;
    final openHour = int.parse(_selectedPickupAddress!.openingHours.split(':')[0]);
    final closeHour = int.parse(_selectedPickupAddress!.closingHours.split(':')[0]);
    
    return hour >= openHour && hour < closeHour;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPickupAddress == null) return;

    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    // Get cart item IDs
    final cartItemIds = cartProvider.availableItems.map((item) => item.id).toList();

    final order = await orderProvider.createOrder(
      cartItemIds: cartItemIds,
      pickupAddressId: _selectedPickupAddress!.id,
      paymentMethod: _selectedPaymentMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      preferredPickupTime: _preferredPickupTime,
    );

    if (order != null && mounted) {
      // Clear cart after successful order
      await cartProvider.clearCart();
      
      if (_selectedPaymentMethod == PaymentMethod.cash) {
        // Cash payment - go directly to order detail
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(orderId: order.id),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${order.orderNumber} placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Online payment - go to payment page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(order: order),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to place order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class PickupLocationSelector extends StatelessWidget {
  const PickupLocationSelector({
    super.key,
    required this.availableAddresses,
    required this.selectedAddress,
    required this.onAddressSelected,
  });

  final List<ShopAddress> availableAddresses;
  final ShopAddress? selectedAddress;
  final Function(ShopAddress) onAddressSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Select Pickup Location',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const Divider(),
          
          if (availableAddresses.isEmpty) ...[
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No pickup locations available'),
                    Text('for your cart items'),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                itemCount: availableAddresses.length,
                itemBuilder: (context, index) {
                  final address = availableAddresses[index];
                  final isSelected = selectedAddress?.id == address.id;
                  
                  return Card(
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                    child: ListTile(
                      leading: Icon(
                        Icons.store,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                      title: Text(
                        address.shopName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(address.shortAddress),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                address.statusIcon,
                                size: 14,
                                color: address.statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                address.statusText,
                                style: TextStyle(
                                  color: address.statusColor,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                address.businessHours,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      onTap: () {
                        onAddressSelected(address);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Payment page placeholder (we'll implement this next)
class PaymentPage extends StatelessWidget {
  const PaymentPage({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: const Center(
        child: Text('Payment integration will be implemented next'),
      ),
    );
  }
}
