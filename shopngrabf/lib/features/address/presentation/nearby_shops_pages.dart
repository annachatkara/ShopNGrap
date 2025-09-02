import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/custom_button.dart';
import '../domain/address_model.dart';
import 'address_provider.dart';
import 'shop_location_detail_page.dart';
import 'shop_locations_page.dart';

class NearbyShopsPage extends StatefulWidget {
  const NearbyShopsPage({
    super.key,
    this.isEmbedded = false,
  });

  final bool isEmbedded;

  static const routeName = '/nearby-shops';

  @override
  State<NearbyShopsPage> createState() => _NearbyShopsPageState();
}

class _NearbyShopsPageState extends State<NearbyShopsPage> {
  double _selectedRadius = 10.0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isEmbedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNearbyShops();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyShops() async {
    final provider = context.read<AddressProvider>();
    await provider.loadNearbyShops(
      radiusKm: _selectedRadius,
      searchQuery: _searchController.text.trim().isNotEmpty 
          ? _searchController.text.trim() 
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return _buildContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Shops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _refreshLocation,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Consumer<AddressProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Location and search controls
            _buildControls(provider),
            
            // Content
            Expanded(
              child: _buildNearbyShopsList(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(AddressProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Location status
          if (!provider.hasCurrentLocation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Location access needed to find nearby shops',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: _requestLocation,
                    child: const Text('Enable'),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Finding shops near your location',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  TextButton(
                    onPressed: _refreshLocation,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          
          if (provider.hasCurrentLocation) ...[
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search nearby shops...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadNearbyShops();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _loadNearbyShops(),
            ),
            
            const SizedBox(height: 16),
            
            // Radius selector
            Row(
              children: [
                const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Radius: ${_selectedRadius.toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: _selectedRadius,
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        onChanged: (value) {
                          setState(() {
                            _selectedRadius = value;
                          });
                        },
                        onChangeEnd: (_) => _loadNearbyShops(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNearbyShopsList(AddressProvider provider) {
    if (provider.isLoading && provider.nearbyShops.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (provider.hasError && provider.nearbyShops.isEmpty) {
      return _buildErrorView(provider);
    }

    if (!provider.hasCurrentLocation) {
      return const EmptyState(
        icon: Icons.location_off,
        title: 'Location Required',
        subtitle: 'Enable location access to find nearby pickup locations',
        actionText: 'Enable Location',
      );
    }

    if (provider.nearbyShops.isEmpty) {
      return EmptyState(
        icon: Icons.store_mall_directory_outlined,
        title: 'No Nearby Shops',
        subtitle: 'No pickup locations found within ${_selectedRadius.toStringAsFixed(1)}km radius',
        actionText: 'Increase Search Radius',
        onActionPressed: () {
          setState(() {
            _selectedRadius = (_selectedRadius * 1.5).clamp(1.0, 50.0);
          });
          _loadNearbyShops();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNearbyShops,
      child: Column(
        children: [
          // Results summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${provider.nearbyShops.length} shops found within ${_selectedRadius.toStringAsFixed(1)}km',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (provider.nearbyShops.length >= 10)
                  Text(
                    'Showing closest 10',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          
          // Shops list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: provider.nearbyShops.length,
              itemBuilder: (context, index) {
                final shop = provider.nearbyShops[index];
                return ShopAddressCard(
                  shop: shop,
                  showDistance: true,
                  distance: provider.getDistanceToShop(shop),
                  onTap: () => _navigateToShopDetail(shop),
                );
              },
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
            onPressed: _loadNearbyShops,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLocation() async {
    final provider = context.read<AddressProvider>();
    final success = await provider.getCurrentLocation();
    
    if (success) {
      await _loadNearbyShops();
    } else {
      if (mounted) {
        _showLocationPermissionDialog();
      }
    }
  }

  Future<void> _refreshLocation() async {
    final provider = context.read<AddressProvider>();
    await provider.getCurrentLocation();
    await _loadNearbyShops();
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Access Required'),
        content: const Text(
          'To find nearby pickup locations, please enable location access in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Open app settings
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
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
