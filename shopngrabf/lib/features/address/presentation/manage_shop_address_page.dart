import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/presentation/auth_provider.dart';
import 'address_provider.dart';
import 'add_edit_shop_address_page.dart';

class ManageShopAddressPage extends StatefulWidget {
  const ManageShopAddressPage({super.key});

  static const routeName = '/manage-shop-address';

  @override
  State<ManageShopAddressPage> createState() => _ManageShopAddressPageState();
}

class _ManageShopAddressPageState extends State<ManageShopAddressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAdmin || authProvider.isSuperuser) {
        context.read<AddressProvider>().loadMyShopAddress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Address'),
        actions: [
          Consumer<AddressProvider>(
            builder: (context, provider, child) {
              if (provider.hasShopAddress) {
                return PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Address'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'preview',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 8),
                          Text('Preview'),
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
      body: Consumer2<AddressProvider, AuthProvider>(
        builder: (context, addressProvider, authProvider, child) {
          if (!authProvider.isAdmin && !authProvider.isSuperuser) {
            return const Center(
              child: EmptyState(
                icon: Icons.admin_panel_settings,
                title: 'Admin Access Required',
                subtitle: 'You need admin privileges to manage shop address',
              ),
            );
          }

          if (addressProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (addressProvider.hasError && !addressProvider.hasShopAddress) {
            return _buildErrorView(addressProvider);
          }

          if (!addressProvider.hasShopAddress) {
            return _buildNoAddressView();
          }

          return _buildAddressView(addressProvider.myShopAddress!);
        },
      ),
      floatingActionButton: Consumer2<AddressProvider, AuthProvider>(
        builder: (context, addressProvider, authProvider, child) {
          if (!authProvider.isAdmin && !authProvider.isSuperuser) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _navigateToAddEdit(),
            icon: Icon(addressProvider.hasShopAddress ? Icons.edit : Icons.add),
            label: Text(addressProvider.hasShopAddress ? 'Edit Address' : 'Add Address'),
          );
        },
      ),
    );
  }

  Widget _buildNoAddressView() {
    return const Center(
      child: EmptyState(
        icon: Icons.location_off,
        title: 'No Shop Address Set',
        subtitle: 'Set up your shop address so customers can find your pickup location',
        actionText: 'Add Shop Address',
      ),
    );
  }

  Widget _buildAddressView(ShopAddress shop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.store,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.shopName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              shop.statusText,
                              style: TextStyle(
                                color: shop.statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Address details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Address Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on, 'Street', shop.street),
                  _buildDetailRow(Icons.landscape, 'Landmark', shop.landmark),
                  _buildDetailRow(Icons.location_city, 'City', shop.city),
                  _buildDetailRow(Icons.map, 'State', shop.state),
                  _buildDetailRow(Icons.markunread_mailbox, 'Pincode', shop.pincode),
                  _buildDetailRow(Icons.public, 'Country', shop.country),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.person, 'Contact Person', shop.contactPerson),
                  _buildDetailRow(Icons.phone, 'Primary Phone', shop.phone),
                  _buildDetailRow(Icons.phone_android, 'Alternate Phone', shop.alternatePhone),
                  _buildDetailRow(Icons.email, 'Email', shop.email),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Business hours
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Hours',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.access_time, 'Opening Hours', shop.openingHours),
                  _buildDetailRow(Icons.access_time_filled, 'Closing Hours', shop.closingHours),
                  _buildDetailRow(Icons.calendar_today, 'Working Days', shop.workingDaysText),
                ],
              ),
            ),
          ),

          if (shop.instructions != null && shop.instructions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      shop.instructions!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(AddressProvider provider) {
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
            onPressed: () {
              context.read<AddressProvider>().loadMyShopAddress();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _navigateToAddEdit();
        break;
      case 'preview':
        _previewAddress();
        break;
    }
  }

  void _navigateToAddEdit() {
    final provider = context.read<AddressProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditShopAddressPage(
          shopAddress: provider.myShopAddress,
        ),
      ),
    ).then((_) {
      // Refresh after returning
      provider.loadMyShopAddress();
    });
  }

  void _previewAddress() {
    final shop = context.read<AddressProvider>().myShopAddress;
    if (shop != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Address Preview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This is how customers will see your pickup location:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(shop.pickupLocation),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
