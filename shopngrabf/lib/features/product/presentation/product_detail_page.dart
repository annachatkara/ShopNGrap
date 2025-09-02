// Product detail page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../domain/product_model.dart';
import 'product_provider.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  final int productId;

  static const routeName = '/product';

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().getProduct(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Scaffold(
              body: Center(child: LoadingIndicator()),
            );
          }

          final product = productProvider.selectedProduct;
          if (product == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Product')),
              body: const Center(
                child: Text('Product not found'),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // TODO: Add to wishlist
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to wishlist')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // TODO: Share product
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share product')),
                      );
                    },
                  ),
                ],
              ),
              
              // Product Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name and Price
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Text(
                            Formatters.currency(product.price),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (product.averageRating > 0) ...[
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${product.displayRating} (${product.reviewCount} ${product.reviewText})',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Shop Info
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.store),
                          ),
                          title: Text(product.shopName),
                          subtitle: const Text('Shop Details'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Navigate to shop page
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Navigate to ${product.shopName}')),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Stock Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: product.stockStatusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: product.stockStatusColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: product.stockStatusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${product.stockStatus} (${product.stock} available)',
                              style: TextStyle(
                                color: product.stockStatusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Category
                      Row(
                        children: [
                          Text(
                            'Category: ',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Chip(
                            label: Text(product.categoryName),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Reviews Section
                      Row(
                        children: [
                          Text(
                            'Reviews',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to reviews page
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('View all reviews')),
                              );
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      
                      if (product.reviewCount > 0) ...[
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      product.displayRating,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          Icons.star,
                                          size: 16,
                                          color: index < product.averageRating
                                              ? Colors.amber
                                              : Colors.grey[300],
                                        );
                                      }),
                                    ),
                                    Text(
                                      '${product.reviewCount} ${product.reviewText}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildRatingRow(context, 5, 0.6),
                                      _buildRatingRow(context, 4, 0.3),
                                      _buildRatingRow(context, 3, 0.1),
                                      _buildRatingRow(context, 2, 0.0),
                                      _buildRatingRow(context, 1, 0.0),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('No reviews yet'),
                                  Text('Be the first to review this product'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      
      // Bottom Action Buttons
      bottomNavigationBar: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          final product = productProvider.selectedProduct;
          if (product == null) return const SizedBox.shrink();
          
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
                  // Add to Cart Button
                  Expanded(
                    child: CustomButton(
                      onPressed: product.isInStock ? () {
                        // TODO: Add to cart
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      } : null,
                      child: Text(
                        product.isInStock ? 'Add to Cart' : 'Out of Stock',
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Buy Now Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: product.isInStock ? () {
                        // TODO: Buy now
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Buy now')),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                      child: const Text('Buy Now'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context, int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars'),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
