// Category list page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/category_model.dart';
import 'category_provider.dart';
import 'category_detail_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  static const routeName = '/categories';

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().initialize();
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
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Categories', icon: Icon(Icons.category)),
            Tab(text: 'Featured', icon: Icon(Icons.star)),
            Tab(text: 'Tree View', icon: Icon(Icons.account_tree)),
          ],
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllCategoriesTab(provider),
              _buildFeaturedCategoriesTab(provider),
              _buildTreeViewTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAllCategoriesTab(CategoryProvider provider) {
    if (provider.isLoading && provider.mainCategories.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (provider.hasError && provider.mainCategories.isEmpty) {
      return _buildErrorView(provider);
    }

    if (provider.isEmpty) {
      return const EmptyState(
        icon: Icons.category_outlined,
        title: 'No Categories Found',
        subtitle: 'Categories will appear here when they are available',
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.mainCategories.length,
        itemBuilder: (context, index) {
          final category = provider.mainCategories[index];
          return CategoryCard(
            category: category,
            onTap: () => _navigateToCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCategoriesTab(CategoryProvider provider) {
    if (provider.featuredCategories.isEmpty) {
      return const EmptyState(
        icon: Icons.star_outline,
        title: 'No Featured Categories',
        subtitle: 'Featured categories will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Featured categories header
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 12),
              Text(
                'Featured Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Featured categories grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: provider.featuredCategories.length,
            itemBuilder: (context, index) {
              final category = provider.featuredCategories[index];
              return FeaturedCategoryCard(
                category: category,
                onTap: () => _navigateToCategory(category),
              );
            },
          ),

          const SizedBox(height: 24),

          // Popular categories section
          Text(
            'Popular Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...provider.mainCategories
              .where((c) => c.productCount > 0)
              .take(5)
              .map((category) => PopularCategoryTile(
                    category: category,
                    onTap: () => _navigateToCategory(category),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTreeViewTab(CategoryProvider provider) {
    if (provider.categoryTree.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadCategoryTree(forceRefresh: true),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingIndicator(),
              SizedBox(height: 16),
              Text('Loading category tree...'),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadCategoryTree(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Category Hierarchy',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...provider.categoryTree.map((category) => CategoryTreeTile(
                category: category,
                level: 0,
                onTap: (cat) => _navigateToCategory(cat),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorView(CategoryProvider provider) {
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

  void _showSearch() {
    showSearch(
      context: context,
      delegate: CategorySearchDelegate(),
    );
  }

  void _navigateToCategory(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailPage(categoryId: category.id),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: category.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: category.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          category.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              category.categoryIcon,
                              size: 30,
                              color: category.categoryColor,
                            );
                          },
                        ),
                      )
                    : Icon(
                        category.categoryIcon,
                        size: 30,
                        color: category.categoryColor,
                      ),
              ),

              const SizedBox(height: 12),

              // Category name
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Product count
              Text(
                '${category.formattedProductCount} products',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              // Subcategories indicator
              if (category.hasChildren) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${category.children.length} subcategories',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
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

class FeaturedCategoryCard extends StatelessWidget {
  const FeaturedCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.categoryColor.withOpacity(0.8),
                category.categoryColor.withOpacity(0.6),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          const Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Category icon
                Icon(
                  category.categoryIcon,
                  size: 24,
                  color: Colors.white,
                ),

                const SizedBox(height: 8),

                // Category name
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Product count
                Text(
                  '${category.formattedProductCount} products',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PopularCategoryTile extends StatelessWidget {
  const PopularCategoryTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            category.categoryIcon,
            color: category.categoryColor,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${category.formattedProductCount} products'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class CategoryTreeTile extends StatefulWidget {
  const CategoryTreeTile({
    super.key,
    required this.category,
    required this.level,
    required this.onTap,
  });

  final Category category;
  final int level;
  final Function(Category) onTap;

  @override
  State<CategoryTreeTile> createState() => _CategoryTreeTileState();
}

class _CategoryTreeTileState extends State<CategoryTreeTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: widget.level * 16.0),
          child: ListTile(
            leading: widget.category.hasChildren
                ? IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  )
                : Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.category.categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      widget.category.categoryIcon,
                      size: 16,
                      color: widget.category.categoryColor,
                    ),
                  ),
            title: Text(
              widget.category.name,
              style: TextStyle(
                fontWeight: widget.level == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text('${widget.category.formattedProductCount} products'),
            onTap: () => widget.onTap(widget.category),
          ),
        ),
        if (_isExpanded && widget.category.hasChildren)
          ...widget.category.children.map(
            (child) => CategoryTreeTile(
              category: child,
              level: widget.level + 1,
              onTap: widget.onTap,
            ),
          ),
      ],
    );
  }
}

class CategorySearchDelegate extends SearchDelegate<Category?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Enter at least 2 characters to search'),
      );
    }

    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        // Trigger search
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.searchCategories(query);
        });

        if (provider.isSearching) {
          return const Center(child: LoadingIndicator());
        }

        if (provider.searchResults.isEmpty) {
          return const Center(
            child: Text('No categories found'),
          );
        }

        return ListView.builder(
          itemCount: provider.searchResults.length,
          itemBuilder: (context, index) {
            final category = provider.searchResults[index];
            return ListTile(
              leading: Icon(category.categoryIcon),
              title: Text(category.name),
              subtitle: Text('${category.formattedProductCount} products'),
              onTap: () {
                close(context, category);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailPage(categoryId: category.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        final recentCategories = provider.recentlyViewedCategories
            .take(5)
            .map((id) => provider.mainCategories.firstWhere(
                  (cat) => cat.id == id,
                  orElse: () => provider.mainCategories.first,
                ))
            .toList();

        return ListView(
          children: [
            if (recentCategories.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Recently Viewed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...recentCategories.map((category) => ListTile(
                    leading: Icon(category.categoryIcon),
                    title: Text(category.name),
                    subtitle: Text('${category.formattedProductCount} products'),
                    onTap: () {
                      query = category.name;
                      showResults(context);
                    },
                  )),
            ],
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Popular Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...provider.mainCategories.take(8).map((category) => ListTile(
                  leading: Icon(category.categoryIcon),
                  title: Text(category.name),
                  subtitle: Text('${category.formattedProductCount} products'),
                  onTap: () {
                    query = category.name;
                    showResults(context);
                  },
                )),
          ],
        );
      },
    );
  }
}
