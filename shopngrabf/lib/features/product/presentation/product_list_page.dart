// Product list page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_dialog.dart';
import '../../../core/utils/formatters.dart';
import '../domain/product_model.dart';
import 'product_provider.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({
    super.key,
    this.categoryId,
    this.shopId,
    this.title,
    this.showSearch = true,
    this.showFilters = true,
  });

  final int? categoryId;
  final int? shopId;
  final String? title;
  final bool showSearch;
  final bool showFilters;

  static const routeName = '/products';

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      
      if (widget.categoryId != null) {
        productProvider.loadProductsByCategory(widget.categoryId!);
      } else if (widget.shopId != null) {
        productProvider.loadProductsByShop(widget.shopId!);
      } else {
        productProvider.loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      context.read<ProductProvider>().loadMoreProducts();
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        context.read<ProductProvider>().clearSearch();
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      context.read<ProductProvider>().searchProducts(query.trim());
    }
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ProductFiltersBottomSheet(),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ProductSortBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Products'),
        actions: [
          if (widget.showSearch)
            IconButton(
              icon: Icon(_showSearchBar ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
            ),
          if (widget.showFilters)
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _showFiltersBottomSheet,
                    ),
                    if (provider.hasActiveFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortBottomSheet,
          ),
        ],
        bottom: _showSearchBar
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductProvider>().clearSearch();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: _onSearchSubmitted,
                    textInputAction: TextInputAction.search,
                  ),
                ),
              )
            : null,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading && productProvider.products.isEmpty) {
            return const Center(child: LoadingIndicator());
          }

          if (productProvider.hasError && productProvider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    productProvider.errorMessage ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => productProvider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (productProvider.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No Products Found',
              subtitle: 'Try adjusting your search or filters',
            );
          }

          return RefreshIndicator(
            onRefresh: () => productProvider.refresh(),
            child: Column(
              children: [
                // Results summary and active filters
                _buildResultsSummary(productProvider),
                
                // Products grid
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: productProvider.products.length + 
                               (productProvider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= productProvider.products.length) {
                        return const Center(child: LoadingIndicator());
                      }
                      
                      final product = productProvider.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () => _navigateToProductDetail(product),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsSummary(ProductProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              provider.resultsText,
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

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(productId: product.id),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[200],
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported, size: 48);
                          },
                        ),
                      )
                    : const Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Shop Name
                    Text(
                      product.shopName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Price and Rating Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            Formatters.currency(product.price),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        if (product.averageRating > 0) ...[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            product.displayRating,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Stock Status
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: product.stockStatusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.stockStatus,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: product.stockStatusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductFiltersBottomSheet extends StatefulWidget {
  const ProductFiltersBottomSheet({super.key});

  @override
  State<ProductFiltersBottomSheet> createState() => _ProductFiltersBottomSheetState();
}

class _ProductFiltersBottomSheetState extends State<ProductFiltersBottomSheet> {
  late ProductFilters _filters;
  RangeValues _priceRange = const RangeValues(0, 10000);
  bool _inStockOnly = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    _filters = provider.filters;
    _priceRange = RangeValues(
      _filters.minPrice ?? 0,
      _filters.maxPrice ?? 10000,
    );
    _inStockOnly = _filters.inStockOnly ?? false;
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
                'Filters',
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
                  // Price Range
                  Text(
                    'Price Range',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    labels: RangeLabels(
                      Formatters.currency(_priceRange.start),
                      Formatters.currency(_priceRange.end),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  Row(
                    children: [
                      Text(Formatters.currency(_priceRange.start)),
                      const Spacer(),
                      Text(Formatters.currency(_priceRange.end)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // In Stock Only
                  CheckboxListTile(
                    title: const Text('In Stock Only'),
                    subtitle: const Text('Show only available products'),
                    value: _inStockOnly,
                    onChanged: (value) {
                      setState(() {
                        _inStockOnly = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
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

  void _clearAll() {
    setState(() {
      _priceRange = const RangeValues(0, 10000);
      _inStockOnly = false;
    });
  }

  void _applyFilters() {
    final newFilters = _filters.copyWith(
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 10000 ? _priceRange.end : null,
      inStockOnly: _inStockOnly ? true : null,
    );
    
    context.read<ProductProvider>().applyFilters(newFilters);
    Navigator.pop(context);
  }
}

class ProductSortBottomSheet extends StatelessWidget {
  const ProductSortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      {'key': 'newest', 'title': 'Newest First', 'icon': Icons.schedule},
      {'key': 'price_low', 'title': 'Price: Low to High', 'icon': Icons.arrow_upward},
      {'key': 'price_high', 'title': 'Price: High to Low', 'icon': Icons.arrow_downward},
      {'key': 'rating', 'title': 'Highest Rated', 'icon': Icons.star},
      {'key': 'name', 'title': 'Name: A to Z', 'icon': Icons.sort_by_alpha},
    ];

    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort By',
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
                    provider.sortProducts(option['key'] as String);
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
