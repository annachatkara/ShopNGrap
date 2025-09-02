import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../domain/category_model.dart';
import 'category_provider.dart';

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({
    super.key,
    required this.categoryId,
  });

  final int categoryId;

  static const routeName = '/category-detail';

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().getCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingIndicator());
          }
          final category = provider.selectedCategory;
          if (category == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Category')),
              body: const Center(child: Text('Category not found')),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                title: Text(category.name),
                flexibleSpace: FlexibleSpaceBar(
                  background: category.imageUrl != null
                      ? Image.network(category.imageUrl!, fit: BoxFit.cover)
                      : Container(color: category.categoryColor),
                ),
                bottom: SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: false,
                  toolbarHeight: 40,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(category.categoryPath),
                    titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${category.totalProductCount} products',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      if (category.hasChildren)
                        Text(
                          'Subcategories',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      if (category.hasChildren)
                        ...category.children.map((sub) {
                          return ListTile(
                            leading: Icon(sub.categoryIcon, color: sub.categoryColor),
                            title: Text(sub.name),
                            subtitle: Text('${sub.formattedProductCount} products'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryDetailPage(categoryId: sub.id),
                              ),
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 16),
                      Text(
                        'Products under this category will be listed here.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
