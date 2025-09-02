// Order detail page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../domain/order_model.dart';
import 'order_provider.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

  final int orderId;

  static const routeName = '/order-detail';

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().getOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
              body: Center(child: LoadingIndicator()),
            );
          }

          final order = provider.selectedOrder;
          if (order == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Order Details')),
              body: const Center(
                child: Text('Order not found'),
              ),
            );
          }

          return _buildOrderDetail(order, provider);
        },
      ),
      bottomNavigationBar: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          final order = provider.selectedOrder;
          if (order == null) return const SizedBox.shrink();
          
          return _buildBottomActions(order, provider);
        },
      ),
    );
  }

  Widget _buildOrderDetail(Order order, OrderProvider provider) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              order.orderNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 2),
                ],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    order.statusColor,
                    order.statusColor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareOrder(order),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, order, provider),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'receipt',
                  child: Row(
                    children: [
                      Icon(Icons.receipt, size: 20),
                      SizedBox(width: 8),
                      Text('View Receipt'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'directions',
                  child: Row(
                    children: [
                      Icon(Icons.directions, size: 20),
                      SizedBox(width: 8),
                      Text('Get Directions'),
                    ],
                  ),
                ),
                if (order.canCancel)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancel Order'),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Order content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                _buildStatusCard(order),
                
                const SizedBox(height: 16),
                
                // Order items
                _buildOrderItemsCard(order),
                
                const SizedBox(height: 16),
                
                // Pickup details
                _buildPickupDetailsCard(order),
                
                const SizedBox(height: 16),
                
                // Payment details
                _buildPaymentDetailsCard(order),
                
                const SizedBox(height: 16),
                
                // Order timeline
                _buildOrderTimelineCard(order),
                
                const SizedBox(height: 16),
                
                // Order summary
                _buildOrderSummaryCard(order),
                
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(order),
                ],
                
                const SizedBox(height: 100), // Space for bottom actions
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    order.statusIcon,
                    color: order.statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.statusTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: order.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        order.statusDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Time information
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Ordered ${order.timeAgo}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            if (order.estimatedPickupTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated pickup: ${order.formattedEstimatedPickup}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            
            if (order.isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Order is overdue',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items (${order.totalItems})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...order.items.map((item) => _buildOrderItemRow(item)).toList(),
            
            if (order.hasUnavailableItems) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Some items may no longer be available. Please contact the shop for updates.',
                        style: TextStyle(
                          color: Colors.red.shade700,
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

  Widget _buildOrderItemRow(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
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
          
          const SizedBox(width: 12),
          
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: !item.isAvailable ? TextDecoration.lineThrough : null,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  'Qty: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Text(
                      '${item.formattedPrice} × ${item.quantity}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.formattedTotal,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDetailsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Pickup Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Shop name
            _buildDetailRow(
              Icons.storefront,
              'Shop',
              order.pickupAddress.shopName,
            ),
            
            // Address
            _buildDetailRow(
              Icons.location_on,
              'Address',
              order.pickupAddress.fullAddress,
            ),
            
            // Contact
            _buildDetailRow(
              Icons.phone,
              'Phone',
              order.pickupAddress.phone,
              onTap: () => _makePhoneCall(order.pickupAddress.phone),
            ),
            
            // Business hours
            _buildDetailRow(
              Icons.access_time,
              'Hours',
              order.pickupAddress.businessHours,
            ),
            
            if (order.pickupAddress.instructions != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Pickup Instructions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.pickupAddress.instructions!,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(order.pickupAddress.phone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Shop'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openDirections(order.pickupAddress),
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Directions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(order.paymentMethod.icon, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Payment Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Payment method
            _buildDetailRow(
              order.paymentMethod.icon,
              'Payment Method',
              order.paymentMethod.title,
            ),
            
            // Payment status
            Row(
              children: [
                Icon(Icons.payment, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  'Payment Status',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.paymentStatus.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: order.paymentStatus.color),
                  ),
                  child: Text(
                    order.paymentStatus.title,
                    style: TextStyle(
                      color: order.paymentStatus.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            if (order.paymentTransactionId != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.receipt_long,
                'Transaction ID',
                order.paymentTransactionId!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimelineCard(Order order) {
    final timeline = _getOrderTimeline(order);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...timeline.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == timeline.length - 1;
              
              return _buildTimelineStep(step, isLast);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(Map<String, dynamic> step, bool isLast) {
    final isCompleted = step['isCompleted'] as bool;
    final isCurrent = step['isCurrent'] as bool;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : (isCurrent ? Colors.blue : Colors.grey[300]),
                shape: BoxShape.circle,
              ),
              child: isCompleted 
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : (isCurrent ? const Icon(Icons.circle, size: 8, color: Colors.white) : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Timeline content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.green : (isCurrent ? Colors.blue : Colors.grey),
                  ),
                ),
                if (step['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step['description'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (step['time'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step['time'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(Order order) {
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
            
            _buildSummaryRow('Subtotal', order.subtotal),
            if (order.deliveryFee > 0)
              _buildSummaryRow('Delivery Fee', order.deliveryFee),
            if (order.tax > 0)
              _buildSummaryRow('Tax', order.tax),
            if (order.discount > 0)
              _buildSummaryRow('Discount', -order.discount, isDiscount: true),
            
            const Divider(),
            
            _buildSummaryRow('Total', order.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(Order order) {
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
                  'Order Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              order.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onTap != null ? Theme.of(context).primaryColor : null,
                      fontWeight: onTap != null ? FontWeight.w500 : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.launch,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
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

  Widget _buildBottomActions(Order order, OrderProvider provider) {
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
            // Primary action based on order status
            if (order.status == OrderStatus.ready) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openDirections(order.pickupAddress),
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions to Pickup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Secondary actions
            Row(
              children: [
                // Call shop
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(order.pickupAddress.phone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Shop'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Reorder (if completed)
                if (order.isCompleted)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _reorderItems(order),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reorder'),
                    ),
                  )
                else if (order.canCancel)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCancelDialog(order, provider),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<Map<String, dynamic>> _getOrderTimeline(Order order) {
    return [
      {
        'title': 'Order Placed',
        'description': 'Order has been placed successfully',
        'time': Formatters.dateTime(order.createdAt),
        'isCompleted': true,
        'isCurrent': false,
      },
      {
        'title': 'Order Confirmed',
        'description': 'Shop has confirmed your order',
        'time': order.status.index >= OrderStatus.confirmed.index ? 'Confirmed' : null,
        'isCompleted': order.status.index >= OrderStatus.confirmed.index,
        'isCurrent': order.status == OrderStatus.pending,
      },
      {
        'title': 'Preparing Order',
        'description': 'Your order is being prepared',
        'time': order.status.index >= OrderStatus.preparing.index ? 'In preparation' : null,
        'isCompleted': order.status.index >= OrderStatus.preparing.index,
        'isCurrent': order.status == OrderStatus.confirmed,
      },
      {
        'title': 'Ready for Pickup',
        'description': 'Order is ready for collection',
        'time': order.status.index >= OrderStatus.ready.index ? 'Ready' : null,
        'isCompleted': order.status.index >= OrderStatus.ready.index,
        'isCurrent': order.status == OrderStatus.preparing,
      },
      {
        'title': 'Order Completed',
        'description': 'Order has been collected successfully',
        'time': order.actualPickupTime != null ? Formatters.dateTime(order.actualPickupTime!) : null,
        'isCompleted': order.status == OrderStatus.completed,
        'isCurrent': order.status == OrderStatus.ready,
      },
    ];
  }

  void _handleMenuAction(String action, Order order, OrderProvider provider) {
    switch (action) {
      case 'receipt':
        _viewReceipt(order);
        break;
      case 'directions':
        _openDirections(order.pickupAddress);
        break;
      case 'cancel':
        _showCancelDialog(order, provider);
        break;
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _openDirections(ShopAddress address) async {
    final Uri launchUri = Uri.parse(address.googleMapsUrl);
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareOrder(Order order) {
    final shareText = '''
Order Details:
${order.orderNumber}

Status: ${order.statusTitle}
Items: ${order.totalItems}
Total: ${order.formattedTotal}

Pickup from: ${order.pickupAddress.shopName}
${order.pickupAddress.shortAddress}

${order.pickupInstructions}
    ''';
    
    Share.share(shareText, subject: 'Order ${order.orderNumber}');
  }

  void _viewReceipt(Order order) {
    // TODO: Navigate to receipt page or generate PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt generation coming soon')),
    );
  }

  void _showCancelDialog(Order order, OrderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => OrderCancelDialog(order: order),
    );
  }

  void _reorderItems(Order order) {
    // TODO: Add items back to cart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Items added to cart for reordering')),
    );
  }
}

class OrderCancelDialog extends StatefulWidget {
  const OrderCancelDialog({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  State<OrderCancelDialog> createState() => _OrderCancelDialogState();
}

class _OrderCancelDialogState extends State<OrderCancelDialog> {
  final _reasonController = TextEditingController();
  bool _refundRequested = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Order'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to cancel order ${widget.order.orderNumber}?'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for cancellation',
              hintText: 'Please provide a reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          if (widget.order.isPaid)
            CheckboxListTile(
              value: _refundRequested,
              onChanged: (value) {
                setState(() {
                  _refundRequested = value ?? false;
                });
              },
              title: const Text('Request Refund'),
              subtitle: const Text('Refund will be processed to original payment method'),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Order'),
        ),
        Consumer<OrderProvider>(
          builder: (context, provider, child) {
            return ElevatedButton(
              onPressed: provider.isUpdatingStatus ? null : () async {
                if (_reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a reason for cancellation')),
                  );
                  return;
                }

                final success = await provider.cancelOrder(
                  widget.order.id,
                  _reasonController.text.trim(),
                  refundRequested: _refundRequested,
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled successfully')),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Failed to cancel order'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: provider.isUpdatingStatus 
                  ? const LoadingIndicator(size: 16) 
                  : const Text('Cancel Order'),
            );
          },
        ),
      ],
    );
  }
}
