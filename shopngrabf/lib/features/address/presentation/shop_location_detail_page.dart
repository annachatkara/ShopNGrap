// shop location detail page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../domain/address_model.dart';
import 'address_provider.dart';

class ShopLocationDetailPage extends StatefulWidget {
  const ShopLocationDetailPage({
    super.key,
    required this.shopId,
  });

  final int shopId;

  static const routeName = '/shop-location-detail';

  @override
  State<ShopLocationDetailPage> createState() => _ShopLocationDetailPageState();
}

class _ShopLocationDetailPageState extends State<ShopLocationDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().getShopAddress(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AddressProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
              body: Center(child: LoadingIndicator()),
            );
          }

          final shop = provider.selectedShopAddress;
          if (shop == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Shop Location')),
              body: const Center(
                child: Text('Shop location not found'),
              ),
            );
          }

          return _buildShopDetail(shop, provider);
        },
      ),
    );
  }

  Widget _buildShopDetail(ShopAddress shop, AddressProvider provider) {
    return CustomScrollView(
      slivers: [
        // App Bar with shop image placeholder
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              shop.shopName,
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
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Icon(
                Icons.store,
                size: 80,
                color: Colors.white54,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareShopLocation(shop),
            ),
          ],
        ),

        // Shop details content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                _buildStatusCard(shop),
                
                const SizedBox(height: 16),
                
                // Contact information
                _buildContactCard(shop),
                
                const SizedBox(height: 16),
                
                // Address information
                _buildAddressCard(shop, provider),
                
                const SizedBox(height: 16),
                
                // Business hours
                _buildBusinessHoursCard(shop),
                
                const SizedBox(height: 16),
                
                // Special instructions
                if (shop.instructions != null && shop.instructions!.isNotEmpty)
                  _buildInstructionsCard(shop),
                
                const SizedBox(height: 100), // Space for bottom buttons
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(ShopAddress shop) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: shop.statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.statusText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: shop.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Working Days: ${shop.workingDaysText}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(ShopAddress shop) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Contact person
            _buildInfoRow(
              icon: Icons.person,
              label: 'Contact Person',
              value: shop.contactPerson,
            ),
            
            const SizedBox(height: 12),
            
            // Phone numbers
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Primary Phone',
              value: shop.phone,
              onTap: () => _makePhoneCall(shop.phone),
              isClickable: true,
            ),
            
            if (shop.alternatePhone.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.phone_android,
                label: 'Alternate Phone',
                value: shop.alternatePhone,
                onTap: () => _makePhoneCall(shop.alternatePhone),
                isClickable: true,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Email
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: shop.email,
              onTap: () => _sendEmail(shop.email),
              isClickable: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(ShopAddress shop, AddressProvider provider) {
    final distance = provider.hasCurrentLocation 
        ? provider.getDistanceToShop(shop)
        : null;

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
                  'Pickup Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Full address
            Text(
              shop.fullAddress,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            
            if (distance != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      distance,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
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
                    onPressed: () => _copyAddress(shop.fullAddress),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Address'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: shop.hasValidCoordinates 
                        ? () => _openDirections(shop)
                        : null,
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Get Directions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursCard(ShopAddress shop) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Business Hours',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Operating hours
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${shop.openingHours} - ${shop.closingHours}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Working days
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shop.workingDaysText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
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

  Widget _buildInstructionsCard(ShopAddress shop) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Pickup Instructions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              shop.instructions!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool isClickable = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isClickable ? Theme.of(context).primaryColor : null,
                      fontWeight: isClickable ? FontWeight.w500 : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isClickable)
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

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
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

  void _copyAddress(String address) {
    // TODO: Copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
  }

  void _shareShopLocation(ShopAddress shop) {
    final shareText = '''
${shop.shopName}
${shop.fullAddress}

Business Hours: ${shop.businessHours}
Working Days: ${shop.workingDaysText}

Contact: ${shop.phone}
Email: ${shop.email}

Get directions: ${shop.googleMapsUrl}
    ''';
    
    Share.share(shareText, subject: '${shop.shopName} - Pickup Location');
  }
}
