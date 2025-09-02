import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../domain/order_model.dart';
import 'order_provider.dart';

class AdminOrderDetailPage extends StatefulWidget {
  const AdminOrderDetailPage({
    super.key,
    required this.orderId,
  });

  final int orderId;

  static const routeName = '/admin/order-detail';

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
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
          
          return _buildAdminActions(order, provider);
        },
      ),
    );
  }

  Widget _buildOrderDetail(Order order, OrderProvider provider) {
    return CustomScrollView(
      slivers: [
        // Admin app bar
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Order ${order.orderNumber}',
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
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, order, provider),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'call_customer',
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 20),
                      SizedBox(width: 8),
                      Text('Call Customer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'send_notification',
                  child: Row(
                    children: [
                      Icon(Icons.notifications, size: 20),
                      SizedBox(width: 8),
                      Text('Send Notification'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print_receipt',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 20),
                      SizedBox(width: 8),
                      Text('Print Receipt'),
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
                // Status management card
                _buildStatusManagementCard(order, provider),
                
                const SizedBox(height: 16),
                
                // Customer information
                _buildCustomerInfoCard(order),
                
                const SizedBox(height: 16),
                
                // Order items
                _buildOrderItemsCard(order),
                
                const SizedBox(height: 16),
                
                // Payment information
                _buildPaymentInfoCard(order),
                
                const SizedBox(height: 16),
                
                // Order timeline
                _buildOrderTimelineCard(order),
                
                const SizedBox(height: 16),
                
                // Order summary
                _buildOrderSummaryCard(order),
                
                if (order.notes != null || order.shopNotes != null) ...[
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

  Widget _buildStatusManagementCard(Order order, OrderProvider provider) {
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
                        'Current Status: ${order.statusTitle}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            
            const SizedBox(height: 16),
            
            // Quick status change buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildStatusChangeButtons(order, provider),
            ),
            
            // Time information
            const SizedBox(height: 12),
            
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatusChangeButtons(Order order, OrderProvider provider) {
    final buttons = <Widget>[];
    
    switch (order.status) {
      case OrderStatus.pending:
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _showConfirmOrderDialog(order, provider),
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Confirm Order'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        );
        break;
      case OrderStatus.confirmed:
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _markOrderReady(order, provider),
            icon: const Icon(Icons.shopping_bag, size: 16),
            label: const Text('Mark Ready'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        );
        break;
      case OrderStatus.ready:
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _completeOrder(order, provider),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Complete Order'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        );
        break;
    }
    
    return buttons;
  }

  Widget _buildCustomerInfoCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Customer Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.person, 'Name', order.customerName),
            _buildInfoRow(Icons.email, 'Email', order.customerEmail),
            _buildInfoRow(
              Icons.phone, 
              'Phone', 
              order.customerPhone,
              onTap: () => _makePhoneCall(order.customerPhone),
            ),
            
            const SizedBox(height: 12),
            
            // Customer action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(order.customerPhone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Customer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendNotification(order),
                    icon: const Icon(Icons.notifications, size: 16),
                    label: const Text('Send Update'),
                  ),
                ),
              ],
            ),
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
            
            ...order.items.map((item) => Container(
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
                    width: 50,
                    height: 50,
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item.quantity} × ${item.formattedPrice}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Text(
                    item.formattedTotal,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(order.paymentMethod.icon, color: Colors.purple),
                const SizedBox(width: 12),
                Text(
                  'Payment Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.payment, 'Payment Method', order.paymentMethod.title),
            
            Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 20, color: Colors.grey[600]),
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
              _buildInfoRow(Icons.receipt_long, 'Transaction ID', order.paymentTransactionId!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimelineCard(Order order) {
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
            
            // Timeline items would be built here similar to customer view
            Text(
              'Order placed: ${order.formattedCreatedAt}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (order.estimatedPickupTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Estimated pickup: ${order.formattedEstimatedPickup}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (order.actualPickupTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Completed: ${Formatters.dateTime(order.actualPickupTime!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
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
              _buildSummaryRow('Service Fee', order.deliveryFee),
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
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (order.notes != null) ...[
              Text(
                'Customer Notes:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(order.notes!),
              const SizedBox(height: 12),
            ],
            
            if (order.shopNotes != null) ...[
              Text(
                'Shop Notes:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(order.shopNotes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
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

  Widget _buildAdminActions(Order order, OrderProvider provider) {
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
        child: Row(
          children: [
            // Call customer
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _makePhoneCall(order.customerPhone),
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('Call Customer'),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Primary action based on status
            Expanded(
              child: _buildPrimaryAction(order, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(Order order, OrderProvider provider) {
    switch (order.status) {
      case OrderStatus.pending:
        return ElevatedButton.icon(
          onPressed: () => _showConfirmOrderDialog(order, provider),
          icon: const Icon(Icons.check_circle, size: 16),
          label: const Text('Confirm'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        );
      case OrderStatus.confirmed:
        return ElevatedButton.icon(
          onPressed: () => _markOrderReady(order, provider),
          icon: const Icon(Icons.shopping_bag, size: 16),
          label: const Text('Mark Ready'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        );
      case OrderStatus.ready:
        return ElevatedButton.icon(
          onPressed: () => _completeOrder(order, provider),
          icon: const Icon(Icons.done_all, size: 16),
          label: const Text('Complete'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        );
      default:
        return ElevatedButton.icon(
          onPressed: () => _sendNotification(order),
          icon: const Icon(Icons.notifications, size: 16),
          label: const Text('Notify'),
        );
    }
  }

  // Event handlers
  void _handleMenuAction(String action, Order order, OrderProvider provider) {
    switch (action) {
      case 'call_customer':
        _makePhoneCall(order.customerPhone);
        break;
      case 'send_notification':
        _sendNotification(order);
        break;
      case 'print_receipt':
        _printReceipt(order);
        break;
    }
  }

  Future<void> _showConfirmOrderDialog(Order order, OrderProvider provider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ConfirmOrderDialog(order: order),
    );

    if (result != null) {
      final success = await provider.confirmOrder(
        order.id,
        notes: result['notes'],
        estimatedPickupTime: result['estimatedTime'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _markOrderReady(Order order, OrderProvider provider) async {
    final success = await provider.markOrderReady(order.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as ready for pickup'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _completeOrder(Order order, OrderProvider provider) async {
    final success = await provider.completeOrder(order.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
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

  void _sendNotification(Order order) {
    // TODO: Implement notification sending
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending notification to customer...')),
    );
  }

  void _printReceipt(Order order) {
    // TODO: Implement receipt printing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing receipt...')),
    );
  }
}
