import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/category_model.dart';
import 'category_provider.dart';
import 'admin_category_detail_page.dart';
import '../../../shared/widgets/custom_button.dart';

class AdminCategoryListPage extends StatefulWidget {
  const AdminCategoryListPage({super.key});

  static const routeName = '/admin/categories';

  @override
  State<AdminCategoryListPage> createState() => _AdminCategoryListPageState();
}

class _AdminCategoryListPageState extends State<AdminCategoryListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadAdminCategories();
      context.read<CategoryProvider>().loadCategoryStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Categories'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToCreate(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadAdminCategories(forceRefresh: true),
              ),
            ],
          ),
          body: provider.isLoading && provider.adminCategories.isEmpty
              ? const Center(child: LoadingIndicator())
              : provider.hasError && provider.adminCategories.isEmpty
                  ? _buildError(provider)
                  : provider.adminCategories.isEmpty
                      ? const EmptyState(
                          icon: Icons.category_outlined,
                          title: 'No Categories',
                          subtitle: 'Add a new category to get started',
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.loadAdminCategories(forceRefresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.adminCategories.length,
                            itemBuilder: (context, index) {
                              final category = provider.adminCategories[index];
                              return Dismissible(
                                key: ValueKey(category.id),
                                background: Container(color: Colors.red),
                                onDismissed: (_) => provider.deleteCategory(category.id),
                                child: ListTile(
                                  leading: Icon(category.categoryIcon, color: category.categoryColor),
                                  title: Text(category.name),
                                  subtitle: Text('${category.formattedProductCount} products'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _navigateToEdit(category),
                                  ),
                                  onTap: () => _navigateToDetail(category),
                                ),
                              );
                            },
                          ),
                        ),
        );
      },
    );
  }

  Widget _buildError(CategoryProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadAdminCategories(forceRefresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCategoryDetailPage(),
      ),
    );
  }

  void _navigateToEdit(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCategoryDetailPage(category: category),
      ),
    );
  }

  void _navigateToDetail(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCategoryDetailPage(category: category),
      ),
    );
  }
}
