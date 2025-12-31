import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_assesment_1/features/home/provider/category_provider.dart';
import 'package:flutter_assesment_1/features/home/models/product_model.dart';
import 'package:flutter_assesment_1/routes/app_named.dart';

class CategoryListPage extends ConsumerWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to Create Category
              context.goNamed(AppRoutes.createCategoryName);
            },
          ),
        ],
      ),
      body: categoryState.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found. Add one!'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                onTap: () {
                  context.goNamed(
                    AppRoutes.categoryProductsName,
                    extra: category,
                  );
                },
                onEdit: () {
                  context.goNamed(
                    AppRoutes.createCategoryName,
                    extra: category,
                  );
                },
                onDelete: () {
                  _confirmDelete(context, ref, category);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(categoryProvider.notifier)
                    .deleteCategory(category.id);
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Category deleted successfully'),
                  ),
                );
              } catch (e) {
                messenger.clearSnackBars();
                if (e.toString().contains('FOREIGN KEY')) {
                  // Show cascade delete confirmation
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Category contains products'),
                        content: Text(
                          '"${category.name}" has products inside it. Do you want to delete ALL products and this category?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final msg = ScaffoldMessenger.of(context);
                              // Show loading
                              msg.showSnackBar(
                                const SnackBar(content: Text('Deleting...')),
                              );

                              try {
                                final notifier = ref.read(
                                  categoryProvider.notifier,
                                );
                                await notifier.deleteProductsByCategory(
                                  category.id,
                                );
                                await notifier.deleteCategory(category.id);

                                msg.clearSnackBars();
                                msg.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Category and products deleted!',
                                    ),
                                  ),
                                );
                              } catch (nestedError) {
                                msg.clearSnackBars();
                                msg.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $nestedError'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Delete ALL',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete: ${e.toString().replaceAll('Exception:', '').trim()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Hero(
              tag: 'category-img-${category.id}',
              child: Image.network(
                category.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.category,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Action Buttons (Top Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionButton(
                        icon: Icons.edit,
                        color: Colors.white,
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete,
                        color: Colors.redAccent,
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                  // Category Name (Bottom Left)
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
