// Address form page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/address_model.dart';
import 'address_provider.dart';
import 'shop_location_detail_page.dart';
import 'nearby_shops_page.dart';

class ShopLocationsPage extends StatefulWidget {
  const ShopLocationsPage({super.key});

  static const routeName = '/shop-locations';

  @override
  State<ShopLocationsPage> createState() => _ShopLocationsPageState();
}

class _ShopLocationsPageState extends State<ShopLocationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AddressProvider>();
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Locations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Shops', icon: Icon(Icons.store)),
            Tab(text: 'Nearby', icon: Icon(Icons.location_on)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersBottomSheet,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllShopsTab(),
          _buildNearbyShopsTab(),
        ],
      ),
    );
  }

  Widget _buildAllShopsTab() {
    return Consumer<AddressProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.shopAddresses.isEmpty) {
          return const Center(child: LoadingIndicator());
        }

        if (provider.hasError && provider.shopAddresses.isEmpty) {
          return _buildErrorView(provider);
        }

        if (provider.isEmpty) {
          return const EmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: 'No Shops Found',
            subtitle: 'There are no pickup locations available at the moment',
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: Column(
            children: [
              // Search and filters summary
              _buildSearchAndFilters(provider),
              
              // Shops list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.shopAddresses.length,
                  itemBuilder: (context, index) {
                    final shop = provider.shopAddresses[index];
                    return ShopAddressCard(
                      shop: shop,
                      showDistance: provider.hasCurrentLocation,
                      distance: provider.hasCurrentLocation 
                          ? provider.getDistanceToShop(shop)
                          : null,
                      onTap: () => _navigateToShopDetail(shop),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNearbyShopsTab() {
    return NearbyShopsPage(isEmbedded: true);
  }

  Widget _buildSearchAndFilters(AddressProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search shops...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        // TODO: Clear search
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              // TODO: Implement search
            },
          ),
          
          const SizedBox(height: 12),
          
          // Active filters and results count
          Row(
            children: [
              Expanded(
                child: Text(
                  '${provider.totalShops} pickup locations found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              // Sort button
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (value) => _handleSort(provider, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha, size: 20),
                        SizedBox(width: 8),
                        Text('Sort by Name'),
                      ],
                    ),
                  ),
                  if (provider.hasCurrentLocation)
                    const PopupMenuItem(
                      value: 'distance',
                      child: Row(
                        children: [
                          Icon(Icons.near_me, size: 20),
                          SizedBox(width: 8),
                          Text('Sort by Distance'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 20),
                        SizedBox(width: 8),
                        Text('Open First'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Active filters chips
          if (_hasActiveFilters(provider)) ...[
            const SizedBox(height: 8),
            _buildActiveFiltersChips(provider),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips(AddressProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (provider.selectedCity != null)
            _buildFilterChip(
              'City: ${provider.selectedCity}',
              () => provider.filterByCity(null),
            ),
          if (provider.selectedState != null)
            _buildFilterChip(
              'State: ${provider.selectedState}',
              () => provider.filterByState(null),
            ),
          if (provider.selectedCategoryId != null)
            _buildFilterChip(
              'Category Filter',
              () => provider.filterByCategory(null),
            ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => provider.clearFilters(),
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close, size: 16),
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
            onPressed: () => provider.refresh(),
            child: const Text('Retry'),
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
      builder: (context) => const ShopFiltersBottomSheet(),
    );
  }

  void _handleSort(AddressProvider provider, String sortType) {
    switch (sortType) {
      case 'name':
        provider.sortShopsByName();
        break;
      case 'distance':
        provider.sortShopsByDistance();
        break;
      case 'status':
        provider.sortShopsByStatus();
        break;
    }
  }

  bool _hasActiveFilters(AddressProvider provider) {
    return provider.selectedCity != null ||
           provider.selectedState != null ||
           provider.selectedCategoryId != null;
  }

  void _navigateToShopDetail(ShopAddress shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopLocationDetailPage(shopId: shop.shopId),
      ),
    );
  }
}

class ShopAddressCard extends StatelessWidget {
  const ShopAddressCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.showDistance = false,
    this.distance,
  });

  final ShopAddress shop;
  final VoidCallback onTap;
  final bool showDistance;
  final String? distance;

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
              // Shop name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shop.shopName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: shop.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: shop.statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: shop.statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          shop.statusText,
                          style: TextStyle(
                            color: shop.statusColor,
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
              
              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shop.shortAddress,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Contact and timing info
              Row(
                children: [
                  // Phone
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          shop.phone,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  
                  // Business hours
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        shop.businessHours,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              
              if (showDistance && distance != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      distance!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  // Call button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makePhoneCall(shop.phone),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Directions button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: shop.hasValidCoordinates 
                          ? () => _openDirections(shop)
                          : null,
                      icon: const Icon(Icons.directions, size: 16),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  void _openDirections(ShopAddress shop) async {
    final Uri launchUri = Uri.parse(shop.googleMapsUrl);
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }
}

class ShopFiltersBottomSheet extends StatefulWidget {
  const ShopFiltersBottomSheet({super.key});

  @override
  State<ShopFiltersBottomSheet> createState() => _ShopFiltersBottomSheetState();
}

class _ShopFiltersBottomSheetState extends State<ShopFiltersBottomSheet> {
  String? _selectedCity;
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AddressProvider>();
    _selectedCity = provider.selectedCity;
    _selectedState = provider.selectedState;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Filter Shops',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
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
                      // City filter
                      Text(
                        'City',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        hint: const Text('Select City'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: provider.availableCities.map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // State filter
                      Text(
                        'State',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedState,
                        hint: const Text('Select State'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: provider.availableStates.map((state) {
                          return DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedState = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Apply button
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
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedState = null;
    });
  }

  void _applyFilters() {
    final provider = context.read<AddressProvider>();
    
    if (_selectedCity != provider.selectedCity) {
      provider.filterByCity(_selectedCity);
    }
    
    if (_selectedState != provider.selectedState) {
      provider.filterByState(_selectedState);
    }
    
    Navigator.pop(context);
  }
}
