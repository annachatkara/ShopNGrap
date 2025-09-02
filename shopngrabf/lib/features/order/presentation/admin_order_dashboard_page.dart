import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/formatters.dart';
import '../domain/order_model.dart';
import '../../auth/presentation/auth_provider.dart';
import 'order_provider.dart';
import 'admin_order_detail_page.dart';

class AdminOrderDashboardPage extends StatefulWidget {
  const AdminOrderDashboardPage({super.key});

  static const routeName = '/admin/orders';

  @override
  State<AdminOrderDashboardPage> createState() => _AdminOrderDashboardPageState();
}

class _AdminOrderDashboardPageState extends State<AdminOrderDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAdmin || authProvider.isSuperuser) {
        final orderProvider = context.read<OrderProvider>();
        orderProvider.loadShopOrders();
        orderProvider.loadOrderStatistics();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OrderProvider>(
      builder: (context, authProvider, orderProvider, child) {
        if (!authProvider.isAdmin && !authProvider.isSuperuser) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Management')),
            body: const Center(
              child: EmptyState(
                icon: Icons.admin_panel_settings,
                title: 'Admin Access Required',
                subtitle: 'You need admin privileges to manage orders',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Order Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  orderProvider.loadShopOrders(forceRefresh: true);
                  orderProvider.loadOrderStatistics();
                },
              ),
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'statistics',
                    child: Row(
                      children: [
                        Icon(Icons.analytics, size: 20),
                        SizedBox(width: 8),
                        Text('View Statistics'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'bulk_actions',
                    child: Row(
                      children: [
                        Icon(Icons.checklist, size: 20),
                        SizedBox(width: 8),
                        Text('Bulk Actions'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              onTap: _onTabChanged,
              tabs: [
                Tab(text: 'All (${orderProvider.shopOrders.length})'),
                Tab(text: 'Pending (${_getOrdersByStatus(orderProvider.shopOrders, OrderStatus.pending).length})'),
                Tab(text: 'Confirmed (${_getOrdersByStatus(orderProvider.shopOrders, OrderStatus.confirmed).length})'),
                Tab(text: 'Ready (${_getOrdersByStatus(orderProvider.shopOrders, OrderStatus.ready).length})'),
                Tab(text: 'Completed (${_getOrdersByStatus(orderProvider.shopOrders, OrderStatus.completed).length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Statistics summary
              _buildStatisticsSummary(orderProvider),
              
              // Orders list
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(orderProvider.shopOrders, orderProvider),
                    _buildOrdersList(_getOrdersByStatus(orderProvider.shopOrders, OrderStatus.pending), orderProvider),
                    _buildOrdersList(_getOrdersByStatus(orderProvider.shopOrders, OrderStatus.confirmed), orderProvider),
                    _buildOrdersList(_getOrdersByStatus(orderProvider.shopOrders, OrderStatus.ready), orderProvider),
                    _buildOrdersList(_getOrdersByStatus(orderProvider.shopOrders, OrderStatus.completed), orderProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSummary(OrderProvider orderProvider) {
    if (orderProvider.orderStatistics == null) {
      return const SizedBox.shrink();
    }

    final stats = orderProvider.orderStatistics!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Today Revenue',
              stats.formattedTodayRevenue,
              Icons.attach_money,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending Orders',
              '${stats.pendingOrders}',
              Icons.pending,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Completed',
              '${stats.completedOrders}',
              Icons.done_all,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, OrderProvider orderProvider) {
    if (orderProvider.isLoading && orders.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Orders Found',
        subtitle: 'Orders will appear here when customers place them',
      );
    }

    return RefreshIndicator(
      onRefresh: () => orderProvider.loadShopOrders(forceRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return AdminOrderCard(
            order: order,
            onTap: () => _navigateToOrderDetail(order),
            onQuickAction: (action) => _handleQuickAction(order, action, orderProvider),
          );
        },
      ),
    );
  }

  List<Order> _getOrdersByStatus(List<Order> orders, OrderStatus status) {
    return orders.where((order) => order.status == status).toList();
  }

  void _onTabChanged(int index) {
    // Tab change handled by TabBarView automatically
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'statistics':
        _showStatisticsDialog();
        break;
      case 'bulk_actions':
        _showBulkActionsDialog();
        break;
    }
  }

  void _handleQuickAction(Order order, String action, OrderProvider orderProvider) {
    switch (action) {
      case 'confirm':
        _confirmOrder(order, orderProvider);
        break;
      case 'ready':
        _markOrderReady(order, orderProvider);
        break;
      case 'complete':
        _completeOrder(order, orderProvider);
        break;
      case 'call':
        _callCustomer(order);
        break;
    }
  }

  Future<void> _confirmOrder(Order order, OrderProvider orderProvider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ConfirmOrderDialog(order: order),
    );

    if (result != null) {
      final success = await orderProvider.confirmOrder(
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

  Future<void> _markOrderReady(Order order, OrderProvider orderProvider) async {
    final success = await orderProvider.markOrderReady(order.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as ready for pickup'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _completeOrder(Order order, OrderProvider orderProvider) async {
    final success = await orderProvider.completeOrder(order.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _callCustomer(Order order) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${order.customerPhone}...')),
    );
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => const OrderStatisticsDialog(),
    );
  }

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => const BulkActionsDialog(),
    );
  }

  void _navigateToOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminOrderDetailPage(orderId: order.id),
      ),
    );
  }
}

class AdminOrderCard extends StatelessWidget {
  const AdminOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onQuickAction,
  });

  final Order order;
  final VoidCallback onTap;
  final Function(String) onQuickAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          order.timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: order.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: order.statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          order.statusIcon,
                          size: 14,
                          color: order.statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.statusTitle,
                          style: TextStyle(
                            color: order.statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Customer info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order.customerName} • ${order.customerPhone}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Order summary
              Row(
                children: [
                  Icon(Icons.shopping_bag, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${order.totalItems} items • ${order.formattedTotal}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.paymentStatus.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.paymentStatus.title,
                      style: TextStyle(
                        color: order.paymentStatus.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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
                      'Pickup by: ${order.formattedEstimatedPickup}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Quick actions
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = <Widget>[];
    
    switch (order.status) {
      case OrderStatus.pending:
        actions.addAll([
          _buildActionButton('Confirm', Colors.blue, () => onQuickAction('confirm')),
          _buildActionButton('Call', Colors.green, () => onQuickAction('call')),
        ]);
        break;
      case OrderStatus.confirmed:
        actions.addAll([
          _buildActionButton('Mark Ready', Colors.orange, () => onQuickAction('ready')),
          _buildActionButton('Call', Colors.green, () => onQuickAction('call')),
        ]);
        break;
      case OrderStatus.ready:
        actions.addAll([
          _buildActionButton('Complete', Colors.green, () => onQuickAction('complete')),
          _buildActionButton('Call', Colors.blue, () => onQuickAction('call')),
        ]);
        break;
      default:
        actions.add(
          _buildActionButton('Call', Colors.blue, () => onQuickAction('call')),
        );
    }
    
    return Row(
      children: actions.map((action) => Expanded(child: action)).toList(),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class ConfirmOrderDialog extends StatefulWidget {
  const ConfirmOrderDialog({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  State<ConfirmOrderDialog> createState() => _ConfirmOrderDialogState();
}

class _ConfirmOrderDialogState extends State<ConfirmOrderDialog> {
  final _notesController = TextEditingController();
  DateTime? _estimatedPickupTime;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Order ${widget.order.orderNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set estimated pickup time and add notes for the customer.'),
            
            const SizedBox(height: 16),
            
            // Estimated pickup time
            Text(
              'Estimated Pickup Time',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            InkWell(
              onTap: _selectPickupTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 12),
                    Text(
                      _estimatedPickupTime != null 
                          ? Formatters.dateTime(_estimatedPickupTime!)
                          : 'Select pickup time',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes
            Text(
              'Notes for Customer',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Optional notes for the customer...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'estimatedTime': _estimatedPickupTime,
              'notes': _notesController.text.trim().isEmpty 
                  ? null 
                  : _notesController.text.trim(),
            });
          },
          child: const Text('Confirm Order'),
        ),
      ],
    );
  }

  Future<void> _selectPickupTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _estimatedPickupTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
}

class OrderStatisticsDialog extends StatelessWidget {
  const OrderStatisticsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final stats = orderProvider.orderStatistics;
        
        return AlertDialog(
          title: const Text('Order Statistics'),
          content: stats == null 
              ? const LoadingIndicator()
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatRow('Total Orders', '${stats.totalOrders}'),
                      _buildStatRow('Pending Orders', '${stats.pendingOrders}'),
                      _buildStatRow('Completed Orders', '${stats.completedOrders}'),
                      _buildStatRow('Cancelled Orders', '${stats.cancelledOrders}'),
                      const Divider(),
                      _buildStatRow('Total Revenue', stats.formattedTotalRevenue),
                      _buildStatRow('Today Revenue', stats.formattedTodayRevenue),
                      _buildStatRow('Average Order Value', stats.formattedAverageOrderValue),
                      const Divider(),
                      _buildStatRow('Completion Rate', '${stats.completionRate.toStringAsFixed(1)}%'),
                      _buildStatRow('Cancellation Rate', '${stats.cancellationRate.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class BulkActionsDialog extends StatelessWidget {
  const BulkActionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Actions'),
      content: const Text('Bulk actions for managing multiple orders will be available soon.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
