// Order list page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/formatters.dart';
import '../domain/order_model.dart';
import 'order_provider.dart';
import 'order_detail_page.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  static const routeName = '/orders';

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      context.read<OrderProvider>().loadMoreOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20),
                    SizedBox(width: 8),
                    Text('Filter Orders'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sort',
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 20),
                    SizedBox(width: 8),
                    Text('Sort Orders'),
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
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(child: LoadingIndicator());
          }

          if (provider.hasError && provider.orders.isEmpty) {
            return _buildErrorView(provider);
          }

          if (provider.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No Orders Yet',
              subtitle: 'Start shopping to see your orders here',
              actionText: 'Start Shopping',
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(provider.orders, provider),
              _buildOrdersList(provider.activeOrders, provider),
              _buildOrdersList(provider.completedOrders, provider),
              _buildOrdersList(provider.cancelledOrders, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, OrderProvider provider) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Orders Found',
        subtitle: 'No orders match the current filter',
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: Column(
        children: [
          // Active filters and results summary
          _buildResultsSummary(provider),
          
          // Orders list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: orders.length + (provider.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= orders.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: LoadingIndicator(),
                    ),
                  );
                }

                final order = orders[index];
                return OrderCard(
                  order: order,
                  onTap: () => _navigateToOrderDetail(order),
                  onCancel: order.canCancel ? () => _showCancelDialog(order) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary(OrderProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${provider.totalOrders} orders found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          if (provider.hasActiveFilters)
            TextButton.icon(
              onPressed: () => provider.clearFilters(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(OrderProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _onTabChanged(int index) {
    final provider = context.read<OrderProvider>();
    OrderStatus? status;
    
    switch (index) {
      case 0: // All
        status = null;
        break;
      case 1: // Active
        // Filter active orders locally since we don't have "active" as a single status
        break;
      case 2: // Completed
        status = OrderStatus.completed;
        break;
      case 3: // Cancelled
        status = OrderStatus.cancelled;
        break;
    }
    
    if (status != null) {
      provider.filterByStatus(status);
    } else if (index == 0) {
      provider.filterByStatus(null);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter':
        _showFiltersBottomSheet();
        break;
      case 'sort':
        _showSortBottomSheet();
        break;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Orders'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter order number or shop name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<OrderProvider>().searchOrders(_searchController.text.trim());
              _searchController.clear();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const OrderFiltersBottomSheet(),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const OrderSortBottomSheet(),
    );
  }

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => OrderCancelDialog(order: order),
    );
  }

  void _navigateToOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(orderId: order.id),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onCancel,
  });

  final Order order;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              
              // Pickup location
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.pickupAddress.shopName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.pickupAddress.shortAddress,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Order summary
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.totalItems} item${order.totalItems > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          order.formattedTotal,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  if (onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel Order'),
                    ),
                ],
              ),
              
              // Estimated pickup time
              if (order.estimatedPickupTime != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Pickup by: ${order.formattedEstimatedPickup}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OrderFiltersBottomSheet extends StatefulWidget {
  const OrderFiltersBottomSheet({super.key});

  @override
  State<OrderFiltersBottomSheet> createState() => _OrderFiltersBottomSheetState();
}

class _OrderFiltersBottomSheetState extends State<OrderFiltersBottomSheet> {
  late OrderFilters _filters;
  OrderStatus? _selectedStatus;
  PaymentStatus? _selectedPaymentStatus;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    final provider = context.read<OrderProvider>();
    _filters = provider.filters;
    _selectedStatus = _filters.status;
    _selectedPaymentStatus = _filters.paymentStatus;
    if (_filters.fromDate != null && _filters.toDate != null) {
      _selectedDateRange = DateTimeRange(
        start: _filters.fromDate!,
        end: _filters.toDate!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Filter Orders',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearAll,
                child: const Text('Clear All'),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const Divider(),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status
                  Text(
                    'Order Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: OrderStatus.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      return FilterChip(
                        label: Text(status.title),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected ? status : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Payment Status
                  Text(
                    'Payment Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PaymentStatus.values.map((status) {
                      final isSelected = _selectedPaymentStatus == status;
                      return FilterChip(
                        label: Text(status.title),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPaymentStatus = selected ? status : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Date Range
                  Text(
                    'Date Range',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(_selectedDateRange != null
                        ? '${Formatters.dateOnly(_selectedDateRange!.start)} - ${Formatters.dateOnly(_selectedDateRange!.end)}'
                        : 'Select Date Range'),
                  ),
                  if (_selectedDateRange != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Date Range'),
                    ),
                ],
              ),
            ),
          ),
          
          // Apply Button
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _selectedStatus = null;
      _selectedPaymentStatus = null;
      _selectedDateRange = null;
    });
  }

  void _applyFilters() {
    final newFilters = _filters.copyWith(
      status: _selectedStatus,
      paymentStatus: _selectedPaymentStatus,
      fromDate: _selectedDateRange?.start,
      toDate: _selectedDateRange?.end,
    );
    
    context.read<OrderProvider>().applyFilters(newFilters);
    Navigator.pop(context);
  }
}

class OrderSortBottomSheet extends StatelessWidget {
  const OrderSortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      {'key': 'newest', 'title': 'Newest First', 'icon': Icons.schedule},
      {'key': 'oldest', 'title': 'Oldest First', 'icon': Icons.history},
      {'key': 'amount', 'title': 'Highest Amount', 'icon': Icons.attach_money},
      {'key': 'status', 'title': 'By Status', 'icon': Icons.flag},
    ];

    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort Orders',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...sortOptions.map((option) {
                final isSelected = provider.filters.sortBy == option['key'];
                return ListTile(
                  leading: Icon(option['icon'] as IconData),
                  title: Text(option['title'] as String),
                  trailing: isSelected ? Icon(
                    Icons.check,
                    color: Theme.of(context).primaryColor,
                  ) : null,
                  onTap: () {
                    provider.sortOrders(option['key'] as String);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
